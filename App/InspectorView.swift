import SwiftUI

struct InspectorView: View {
  @Bindable var model: StudioModel
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      Form {
        Section("Kâğıt") {
          TextField("Proje adı", text: $model.document.name)
          LabeledContent("Genişlik · mm") {
            TextField("Genişlik", value: $model.document.width, format: .number)
              .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
              .onChange(of: model.document.width) { _, value in
                if value < 20 || value > 1000 { model.document.width = min(1000, max(20, value)) }
              }
          }
          LabeledContent("Yükseklik · mm") {
            TextField("Yükseklik", value: $model.document.height, format: .number)
              .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
              .onChange(of: model.document.height) { _, value in
                if value < 20 || value > 1000 { model.document.height = min(1000, max(20, value)) }
              }
          }
          Picker("Malzeme", selection: $model.document.material) {
            ForEach(PaperMaterial.allCases) { material in Text(material.title).tag(material) }
          }
        }
        Section {
          Toggle("Menteşe ile eşleştir", isOn: $model.syncHinge)
          LabeledContent("Giriş", value: model.hingeAvailable ? "Fiziksel menteşe" : "Manuel sürgü")
        } header: { Text("Katlama") } footer: {
          Text("iPhone Duo’da menteşe 180° ile 90° arasında kapanırken model eşzamanlı katlanır. Diğer cihazlarda sürgüyü kullanın.")
        }
        Section("Kat izleri") {
          ForEach(model.document.creases) { crease in
            HStack {
              Text(crease.mountain ? "Dağ katı" : "Vadi katı")
              Spacer()
              Text("\(crease.start.x, format: .number.precision(.fractionLength(2))), \(crease.start.y, format: .number.precision(.fractionLength(2)))")
                .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            .swipeActions {
              Button("Sil", role: .destructive) {
                model.checkpoint()
                model.document.creases.removeAll { $0.id == crease.id }
              }
            }
          }
          Button("Dikey kat ekle", systemImage: "plus") {
            model.addCrease(from: CGPoint(x: 0.5, y: 0), to: CGPoint(x: 0.5, y: 1))
          }
          Button("Yatay kat ekle", systemImage: "plus") {
            model.addCrease(from: CGPoint(x: 0, y: 0.5), to: CGPoint(x: 1, y: 0.5))
          }
        }
        Section {
          if model.activitiesEnabled || model.activityRunning {
            Button(model.activityRunning ? "Canlı Etkinliği bitir" : "Canlı Etkinliği başlat", systemImage: model.activityRunning ? "pause.fill" : "play.fill") {
              Task { await model.toggleActivity() }
            }
          } else {
            Text("Canlı Etkinlikler cihaz ayarlarında kapalı.").foregroundStyle(.secondary)
          }
        } header: { Text("Canlı Etkinlik") } footer: {
          Text("Proje adı, açı ve kat sayısı kilit ekranında görünür. Çalışmanız bittiğinde etkinliği buradan bitirin.")
        }
      }
      .navigationTitle("Parametreler").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Bitti", systemImage: "checkmark") { dismiss() } } }
    }
    .tint(StudioTheme.copper).presentationDetents([.large])
  }
}
