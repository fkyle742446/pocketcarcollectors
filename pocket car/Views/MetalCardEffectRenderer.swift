
import MetalKit

class MetalCardEffectRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    // Ajouter d'autres propriétés nécessaires (textures, etc.)

    // Simple vertex data for a quad (rectangle)
    let vertices: [Float] = [
        // Positions       // Texture Coords
        -1.0,  1.0, 0.0,   0.0, 0.0, // Top-left
         1.0,  1.0, 0.0,   1.0, 0.0, // Top-right
        -1.0, -1.0, 0.0,   0.0, 1.0, // Bottom-left
         1.0, -1.0, 0.0,   1.0, 1.0  // Bottom-right
    ]
    
    let indices: [UInt16] = [
        0, 1, 2,
        1, 3, 2
    ]
    var indexBuffer: MTLBuffer?


    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        self.commandQueue = self.device.makeCommandQueue()!
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb // Standard pixel format
        metalKitView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0) // Transparent background

        super.init()
        
        setupPipeline()
        setupBuffers()
    }

    private func setupPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            print("Could not load default Metal library")
            return
        }
        
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader_HolographicEX") // Nom spécifique pour notre shader

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        // pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        // pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        // pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        // pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        // pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        // pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        // pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha


        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    private func setupBuffers() {
        let vertexDataSize = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexDataSize, options: [])
        
        let indexDataSize = indices.count * MemoryLayout<UInt16>.size
        indexBuffer = device.makeBuffer(bytes: indices, length: indexDataSize, options: [])
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Respond to view size changes if needed
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              let indexBuffer = indexBuffer,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        // renderPassDescriptor.colorAttachments[0].loadAction = .clear // Clear each frame for opaque
        // renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0) // Or another color for testing
        renderPassDescriptor.colorAttachments[0].loadAction = .dontCare // If drawing over something and shaders handle full coverage

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Uniforms can be passed here (e.g., time for animation, touch coordinates)
        // var currentTime = Float(CACurrentMediaTime()) // Example
        // renderEncoder.setFragmentBytes(&currentTime, length: MemoryLayout<Float>.size, index: 0)


        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indices.count,
                                            indexType: .uint16,
                                            indexBuffer: indexBuffer,
                                            indexBufferOffset: 0)

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
