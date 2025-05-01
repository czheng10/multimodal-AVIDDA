//
//  FrameHandler.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 4/28/25.
//

import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject {
    // video recording
    @Published var frame:CGImage?
    @Published var isRecording = false
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    
    // frame processing
    private var collectedFrames: [CGImage] = []
    private var lastFrameTime: CMTime = .zero
    private let targetFrameInterval = CMTime(value: 1, timescale: 24) // 24 fps
    private let framesPerVideo = 240
    private var isProcessing = false
    
    // prediction
    private var isDrowsy = false
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
            
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard permissionGranted else {return}
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {return}
        
        if captureSession.canSetSessionPreset(.hd1280x720) {
                captureSession.sessionPreset = .hd1280x720
            } else {
                captureSession.sessionPreset = .photo // Fallback
            }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {return}
        guard captureSession.canAddInput(videoDeviceInput) else {return}
        captureSession.addInput(videoDeviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        videoOutput.connection(with: .video)?.isVideoMirrored = true
    }
    
    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        collectedFrames.removeAll()
        lastFrameTime = .zero
    }
        
    private func stopRecording() {
        isRecording = false
        collectedFrames.removeAll()
    }
    
    private func processCollectedFrames() {
        guard !collectedFrames.isEmpty else { return }
        isProcessing = true
        let framesToProcess = collectedFrames
        collectedFrames.removeAll()
        
        // Call your prediction method
        extractAndPredict(with: framesToProcess) { [weak self] in
            self?.isProcessing = false
        }
    }
    
    private func extractAndPredict(with frames: [CGImage], completion: @escaping () -> Void) {
        // Given frame collection, extract features from each and predict
        print("Making prediction with \(frames.count) frames")
        
        DispatchQueue.main.async {
            completion()
        }
    }
    
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else {return}
        
        DispatchQueue.main.async{ [unowned self] in
            self.frame = cgImage
            
            // Only collect frames if we're recording and not currently processing
            guard self.isRecording, !self.isProcessing else { return }
            
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            // Collect frames at target frame rate
            if self.lastFrameTime == .zero || timestamp - self.lastFrameTime >= self.targetFrameInterval {
                self.collectedFrames.append(cgImage)
                self.lastFrameTime = timestamp
                print(collectedFrames.count, " FRAMES SO FAR")
                // Check if we've collected enough frames
                if self.collectedFrames.count >= self.framesPerVideo {
                    self.processCollectedFrames()
                }
            }
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return nil}
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {return nil}
        return cgImage
    }
}
