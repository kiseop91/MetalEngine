

import MetalKit

class Renderer: NSObject {
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!
  let depthStencilState: MTLDepthStencilState
    
  var uniforms = Uniforms()
  
  // Camera holds view and projection matrices
  lazy var camera: Camera = {
    let camera = ArcballCamera()
    camera.distance = 2
    camera.target = [0, 0.5, 0]
    camera.rotation.x = Float(-10).degreesToRadians
    return camera
  }()

  // Array of Models allows for rendering multiple models
  var models: [Model] = []
  
  // Debug drawing of lights
  lazy var lightPipelineState: MTLRenderPipelineState = {
    return buildLightPipelineState()
  }()

    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    func buildDefaultLight() -> Light {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [0.6, 0.6, 0.6]
        light.intensity = 1
        light.attenuation = float3(1, 0, 0)
        light.type = Sunlight
        return light
    }
    
    lazy var sunlight: Light = {
        var light = buildDefaultLight()
        light.position = [1,2,-2]
        return light
    }()
    
    lazy var ambientLight: Light = {
       var light = buildDefaultLight()
        light.intensity = 0.1
        light.color = [0.5, 1, 0]
        light.type = Ambientlight
        return light
    }()
    
    var lights: [Light] = []
    var fragmentUniforms = FragmentUniforms()
    
    
  init(metalView: MTKView) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else {
        fatalError("GPU not available")
    }
    Renderer.device = device
    Renderer.commandQueue = commandQueue
    Renderer.library = device.makeDefaultLibrary()
    metalView.device = device
    metalView.depthStencilPixelFormat = .depth32Float
    
    depthStencilState = Renderer.buildDepthStencilState()!
      
    super.init()
    metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                         blue: 0.8, alpha: 1.0)
    metalView.delegate = self
    
    // add the model to the scene
    let train = Model(name: "train.obj")
    train.position = [0, 0, 0]
    train.rotation = [0, Float(45).degreesToRadians, 0]
    models.append(train)
    
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
      
      lights.append(sunlight)
      lights.append(ambientLight)
      fragmentUniforms.lightCount = UInt32(lights.count)
      
      
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
  }
  
  func draw(in view: MTKView) {
    guard
      let descriptor = view.currentRenderPassDescriptor,
      let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
        return
    }
    
    renderEncoder.setDepthStencilState(depthStencilState)
    
    uniforms.projectionMatrix = camera.projectionMatrix
    uniforms.viewMatrix = camera.viewMatrix
    fragmentUniforms.cameraPosition = camera.position
    
      renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<Light>.stride * lights.count, index: 2)
      renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 3)
      
    // render all the models in the array
    for model in models {
      // model matrix now comes from the Model's superclass: Node
      uniforms.modelMatrix = model.modelMatrix
        uniforms.normalMatrix = uniforms.modelMatrix.upperLeft  
        
      renderEncoder.setVertexBytes(&uniforms,
                                   length: MemoryLayout<Uniforms>.stride, index: 1)
      
      renderEncoder.setRenderPipelineState(model.pipelineState)

      for mesh in model.meshes {
        let vertexBuffer = mesh.mtkMesh.vertexBuffers[0].buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0,
                                      index: 0)

        for submesh in mesh.submeshes {
          let mtkSubmesh = submesh.mtkSubmesh
          renderEncoder.drawIndexedPrimitives(type: .triangle,
                                              indexCount: mtkSubmesh.indexCount,
                                              indexType: mtkSubmesh.indexType,
                                              indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                              indexBufferOffset: mtkSubmesh.indexBuffer.offset)
        }
      }
    }
      
      debugLights(renderEncoder: renderEncoder, lightType: Sunlight)
    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
