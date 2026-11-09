import SwiftUI
import SceneKit

struct PaperSceneView: UIViewRepresentable {
  var document: FoldDocument
  var wireframe: Bool
  var cameraRevision: Int

  func makeUIView(context: Context) -> SCNView {
    let view = PaperRenderView()
    view.backgroundColor = .clear
    view.scene = SCNScene()
    view.allowsCameraControl = true
    view.autoenablesDefaultLighting = false
    view.antialiasingMode = .multisampling4X
    view.defaultCameraController.inertiaEnabled = true
    let camera = SCNNode()
    camera.name = "camera"
    camera.camera = SCNCamera()
    camera.camera?.usesOrthographicProjection = true
    camera.camera?.orthographicScale = 2
    camera.camera?.zFar = 100
    view.scene?.rootNode.addChildNode(camera)
    view.pointOfView = camera
    resetCamera(view)
    let light = SCNNode()
    light.light = SCNLight()
    light.light?.type = .directional
    light.light?.intensity = 950
    light.light?.color = UIColor(red: 1, green: 0.87, blue: 0.74, alpha: 1)
    light.light?.castsShadow = true
    light.light?.shadowMode = .deferred
    light.light?.shadowRadius = 12
    light.light?.shadowColor = UIColor.black.withAlphaComponent(0.6)
    light.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 5, 0)
    view.scene?.rootNode.addChildNode(light)
    let fill = SCNNode()
    fill.light = SCNLight()
    fill.light?.type = .omni
    fill.light?.intensity = 450
    fill.light?.color = UIColor(red: 0.66, green: 0.78, blue: 0.88, alpha: 1)
    fill.position = SCNVector3(-4, 2, 4)
    view.scene?.rootNode.addChildNode(fill)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.intensity = 250
    view.scene?.rootNode.addChildNode(ambient)
    let floor = SCNFloor()
    floor.reflectivity = 0
    floor.firstMaterial?.diffuse.contents = UIColor(red: 0.065, green: 0.075, blue: 0.08, alpha: 1)
    let floorNode = SCNNode(geometry: floor)
    floorNode.position.y = -0.9
    view.scene?.rootNode.addChildNode(floorNode)
    return view
  }

  func updateUIView(_ view: SCNView, context: Context) {
    guard context.coordinator.document != document || context.coordinator.wireframe != wireframe else {
      if context.coordinator.cameraRevision != cameraRevision { resetCamera(view); context.coordinator.cameraRevision = cameraRevision }
      return
    }
    context.coordinator.document = document
    context.coordinator.wireframe = wireframe
    view.scene?.rootNode.childNode(withName: "paper", recursively: false)?.removeFromParentNode()
    let (geometry, center) = PaperGeometry.mesh(document)
    let material = SCNMaterial()
    material.lightingModel = .physicallyBased
    material.diffuse.contents = UIColor(document.material.color)
    material.metalness.contents = document.material == .copper ? 0.18 : 0.05
    material.roughness.contents = 0.47
    material.isDoubleSided = true
    material.fillMode = wireframe ? .lines : .fill
    geometry.materials = [material]
    let paper = SCNNode(geometry: geometry)
    paper.name = "paper"
    let folds = PaperGeometry.transforms(document)
    for crease in document.creases {
      let a = SIMD2<Float>(Float(crease.start.x), Float(crease.start.y))
      let b = SIMD2<Float>(Float(crease.end.x), Float(crease.end.y))
      var vertices: [SCNVector3] = []
      var indices: [Int32] = []
      for i in 0...36 {
        let uv = a + (b - a) * Float(i) / 36
        let v = PaperGeometry.transformed(PaperGeometry.flat(uv, document), original: uv, folds: folds) - center
        vertices.append(SCNVector3(v.x, v.y + 0.006, v.z))
        if i < 36 { indices.append(Int32(i)); indices.append(Int32(i + 1)) }
      }
      let line = SCNGeometry(sources: [.init(vertices: vertices)], elements: [.init(indices: indices, primitiveType: .line)])
      line.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.73, blue: 0.49, alpha: 0.8)
      line.firstMaterial?.lightingModel = .constant
      paper.addChildNode(SCNNode(geometry: line))
    }
    view.scene?.rootNode.addChildNode(paper)
    if context.coordinator.cameraRevision != cameraRevision { resetCamera(view) }
    context.coordinator.cameraRevision = cameraRevision
  }

  func resetCamera(_ view: SCNView) {
    let camera = view.scene?.rootNode.childNode(withName: "camera", recursively: false)
    camera?.position = SCNVector3(5.5, 4.5, 7)
    camera?.look(at: SCNVector3(0, -0.1, 0))
    view.pointOfView = camera
    (view as? PaperRenderView)?.fitCamera()
  }

  func makeCoordinator() -> Coordinator { Coordinator() }
  class Coordinator {
    var document: FoldDocument?
    var wireframe = false
    var cameraRevision = -1
  }
}

private final class PaperRenderView: SCNView {
  private var previousSize = CGSize.zero
  override func layoutSubviews() {
    super.layoutSubviews()
    if bounds.size != previousSize {
      previousSize = bounds.size
      fitCamera()
    }
  }
  func fitCamera() {
    guard bounds.height > 0, bounds.width > 0 else { return }
    pointOfView?.camera?.orthographicScale = max(1.7, 3.3 / Double(bounds.width / bounds.height))
  }
}
