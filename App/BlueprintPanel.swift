import SwiftUI

struct BlueprintPanel: View {
  @Bindable var model: StudioModel
  @State private var dragStart: CGPoint?
  @State private var dragEnd: CGPoint?

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        HStack(spacing: 7) {
          Image(systemName: "ruler").font(.system(size: 11))
          Text("BLUEPRINT").tracking(1.7)
        }
        Spacer()
        Text("\(Int(model.document.width)) × \(Int(model.document.height)) mm")
          .foregroundStyle(StudioTheme.muted)
        Toggle("Izgara", systemImage: "square.grid.2x2", isOn: $model.showGrid)
          .toggleStyle(.button).labelStyle(.iconOnly).buttonStyle(.borderless)
          .frame(width: 32, height: 32).tint(StudioTheme.copper)
      }
      .font(.system(size: 9, weight: .medium, design: .monospaced))
      .padding(.horizontal, 16).padding(.top, 5)
      GeometryReader { geometry in
        let rect = paperRect(in: geometry.size)
        ZStack {
          if model.showGrid { CanvasGrid(spacing: 18) }
          BlueprintDrawing(document: model.document, selectedCrease: model.selectedCrease, rect: rect, dragStart: dragStart, dragEnd: dragEnd)
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
          .onChanged { value in
            guard model.tool != .select else { return }
            if dragStart == nil {
              guard rect.contains(value.startLocation) else { return }
              dragStart = normalized(value.startLocation, rect: rect)
            }
            dragEnd = normalized(value.location, rect: rect)
          }
          .onEnded { value in
            if model.tool == .select {
              selectNearest(normalized(value.location, rect: rect))
            } else if let start = dragStart, let end = dragEnd {
              model.addCrease(from: start, to: end)
            }
            dragStart = nil; dragEnd = nil
          })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("İki boyutlu blueprint. \(model.document.creases.count) kat izi")
        .accessibilityHint("Parmağınızla veya Apple Pencil ile kat çizgisi çizin. Parametrelerden de kat ekleyebilirsiniz.")
        .accessibilityAction(named: "Dikey kat ekle") {
          model.addCrease(from: CGPoint(x: 0.5, y: 0), to: CGPoint(x: 0.5, y: 1))
        }
      }
      .frame(minHeight: 100)
      BlueprintTools(model: model)
      HStack(spacing: 6) {
        Circle().fill(StudioTheme.copper).frame(width: 4, height: 4)
        Text("\(model.document.creases.count) kat izi")
        Text("·")
        Text(model.tool == .select ? "İz seçmek için dokun" : "Katlamak için çiz")
        Spacer()
        Text("1:1").fontDesign(.monospaced)
      }
      .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
      .padding(.horizontal, 18).padding(.vertical, 10)
    }
    .background(StudioTheme.panel.opacity(0.55))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func paperRect(in size: CGSize) -> CGRect {
    let ratio = model.document.width / model.document.height
    let width = max(1, min(size.width - 70, max(1, size.height - 42) * ratio))
    let height = width / ratio
    return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)
  }

  private func normalized(_ point: CGPoint, rect: CGRect) -> CGPoint {
    CGPoint(x: min(1, max(0, ((point.x - rect.minX) / rect.width * 24).rounded() / 24)),
            y: min(1, max(0, ((point.y - rect.minY) / rect.height * 24).rounded() / 24)))
  }

  private func selectNearest(_ point: CGPoint) {
    model.selectedCrease = model.document.creases.min { first, second in
      distance(point, first) < distance(point, second)
    }.flatMap { distance(point, $0) < 0.1 ? $0.id : nil }
  }

  private func distance(_ p: CGPoint, _ crease: Crease) -> Double {
    let a = crease.start.point; let b = crease.end.point
    let dx = b.x - a.x; let dy = b.y - a.y
    let t = min(1, max(0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / max(0.00001, dx * dx + dy * dy)))
    return hypot(p.x - a.x - t * dx, p.y - a.y - t * dy)
  }
}

private struct BlueprintDrawing: View {
  var document: FoldDocument
  var selectedCrease: UUID?
  var rect: CGRect
  var dragStart: CGPoint?
  var dragEnd: CGPoint?

  var body: some View {
    Canvas { context, _ in
      context.fill(Path(rect), with: .color(StudioTheme.copper.opacity(0.035)))
      context.stroke(Path(rect), with: .color(StudioTheme.copper.opacity(0.65)), lineWidth: 1)
      for crease in document.creases {
        var path = Path()
        path.move(to: mapped(crease.start.point)); path.addLine(to: mapped(crease.end.point))
        context.stroke(path, with: .color(crease.id == selectedCrease ? .white : StudioTheme.copper.opacity(crease.mountain ? 0.85 : 0.5)), style: StrokeStyle(lineWidth: crease.id == selectedCrease ? 2 : 1, dash: crease.mountain ? [] : [5, 4]))
      }
      for point in [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1)] {
        let p = mapped(point)
        let square = CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)
        context.fill(Path(square), with: .color(StudioTheme.background))
        context.stroke(Path(square), with: .color(StudioTheme.copper), lineWidth: 1)
      }
      var dimension = Path()
      let y = rect.minY - 14
      dimension.move(to: CGPoint(x: rect.minX, y: y)); dimension.addLine(to: CGPoint(x: rect.maxX, y: y))
      for x in [rect.minX, rect.maxX] {
        dimension.move(to: CGPoint(x: x, y: y - 3)); dimension.addLine(to: CGPoint(x: x, y: y + 3))
      }
      context.stroke(dimension, with: .color(StudioTheme.muted.opacity(0.4)), lineWidth: 0.5)
      let label = Text("\(Int(document.width)) mm").font(.system(size: 8, design: .monospaced)).foregroundStyle(StudioTheme.muted)
      context.draw(label, at: CGPoint(x: rect.midX, y: y - 1))
      context.draw(Text("Y").font(.system(size: 8, design: .monospaced)).foregroundStyle(StudioTheme.muted), at: CGPoint(x: 14, y: 14))
      context.draw(Text("X").font(.system(size: 8, design: .monospaced)).foregroundStyle(StudioTheme.muted), at: CGPoint(x: 29, y: 29))
      if let start = dragStart, let end = dragEnd {
        var path = Path(); path.move(to: mapped(start)); path.addLine(to: mapped(end))
        context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
      }
    }.allowsHitTesting(false)
  }
  private func mapped(_ point: CGPoint) -> CGPoint {
    CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
  }
}

private struct BlueprintTools: View {
  @Bindable var model: StudioModel
  var body: some View {
    HStack(spacing: 4) {
      ForEach(DrawingTool.allCases) { tool in
        Button {
          model.tool = tool
        } label: {
          HStack(spacing: 6) {
            Image(systemName: tool.symbol)
            if model.tool == tool { Text(tool.title).font(.system(size: 11, weight: .semibold)) }
          }
          .frame(minWidth: 36, minHeight: 38)
          .padding(.horizontal, model.tool == tool ? 10 : 0)
          .foregroundStyle(model.tool == tool ? StudioTheme.background : StudioTheme.muted)
          .background(model.tool == tool ? StudioTheme.copper : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel(tool.title).accessibilityAddTraits(model.tool == tool ? [.isSelected] : [])
      }
      Rectangle().fill(StudioTheme.line).frame(width: 1, height: 22).padding(.horizontal, 4)
      Button("Geri al", systemImage: "arrow.uturn.backward") { model.undo() }
        .disabled(!model.canUndo).labelStyle(.iconOnly).frame(width: 38, height: 38)
      if model.selectedCrease != nil {
        Button("Kat izini sil", systemImage: "trash") { model.removeSelectedCrease() }
          .labelStyle(.iconOnly).frame(width: 38, height: 38)
      }
    }
    .font(.system(size: 15)).buttonStyle(.plain)
    .padding(5).background(StudioTheme.raised, in: RoundedRectangle(cornerRadius: 15))
    .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.line))
  }
}
