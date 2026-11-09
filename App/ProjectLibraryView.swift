import SwiftUI

struct ProjectLibraryView: View {
  var model: StudioModel
  var openStudio: () -> Void
  @State private var showTemplates = false
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          VStack(alignment: .leading, spacing: 10) {
            Text("Bir çizgi.\nSonsuz olasılık.")
              .font(.system(.largeTitle, design: .rounded, weight: .light))
            Text("Fikirlerini katla, biçime dönüştür.").foregroundStyle(StudioTheme.muted)
          }.padding(.top, 15)
          Button { showTemplates = true } label: {
            Label("Yeni çalışma oluştur", systemImage: "plus")
              .font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.background)
              .frame(maxWidth: .infinity).padding(18)
              .background(StudioTheme.copper, in: RoundedRectangle(cornerRadius: 16))
          }.buttonStyle(.plain)
          Text("ÇALIŞMALARIN").font(.caption.monospaced()).tracking(2).foregroundStyle(StudioTheme.muted)
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
            ForEach(model.projects) { project in
              Button { model.open(project); openStudio() } label: { ProjectCard(project: project) }.buttonStyle(.plain)
            }
          }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(StudioTheme.background).navigationTitle("Projeler")
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Yeni çalışma", systemImage: "plus") { showTemplates = true } } }
      .sheet(isPresented: $showTemplates, onDismiss: openStudio) { TemplateSheet(model: model) }
    }
  }
}

private struct ProjectCard: View {
  var project: FoldDocument
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack {
        StudioTheme.raised
        CanvasGrid(spacing: 20)
        FoldIllustration(color: project.material.color, folds: max(1, project.creases.count)).padding(20)
      }.frame(height: 135).clipped()
      VStack(alignment: .leading, spacing: 6) {
        Text(project.name).font(.subheadline.weight(.medium)).lineLimit(1)
        Text("\(project.creases.count) kat izi · \(Int(project.angle))°").font(.caption.monospaced()).foregroundStyle(StudioTheme.muted)
      }.padding(14)
    }
    .background(StudioTheme.panel, in: RoundedRectangle(cornerRadius: 18))
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(StudioTheme.line))
  }
}

struct FoldIllustration: View {
  var color: Color = StudioTheme.copper
  var folds = 5
  var body: some View {
    Canvas { context, size in
      let count = min(8, folds + 1)
      let width = size.width * 0.85 / CGFloat(count)
      let start = CGPoint(x: size.width * 0.08, y: size.height * 0.5)
      for i in 0..<count {
        let x = start.x + CGFloat(i) * width
        let lift: CGFloat = i % 2 == 0 ? 0 : -size.height * 0.28
        let nextLift: CGFloat = i % 2 == 0 ? -size.height * 0.28 : 0
        let points = [CGPoint(x: x, y: start.y + lift), CGPoint(x: x + width, y: start.y + nextLift), CGPoint(x: x + width + 12, y: start.y + nextLift + size.height * 0.48), CGPoint(x: x + 12, y: start.y + lift + size.height * 0.48)]
        var path = Path(); path.addLines(points); path.closeSubpath()
        context.fill(path, with: .linearGradient(Gradient(colors: [color.opacity(i % 2 == 0 ? 0.95 : 0.5), color.opacity(i % 2 == 0 ? 0.6 : 0.28)]), startPoint: points[0], endPoint: points[2]))
        context.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 0.6)
      }
    }.accessibilityHidden(true)
  }
}

struct TemplateSheet: View {
  var model: StudioModel
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      List(FoldPreset.allCases) { preset in
        Button { model.create(preset); dismiss() } label: {
          HStack(spacing: 18) {
            FoldIllustration(folds: preset == .valley ? 1 : 5).frame(width: 68, height: 64)
            VStack(alignment: .leading, spacing: 5) {
              Text(preset.title).font(.headline).foregroundStyle(.primary)
              Text(preset.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
          }.padding(.vertical, 8)
        }
      }
      .navigationTitle("Nereden başlayalım?").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Kapat", systemImage: "xmark") { dismiss() } } }
    }.tint(StudioTheme.copper).presentationDetents([.medium, .large])
  }
}
