import SwiftUI

enum StudioTheme {
  static let background = Color(red: 0.055, green: 0.065, blue: 0.075)
  static let panel = Color(red: 0.085, green: 0.098, blue: 0.11)
  static let raised = Color(red: 0.12, green: 0.135, blue: 0.15)
  static let copper = Color(red: 0.92, green: 0.65, blue: 0.45)
  static let muted = Color(red: 0.55, green: 0.59, blue: 0.62)
  static let line = Color.white.opacity(0.08)
  static let mint = Color(red: 0.6, green: 0.82, blue: 0.72)
}

struct StudioTag: View {
  var title: String
  var color: Color = StudioTheme.muted
  var body: some View {
    Text(title).font(.system(size: 9, weight: .semibold, design: .monospaced))
      .tracking(1.2).foregroundStyle(color)
      .padding(.horizontal, 8).padding(.vertical, 5)
      .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 5))
      .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.15)))
  }
}

struct CanvasGrid: View {
  var spacing: CGFloat = 22
  var body: some View {
    Canvas { context, size in
      var path = Path()
      for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
        path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
      }
      for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
        path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
      }
      context.stroke(path, with: .color(.white.opacity(0.035)), lineWidth: 0.5)
    }.allowsHitTesting(false).accessibilityHidden(true)
  }
}
