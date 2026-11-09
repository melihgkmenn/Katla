import SwiftUI
import WidgetKit
import ActivityKit

struct KatlaLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FoldActivityAttributes.self) { context in
      FoldActivityView(context: context)
        .activityBackgroundTint(Color(red: 0.06, green: 0.08, blue: 0.09))
        .activitySystemActionForegroundColor(.white)
        .widgetURL(URL(string: "katla://studio"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Katla", systemImage: "square.stack.3d.up").foregroundStyle(.orange)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.angle)°").font(.title2.monospacedDigit()).foregroundStyle(.orange)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack { Text(context.attributes.projectName); Spacer(); Text("\(context.state.creaseCount) kat izi").foregroundStyle(.secondary) }.font(.caption)
        }
      } compactLeading: {
        Image(systemName: "square.stack.3d.up").foregroundStyle(.orange)
      } compactTrailing: {
        Text("\(context.state.angle)°").monospacedDigit().foregroundStyle(.orange)
      } minimal: {
        Text("\(context.state.angle)°").font(.caption2.monospacedDigit()).foregroundStyle(.orange)
      }
      .keylineTint(.orange)
      .widgetURL(URL(string: "katla://studio"))
    }
    .supplementalActivityFamilies([.small, .medium])
  }
}

private struct FoldActivityView: View {
  var context: ActivityViewContext<FoldActivityAttributes>
  @Environment(\.activityFamily) private var family
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 5) {
        Label("KATLA", systemImage: "square.stack.3d.up").font(.caption2).foregroundStyle(.orange)
        if family != .small { Text(context.attributes.projectName).font(.headline) }
        Text("\(context.state.creaseCount) kat izi").font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      Text("\(context.state.angle)°").font(.system(.largeTitle, design: .monospaced, weight: .light)).foregroundStyle(.orange)
    }.padding()
  }
}
