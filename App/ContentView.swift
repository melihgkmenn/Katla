import SwiftUI

struct ContentView: View {
  @State private var model = StudioModel()
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Stüdyo", systemImage: "square.stack.3d.up", value: 0) {
        StudioView(model: model)
      }
      Tab("Projeler", systemImage: "square.grid.2x2", value: 1) {
        ProjectLibraryView(model: model) { selectedTab = 0 }
      }
      Tab("Rehber", systemImage: "book.closed", value: 2) {
        GuideView()
      }
    }
    .tint(StudioTheme.copper)
    .preferredColorScheme(.dark)
    .onOpenURL { _ in selectedTab = 0 }
    .task { model.save(); await model.observeActivityAuthorization() }
    .alert("İşlem tamamlanamadı", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
      Button("Tamam", role: .cancel) { model.errorMessage = nil }
    } message: { Text(model.errorMessage ?? "") }
  }
}
