import SwiftUI
import WidgetKit

struct KatlaInspirationWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "KatlaInspiration", provider: InspirationProvider()) { entry in
      InspirationWidgetView(entry: entry)
        .containerBackground(Color(red: 0.06, green: 0.08, blue: 0.09), for: .widget)
        .widgetURL(URL(string: "katla://studio"))
    }
    .configurationDisplayName("Günün kıvrımı")
    .description("Her gün yeni bir katlama fikri. Stüdyoyu açmak için dokunun.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

private struct InspirationEntry: TimelineEntry {
  var date: Date
  var title: String
  var subtitle: String
}

private struct InspirationProvider: TimelineProvider {
  func placeholder(in context: Context) -> InspirationEntry { entry(Date()) }
  func getSnapshot(in context: Context, completion: @escaping (InspirationEntry) -> Void) { completion(entry(Date())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<InspirationEntry>) -> Void) {
    let today = Date()
    let next = Calendar.current.nextDate(after: today, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) ?? today.addingTimeInterval(86400)
    completion(Timeline(entries: [entry(today)], policy: .after(next)))
  }
  private func entry(_ date: Date) -> InspirationEntry {
    let ideas = [("Akordeon", "Bir çizgiden ritim yarat."), ("Yelpaze", "Bir noktadan dünyaya açıl."), ("Tek kıvrım", "Bazen bir kat yeter.")]
    let idea = ideas[Calendar.current.component(.day, from: date) % ideas.count]
    return .init(date: date, title: idea.0, subtitle: idea.1)
  }
}

private struct InspirationWidgetView: View {
  var entry: InspirationEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 8) {
        Text("KATLA").font(.caption2.monospaced().weight(.semibold)).tracking(3).foregroundStyle(Color.orange.opacity(0.8))
        Spacer()
        Image(systemName: "square.stack.3d.up.fill").font(.system(size: 30, weight: .light)).foregroundStyle(Color(red: 0.92, green: 0.65, blue: 0.45))
        Text(entry.title).font(.headline)
        Text(entry.subtitle).font(.caption2).foregroundStyle(.secondary)
      }
      if family == .systemMedium {
        Spacer()
        Image(systemName: "square.stack.3d.up").font(.system(size: 72, weight: .ultraLight)).foregroundStyle(Color(red: 0.92, green: 0.65, blue: 0.45))
      }
    }
  }
}
