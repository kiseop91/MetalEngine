//
//  Primitive.swift
//  Pipeline
//
//  Created by 김기섭 on 2022/03/26.
//

import MetalKit

class Primitive {
    static func makeCube(device: MTLDevice, size: Float) -> MDLMesh{
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size,size,size],
                           segments: [1,1,1],
                           inwardNormals: false,
                           geometryType: .triangles,
                           allocator: allocator)
        return mesh
    }
}
