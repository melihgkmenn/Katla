import SwiftUI

struct StudioView: View {
  @Bindable var model: StudioModel
  @State private var showInspector = false
  @State private var showTemplates = false
  @State private var showExport = false
  @State private var showRename = false
  @State private var projectName = ""

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ProjectHeading(model: model) {
          projectName = model.document.name
          showRename = true
        }
        StudioWorkspace(model: model)
      }
      .background(StudioTheme.background)
      .navigationTitle("Katla")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Yeni proje", systemImage: "plus") { showTemplates = true }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Parametreler", systemImage: "slider.horizontal.3") { showInspector = true }
          Button("Dışa aktar", systemImage: "square.and.arrow.up") { showExport = true }
        }
      }
      .sheet(isPresented: $showInspector) { InspectorView(model: model) }
      .sheet(isPresented: $showTemplates) { TemplateSheet(model: model) }
      .sheet(isPresented: $showExport) { ExportSheet(document: model.document) }
      .alert("Projeyi adlandır", isPresented: $showRename) {
        TextField("Proje adı", text: $projectName)
        Button("Kaydet") {
          let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty { model.document.name = trimmed }
        }
        Button("Vazgeç", role: .cancel) {}
      }
    }
  }
}

private struct ProjectHeading: View {
  var model: StudioModel
  var rename: () -> Void
  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 5) {
        Text("KÂĞIT KATLAMA STÜDYOSU")
          .font(.system(size: 9, weight: .medium, design: .monospaced))
          .tracking(2.4).foregroundStyle(StudioTheme.muted)
        Button(action: rename) {
          HStack(spacing: 8) {
            Text(model.document.name).font(.system(.title3, design: .rounded, weight: .semibold))
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold)).foregroundStyle(StudioTheme.muted)
          }.foregroundStyle(.white)
        }
      }
      Spacer(minLength: 10)
      StudioTag(title: "YEREL KAYIT", color: StudioTheme.mint)
    }
    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 17)
  }
}

private struct StudioWorkspace: View {
  var model: StudioModel
  var body: some View {
    GeometryReader { geometry in
      if #available(iOS 27.1, *) {
        ArrangementView {
          RenderPanel(model: model)
            .splitArrangementLayoutRatio(0.5)
        } secondary: {
          BlueprintPanel(model: model)
        }
        .arrangementViewStyle(.split.axes(geometry.size.height > 470 ? .vertical : .horizontal))
        .onHingeChange { _, context in
          model.receiveHinge(context.hinge?.angle.degrees, closed: context.hinge?.status == .closed)
        }
      } else {
        if geometry.size.height > 470 {
          VStack(spacing: 0) { RenderPanel(model: model); BlueprintPanel(model: model) }
        } else {
          HStack(spacing: 0) { RenderPanel(model: model); BlueprintPanel(model: model) }
        }
      }
    }
  }
}
