import SwiftUI
import Observation
import ActivityKit
import WidgetKit

@MainActor @Observable
final class StudioModel {
  var document: FoldDocument { didSet { save(); scheduleActivityUpdate() } }
  var projects: [FoldDocument]
  var tool: DrawingTool = .crease
  var selectedCrease: UUID?
  var wireframe = UserDefaults.standard.bool(forKey: "katla.wireframe") {
    didSet { UserDefaults.standard.set(wireframe, forKey: "katla.wireframe") }
  }
  var showGrid = UserDefaults.standard.object(forKey: "katla.showGrid") as? Bool ?? true {
    didSet { UserDefaults.standard.set(showGrid, forKey: "katla.showGrid") }
  }
  var syncHinge = UserDefaults.standard.object(forKey: "katla.syncHinge") as? Bool ?? true {
    didSet {
      UserDefaults.standard.set(syncHinge, forKey: "katla.syncHinge")
      if syncHinge, let physicalAngle { angle = physicalAngle }
    }
  }
  var hingeAvailable = false
  var physicalAngle: Double?
  var cameraRevision = 0
  var errorMessage: String?
  var activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
  var activityRunning = false
  private var history: [FoldDocument] = []
  private var activity: Activity<FoldActivityAttributes>?
  private var activityUpdate: Task<Void, Never>?

  init() {
    let saved = UserDefaults.standard.data(forKey: "katla.projects")
      .flatMap { try? JSONDecoder().decode([FoldDocument].self, from: $0) } ?? []
    projects = saved
    let currentID = UserDefaults.standard.string(forKey: "katla.currentProject")
    document = saved.first { $0.id.uuidString == currentID } ?? saved.first ?? FoldDocument.preset(.accordion)
    activity = Activity<FoldActivityAttributes>.activities.first
    activityRunning = activity != nil
  }

  var angle: Double {
    get { document.angle }
    set {
      document.angle = min(180, max(90, newValue))
      scheduleActivityUpdate()
    }
  }

  func checkpoint() { history.append(document) }
  var canUndo: Bool { !history.isEmpty }
  func undo() {
    guard let previous = history.popLast() else { return }
    document = previous
    scheduleActivityUpdate()
  }

  func addCrease(from start: CGPoint, to end: CGPoint) {
    guard hypot(end.x - start.x, end.y - start.y) > 0.08 else { return }
    guard let crease = Crease.spanningPaper(from: start, to: end, mountain: tool != .valley) else { return }
    guard !document.creases.contains(where: { existing in
      let a = existing.start.point; let b = existing.end.point
      let c = crease.start.point; let d = crease.end.point
      return (hypot(a.x - c.x, a.y - c.y) < 0.01 && hypot(b.x - d.x, b.y - d.y) < 0.01)
        || (hypot(a.x - d.x, a.y - d.y) < 0.01 && hypot(b.x - c.x, b.y - c.y) < 0.01)
    }) else { return }
    checkpoint()
    document.creases.append(crease)
    selectedCrease = crease.id
    scheduleActivityUpdate()
  }

  func removeSelectedCrease() {
    guard let selectedCrease else { return }
    checkpoint()
    document.creases.removeAll { $0.id == selectedCrease }
    self.selectedCrease = nil
  }

  func open(_ project: FoldDocument) {
    if let previousActivity = activity {
      activity = nil
      activityRunning = false
      Task { await previousActivity.end(nil, dismissalPolicy: .immediate) }
    }
    document = project
    history.removeAll()
    selectedCrease = nil
    cameraRevision += 1
  }

  func create(_ preset: FoldPreset) {
    let newDocument = FoldDocument.preset(preset)
    projects.insert(newDocument, at: 0)
    open(newDocument)
  }

  func receiveHinge(_ degrees: Double?, closed: Bool = false) {
    hingeAvailable = degrees != nil
    physicalAngle = closed ? nil : degrees
    if syncHinge, !closed, let degrees { angle = degrees }
  }

  func save() {
    if let index = projects.firstIndex(where: { $0.id == document.id }) {
      projects[index] = document
    } else {
      projects.insert(document, at: 0)
    }
    if let data = try? JSONEncoder().encode(projects) {
      UserDefaults.standard.set(data, forKey: "katla.projects")
    }
    UserDefaults.standard.set(document.id.uuidString, forKey: "katla.currentProject")
  }

  func toggleActivity() async {
    if let activity {
      await activity.end(ActivityContent(state: activityState, staleDate: nil), dismissalPolicy: .immediate)
      self.activity = nil
      activityRunning = false
    } else {
      guard activitiesEnabled else { return }
      do {
        activity = try Activity.request(
          attributes: FoldActivityAttributes(projectName: document.name),
          content: ActivityContent(state: activityState, staleDate: nil), pushType: nil)
        activityRunning = true
      } catch {
        errorMessage = "Canlı Etkinlik başlatılamadı: \(error.localizedDescription)"
      }
    }
  }

  func observeActivityAuthorization() async {
    for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
      activitiesEnabled = enabled
    }
  }

  private var activityState: FoldActivityAttributes.ContentState {
    .init(angle: Int(angle.rounded()), creaseCount: document.creases.count)
  }

  private func scheduleActivityUpdate() {
    activityUpdate?.cancel()
    activityUpdate = Task {
      try? await Task.sleep(for: .milliseconds(650))
      guard !Task.isCancelled, let activity else { return }
      await activity.update(ActivityContent(state: activityState, staleDate: nil))
    }
  }
}

struct FoldDocument: Codable, Identifiable, Equatable {
  var id = UUID()
  var name: String
  var width: Double = 210
  var height: Double = 148
  var angle: Double = 128
  var material: PaperMaterial = .copper
  var creases: [Crease]

  static func preset(_ preset: FoldPreset) -> FoldDocument {
    switch preset {
    case .accordion:
      return .init(name: "Akordeon No. 01", creases: (1...5).map { i in
        Crease(start: .init(x: Double(i) / 6, y: 0), end: .init(x: Double(i) / 6, y: 1), mountain: i % 2 == 1)
      })
    case .fan:
      return .init(name: "Yelpaze", creases: (1...5).map { i in
        Crease(start: .init(x: 0.5, y: 1), end: .init(x: Double(i) / 6, y: 0), mountain: i % 2 == 1)
      })
    case .valley:
      return .init(name: "Tek Kıvrım", creases: [Crease(start: .init(x: 0.5, y: 0), end: .init(x: 0.5, y: 1), mountain: true)])
    case .blank:
      return .init(name: "Yeni çalışma", angle: 150, creases: [])
    }
  }
}

struct VectorPoint: Codable, Equatable {
  var x: Double
  var y: Double
  init(x: Double, y: Double) { self.x = x; self.y = y }
  init(_ point: CGPoint) { x = point.x; y = point.y }
  var point: CGPoint { CGPoint(x: x, y: y) }
}

struct Crease: Codable, Identifiable, Equatable {
  var id = UUID()
  var start: VectorPoint
  var end: VectorPoint
  var mountain: Bool

  static func spanningPaper(from start: CGPoint, to end: CGPoint, mountain: Bool) -> Crease? {
    let delta = CGPoint(x: end.x - start.x, y: end.y - start.y)
    var intersections: [(Double, CGPoint)] = []
    if abs(delta.x) > 0.0001 {
      for x in [0.0, 1.0] {
        let t = (x - start.x) / delta.x
        let y = start.y + t * delta.y
        if y >= -0.0001 && y <= 1.0001 { intersections.append((t, CGPoint(x: x, y: min(1, max(0, y))))) }
      }
    }
    if abs(delta.y) > 0.0001 {
      for y in [0.0, 1.0] {
        let t = (y - start.y) / delta.y
        let x = start.x + t * delta.x
        if x >= -0.0001 && x <= 1.0001 { intersections.append((t, CGPoint(x: min(1, max(0, x)), y: y))) }
      }
    }
    intersections.sort { $0.0 < $1.0 }
    guard let first = intersections.first?.1, let last = intersections.last?.1,
          hypot(first.x - last.x, first.y - last.y) > 0.08 else { return nil }
    return .init(start: VectorPoint(first), end: VectorPoint(last), mountain: mountain)
  }
}

enum DrawingTool: String, CaseIterable, Identifiable {
  case select, crease, valley
  var id: Self { self }
  var title: String {
    switch self { case .select: "Seç"; case .crease: "Dağ"; case .valley: "Vadi" }
  }
  var symbol: String {
    switch self { case .select: "pointer.arrow"; case .crease: "pencil.and.outline"; case .valley: "line.diagonal" }
  }
}

enum FoldPreset: String, CaseIterable, Identifiable {
  case accordion, fan, valley, blank
  var id: Self { self }
  var title: String {
    switch self { case .accordion: "Akordeon"; case .fan: "Yelpaze"; case .valley: "Tek kıvrım"; case .blank: "Boş kâğıt" }
  }
  var detail: String {
    switch self { case .accordion: "Ritmik, ardışık katlar"; case .fan: "Bir noktadan açılan form"; case .valley: "İlk katınla başla"; case .blank: "Kendi kat izlerini çiz" }
  }
}

enum PaperMaterial: String, Codable, CaseIterable, Identifiable {
  case copper, ivory, graphite
  var id: Self { self }
  var title: String {
    switch self { case .copper: "Bakır"; case .ivory: "Fildişi"; case .graphite: "Grafit" }
  }
  var color: Color {
    switch self { case .copper: Color(red: 0.92, green: 0.57, blue: 0.35); case .ivory: Color(red: 0.91, green: 0.88, blue: 0.79); case .graphite: Color(red: 0.31, green: 0.39, blue: 0.43) }
  }
}
