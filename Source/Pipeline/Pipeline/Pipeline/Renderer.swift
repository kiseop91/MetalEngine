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
        print("draw!")
    }
}
