//
//  Renderer.swift
//  Pipeline
//
//  Created by 김기섭 on 2022/03/26.
//

import MetalKit

class Renderer : NSObject {
    init(metalView: MTKView){
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else{
                fatalError("GPU not acailable")
            }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        let mdlMesh = Primitive.makeCube(device: device, size: 1)
        do{
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch let error{
            print(error.localizedDescription)
        }
        vertexBuffer = mesh.vertexBuffers[0].buffer
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor =
        MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do{
            pipelineState =
            try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0)
        metalView.delegate = self
        
    }
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
}

extension Renderer : MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
        let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
        let renderEncoder =
        commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        // Drawing code goes here
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: submesh.indexBuffer.offset)
        }
        renderEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
