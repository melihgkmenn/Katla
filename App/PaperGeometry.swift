import SceneKit
import simd

enum PaperGeometry {
  struct FoldTransform {
    var start: SIMD2<Float>
    var end: SIMD2<Float>
    var origin: SIMD3<Float>
    var axis: SIMD3<Float>
    var cosine: Float
    var sine: Float
  }

  static func transforms(_ document: FoldDocument) -> [FoldTransform] {
    var result: [FoldTransform] = []
    for crease in document.creases {
      let a = SIMD2<Float>(Float(crease.start.x), Float(crease.start.y))
      let b = SIMD2<Float>(Float(crease.end.x), Float(crease.end.y))
      let origin = transformed(flat(a, document), original: a, folds: result)
      let end = transformed(flat(b, document), original: b, folds: result)
      let delta = end - origin
      guard simd_length(delta) > 0.001 else { continue }
      let angle = Float((180 - document.angle) * .pi / 180) * (crease.mountain ? 1 : -1)
      result.append(.init(start: a, end: b, origin: origin, axis: simd_normalize(delta), cosine: cos(angle), sine: sin(angle)))
    }
    return result
  }

  static func transformed(_ point: SIMD3<Float>, original: SIMD2<Float>, folds: [FoldTransform]) -> SIMD3<Float> {
    var result = point
    for fold in folds {
      let a = fold.start
      let b = fold.end
      let side = (b.x - a.x) * (original.y - a.y) - (b.y - a.y) * (original.x - a.x)
      guard side < -0.00001 else { continue }
      let v = result - fold.origin
      result = fold.origin + v * fold.cosine + simd_cross(fold.axis, v) * fold.sine + fold.axis * simd_dot(fold.axis, v) * (1 - fold.cosine)
    }
    return result
  }

  static func flat(_ point: SIMD2<Float>, _ document: FoldDocument) -> SIMD3<Float> {
    SIMD3((point.x - 0.5) * 4.8, 0, (point.y - 0.5) * 4.8 * Float(document.height / document.width))
  }

  static func mesh(_ document: FoldDocument) -> (SCNGeometry, SIMD3<Float>) {
    let folds = transforms(document)
    let columns = 60
    let rows = 36
    var grid: [SIMD3<Float>] = []
    for row in 0...rows {
      for column in 0...columns {
        let uv = SIMD2<Float>(Float(column) / Float(columns), Float(row) / Float(rows))
        grid.append(transformed(flat(uv, document), original: uv, folds: folds))
      }
    }
    let center = grid.reduce(SIMD3<Float>.zero, +) / Float(grid.count)
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var indices: [Int32] = []
    for row in 0..<rows {
      for column in 0..<columns {
        let a = row * (columns + 1) + column
        let b = a + 1
        let c = a + columns + 1
        let d = c + 1
        for triangle in [[a, c, b], [b, c, d]] {
          let p = triangle.map { grid[$0] - center }
          let normal = simd_normalize(simd_cross(p[1] - p[0], p[2] - p[0]))
          for v in p {
            indices.append(Int32(vertices.count))
            vertices.append(SCNVector3(v.x, v.y, v.z))
            normals.append(SCNVector3(normal.x, normal.y, normal.z))
          }
        }
      }
    }
    let geometry = SCNGeometry(sources: [.init(vertices: vertices), .init(normals: normals)], elements: [.init(indices: indices, primitiveType: .triangles)])
    return (geometry, center)
  }

  static func obj(_ document: FoldDocument) -> String {
    let (geometry, _) = mesh(document)
    guard let source = geometry.sources(for: .vertex).first else { return "" }
    var lines = ["# Katla – \(document.name)", "# Units: mm; hinge: \(document.angle) degrees"]
    source.data.withUnsafeBytes { buffer in
      for i in 0..<source.vectorCount {
        let offset = source.dataOffset + i * source.dataStride
        let x = buffer.loadUnaligned(fromByteOffset: offset, as: Float.self) * Float(document.width / 4.8)
        let y = buffer.loadUnaligned(fromByteOffset: offset + 4, as: Float.self) * Float(document.width / 4.8)
        let z = buffer.loadUnaligned(fromByteOffset: offset + 8, as: Float.self) * Float(document.width / 4.8)
        lines.append("v \(x) \(y) \(z)")
      }
    }
    for i in stride(from: 1, through: source.vectorCount - 2, by: 3) { lines.append("f \(i) \(i + 1) \(i + 2)") }
    return lines.joined(separator: "\n")
  }
}
