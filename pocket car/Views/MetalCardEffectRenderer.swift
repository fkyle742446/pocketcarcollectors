import MetalKit

class MetalCardEffectRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    private var currentTime: Float = 0.0
    private var currentNormalizedTouchLocation: simd_float2 = simd_float2(0.5, 0.5)
    var vertexDescriptor: MTLVertexDescriptor!

    let vertices: [Float] = [
        -1.0,  1.0, 0.0,        0.0, 0.0,
         1.0,  1.0, 0.0,        1.0, 0.0,
        -1.0, -1.0, 0.0,        0.0, 1.0,
         1.0, -1.0, 0.0,        1.0, 1.0
    ]
    
    let indices: [UInt16] = [
        0, 1, 2,
        1, 3, 2
    ]

    init?(metalKitView: MTKView) {
        guard let device = metalKitView.device else {
            print("‼️ MetalKitView does not have a Metal device. Renderer cannot be initialized.")
            return nil 
        }
        self.device = device
        
        guard let commandQueue = self.device.makeCommandQueue() else {
            print("‼️ Failed to create Metal command queue.")
            return nil
        }
        self.commandQueue = commandQueue
        
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metalKitView.isPaused = false 
        metalKitView.enableSetNeedsDisplay = false 
        
        super.init()
        
        print("Renderer Init: Device and Command Queue OK.")
        
        setupVertexDescriptor()
        setupPipeline(metalKitView: metalKitView) 
        setupBuffers()

        if pipelineState == nil {
            print("‼️ Pipeline state is nil after setup. Shaders might not have loaded or compiled correctly.")
        }
        print("✅ MetalCardEffectRenderer initialized.")
    }

    func updateNormalizedTouchLocation(_ location: CGPoint) {
        self.currentNormalizedTouchLocation = simd_float2(Float(location.x), Float(location.y))
    }

    private func setupVertexDescriptor() {
        vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float3 
        vertexDescriptor.attributes[0].offset = 0 
        vertexDescriptor.attributes[0].bufferIndex = 0 

        vertexDescriptor.attributes[1].format = .float2 
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 3 
        vertexDescriptor.attributes[1].bufferIndex = 0 

        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 5 
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        print("Vertex Descriptor Configured OK.")
    }

    private func setupPipeline(metalKitView: MTKView) {
        guard let library = device.makeDefaultLibrary() else {
            print("‼️ Could not load default Metal library. Check if CardShaders.metal is compiled and linked.")
            return 
        }
        print("Shader Library Loaded OK.")
        
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader_HolographicEX")

        if vertexFunction == nil {
            print("‼️ Could not load VERTEX shader function 'vertexShader'. Check name and compilation.")
        }
        if fragmentFunction == nil {
            print("‼️ Could not load FRAGMENT shader function 'fragmentShader_HolographicEX'. Check name and compilation.")
        }
        guard let vertFunc = vertexFunction, let fragFunc = fragmentFunction else {
            return 
        }
        print("Shader Functions Loaded OK: Vertex & Fragment.")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("✅ Render pipeline state created successfully.")
        } catch {
            print("‼️ Failed to create render pipeline state: \(error)")
        }
    }
    
    private func setupBuffers() {
        let vertexDataSize = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexDataSize, options: [])
        
        let indexDataSize = indices.count * MemoryLayout<UInt16>.size
        indexBuffer = device.makeBuffer(bytes: indices, length: indexDataSize, options: [])
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("MTKView size changing to: \(size)")
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer, let indexBuffer = indexBuffer,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        currentTime += 0.016 

        renderPassDescriptor.colorAttachments[0].loadAction = .clear 
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0) 


        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentBytes(&currentTime, length: MemoryLayout<Float>.size, index: 0)
        renderEncoder.setFragmentBytes(&currentNormalizedTouchLocation, length: MemoryLayout<simd_float2>.size, index: 1)

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
