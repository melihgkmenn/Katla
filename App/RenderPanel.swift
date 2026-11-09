import SwiftUI

struct RenderPanel: View {
  @Bindable var model: StudioModel

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        StudioTheme.panel
        CanvasGrid(spacing: 32)
        RadialGradient(colors: [StudioTheme.copper.opacity(0.06), .clear], center: .center, startRadius: 0, endRadius: 220)
        PaperSceneView(document: model.document, wireframe: model.wireframe, cameraRevision: model.cameraRevision)
          .accessibilityLabel("\(model.document.name), üç boyutlu önizleme")
          .accessibilityValue("Menteşe \(Int(model.angle)) derece, \(model.document.creases.count) kat izi")
        VStack {
          HStack(spacing: 7) {
            Circle().fill(StudioTheme.mint).frame(width: 5, height: 5)
            Text("3D ÖNİZLEME").tracking(1.5)
            Spacer()
            Text("PERSPEKTİF").foregroundStyle(StudioTheme.muted)
          }
          .font(.system(size: 9, weight: .medium, design: .monospaced))
          .padding(16)
          Spacer()
          HStack(alignment: .bottom) {
            HStack(spacing: 6) {
              Circle().fill(model.document.material.color).frame(width: 7, height: 7)
              Text(model.document.material.title)
            }
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.black.opacity(0.3), in: Capsule())
            Spacer()
            ViewControls(model: model)
          }.padding(12)
        }
      }
      .clipped()
      HingeControl(model: model)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .top) { Rectangle().fill(StudioTheme.line).frame(height: 1) }
  }
}

private struct ViewControls: View {
  @Bindable var model: StudioModel
  var body: some View {
    HStack(spacing: 2) {
      Toggle("Tel kafes", systemImage: "cube.transparent", isOn: $model.wireframe)
        .toggleStyle(.button)
        .tint(StudioTheme.copper)
      Button("Kamerayı sıfırla", systemImage: "viewfinder") { model.cameraRevision += 1 }
    }
    .labelStyle(.iconOnly).buttonStyle(.borderless)
    .font(.system(size: 16)).foregroundStyle(StudioTheme.muted)
    .padding(6).background(.ultraThinMaterial, in: Capsule())
  }
}

private struct HingeControl: View {
  @Bindable var model: StudioModel
  var body: some View {
    VStack(spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        HStack(spacing: 7) {
          Image(systemName: "rectangle.3.group").font(.system(size: 13))
          Text("Katlama açısı").font(.system(size: 12, weight: .medium))
        }.foregroundStyle(StudioTheme.muted)
        Spacer()
        Text("\(Int(model.angle.rounded()))°")
          .font(.system(size: 28, weight: .light, design: .monospaced))
          .foregroundStyle(StudioTheme.copper).contentTransition(.numericText())
        if model.hingeAvailable {
          Toggle("Menteşe eşleşmesi", isOn: $model.syncHinge)
            .labelsHidden().scaleEffect(0.7).frame(width: 40)
        } else {
          StudioTag(title: "MANUEL")
        }
      }
      HStack(spacing: 12) {
        Text("90°")
        Slider(value: $model.angle, in: 90...180) {
          Text("Katlama açısı")
        } onEditingChanged: { editing in if editing { model.checkpoint(); model.syncHinge = false } }
          .tint(StudioTheme.copper)
          .accessibilityValue("\(Int(model.angle)) derece")
        Text("180°")
      }
      .font(.system(size: 9, design: .monospaced)).foregroundStyle(StudioTheme.muted)
    }
    .padding(.horizontal, 18).padding(.vertical, 10)
    .background(StudioTheme.background)
    .overlay(alignment: .top) { Rectangle().fill(StudioTheme.line).frame(height: 1) }
    .overlay(alignment: .bottom) { Rectangle().fill(StudioTheme.line).frame(height: 1) }
  }
}
