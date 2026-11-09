import ActivityKit

struct FoldActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var angle: Int
    var creaseCount: Int
  }
  var projectName: String
}
