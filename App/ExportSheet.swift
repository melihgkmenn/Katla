import SwiftUI
import UniformTypeIdentifiers

struct ExportSheet: View {
  var document: FoldDocument
  @Environment(\.dismiss) private var dismiss
  @State private var exportFile = StudioExportDocument(text: "")
  @State private var exportType = UTType.plainText
  @State private var filename = "Katla.obj"
  @State private var showingExporter = false
  @State private var errorMessage: String?
  var body: some View {
    NavigationStack {
      List {
        Section {
          Text(document.name).font(.headline)
          Text("\(Int(document.width)) × \(Int(document.height)) mm · \(document.creases.count) kat izi")
            .font(.caption.monospaced()).foregroundStyle(.secondary)
        }
        Section("Dışa aktarma biçimi") {
          Button("3D model · OBJ", systemImage: "cube") {
            exportFile = StudioExportDocument(text: PaperGeometry.obj(document))
            exportType = UTType(filenameExtension: "obj") ?? .plainText
            filename = "Katla.obj"; showingExporter = true
          }
          Button("Blueprint · SVG", systemImage: "ruler") {
            exportFile = StudioExportDocument(text: svg())
            exportType = .svg
            filename = "Katla.svg"; showingExporter = true
          }
        }
      }.navigationTitle("Dışa aktar").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Kapat", systemImage: "xmark") { dismiss() } } }
    }
    .fileExporter(isPresented: $showingExporter, document: exportFile, contentType: exportType, defaultFilename: filename) { result in
      if case .failure(let error) = result { errorMessage = error.localizedDescription }
    }
    .alert("Dosya kaydedilemedi", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
      Button("Tamam", role: .cancel) {}
    } message: { Text(errorMessage ?? "") }
    .tint(StudioTheme.copper).presentationDetents([.medium, .large])
  }
  private func svg() -> String {
    let lines = document.creases.map { crease in
      "<line x1=\"\(crease.start.x * document.width)\" y1=\"\(crease.start.y * document.height)\" x2=\"\(crease.end.x * document.width)\" y2=\"\(crease.end.y * document.height)\" stroke=\"#c77b4d\" stroke-width=\"0.3\"\(crease.mountain ? "" : " stroke-dasharray=\"3 2\"")/>"
    }.joined(separator: "\n")
    return """
    <svg xmlns="http://www.w3.org/2000/svg" width="\(document.width)mm" height="\(document.height)mm" viewBox="0 0 \(document.width) \(document.height)">
    <rect x="0" y="0" width="\(document.width)" height="\(document.height)" fill="none" stroke="black" stroke-width="0.3"/>
    \(lines)
    </svg>
    """
  }
}

struct StudioExportDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.plainText, .svg, UTType(filenameExtension: "obj") ?? .data] }
  var text: String
  init(text: String) { self.text = text }
  init(configuration: ReadConfiguration) throws {
    text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: Data(text.utf8))
  }
}
