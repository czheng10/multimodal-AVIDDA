//
//  FrameHandler.swift
//  AVIDDA
//
//  Created by Cindy Zheng on 4/28/25.
//

import AVFoundation
import CoreImage
import AudioToolbox
import UIKit
import MediaPipeTasksVision
import Foundation

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
    
    // alarm
    @Published var showAlert = false
    @Published var isAlertActive = false
    private var criticalSoundID: SystemSoundID = 1312
    private var alarmPlayer: AVAudioPlayer?
    private var alarmTimer: Timer?
    private var volumeIncreaseTimer: Timer?
    private var currentVolume: Float = 0.1

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
                captureSession.sessionPreset = .photo
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

        let drowsinessDetector = DrowsinessDetector()
        let isDrowsy = drowsinessDetector.predict(frames: frames)
        if isDrowsy! {
            triggerDrowsinessAlert()
        }
    }
    
    func triggerDrowsinessAlert() {
        guard isDrowsy else { return }
        isAlertActive = true
        
        // popup
        DispatchQueue.main.async {
            self.showAlert = true
        }
 
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        // Bypass silent mode to play alarm
        AudioServicesPlaySystemSoundWithCompletion(criticalSoundID) {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.setupAndPlayAlarm()
            }
        }
    }
    
    private func setupAndPlayAlarm() {
        guard let alarmURL = Bundle.main.url(forResource: "alarm", withExtension: "caf") else {
            print("Alarm sound file not found")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            alarmPlayer = try AVAudioPlayer(contentsOf: alarmURL)
            alarmPlayer?.numberOfLoops = -1
            alarmPlayer?.volume = currentVolume
            alarmPlayer?.play()
            
            volumeIncreaseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.currentVolume = min(self.currentVolume + 0.1, 1.0)
                self.alarmPlayer?.volume = self.currentVolume
                
                if self.currentVolume >= 1.0 {
                    self.volumeIncreaseTimer?.invalidate()
                }
            }
        } catch {
            print("Failed to play alarm: \(error.localizedDescription)")
        }
    }
    
    func dismissAlert() {
        showAlert = false
        isAlertActive = false
        alarmPlayer?.stop()
        volumeIncreaseTimer?.invalidate()
        currentVolume = 0.1
    }
        
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else {return}
        
        DispatchQueue.main.async{ [unowned self] in
            self.frame = cgImage
            
            // Only collect frames if not currently processing or alerting
            guard self.isRecording, !self.isProcessing, !self.isAlertActive else { return }
            
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            // Collect frames at 24 fps
            if self.lastFrameTime == .zero || timestamp - self.lastFrameTime >= self.targetFrameInterval {
                self.collectedFrames.append(cgImage)
                self.lastFrameTime = timestamp
                print(collectedFrames.count, " FRAMES SO FAR")

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




class DrowsinessDetector {
    @Published var eyeIndices: Set<Int> = [384, 385, 386, 387, 388, 133, 390, 263, 7, 398, 144, 145, 153, 154, 155, 157, 158, 159, 160, 33, 161, 163, 173, 466, 469, 470, 471, 472, 474, 475, 476, 477, 362, 373, 374, 246, 249, 380, 381, 382]
    @Published var poseIndices: Set<Int> = [0, 7, 8, 9, 10, 11, 12]
    @Published var faceLandmarker: FaceLandmarker?
    @Published var poseLandmarker: PoseLandmarker?
    var weights: [Double] = [1.87858007, 3.86422247, 3.73796147]
    var offset: Double =  -4.839405413695547
    var threshold: Double = 0.59
    init() {
        let facePath = Bundle.main.path(forResource: "face_landmarker", ofType: "task")
        let posePath = Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task")
        print("Face model exists:", facePath != nil)
        print("Pose model exists:", posePath != nil)
        
        setupFaceLandmarker()
        setupPoseLandmarker()
        
        // Debug: Verify initialization
        print("FaceLandmarker initialized:", faceLandmarker != nil)
        print("PoseLandmarker initialized:", poseLandmarker != nil)
    }
    
    func convertCGImagesToMPImages(frames: [CGImage]) -> [MPImage] {
        var mpImages: [MPImage] = []

        for cg in frames {
            let uiImage = UIImage(cgImage: cg)
            do {
                let mpImage = try MPImage(uiImage: uiImage)  // Use .image: UIImage initializer
                mpImages.append(mpImage)
            } catch {
                print("Failed to convert frame to MPImage: \(error)")
            }
        }

        return mpImages
    }

    func setupFaceLandmarker() {
        guard let modelPath = Bundle.main.path(forResource: "face_landmarker", ofType: "task") else {
            print("Model file not found")
            return
        }

        let options = FaceLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.numFaces = 1

        do {
            faceLandmarker = try FaceLandmarker(options: options)
        } catch {
            print("Failed to initialize FaceLandmarker: \(error)")
        }
    }
    
    func setupPoseLandmarker() {
        guard let modelPath = Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task") else {
            print("Pose model not found")
            return
        }

        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image

        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            print("Failed to initialize pose detector: \(error)")
        }
    }

    func extractEyeAndHeadFeatures(from result: FaceLandmarkerResult, eyeIndices: Set<Int>) -> (eye: [[Float]], head: [[Float]]) {
        guard let face = result.faceLandmarks.first else { return ([], []) }

        var eyeFeatures = [[Float]]()
        var headFeatures = [[Float]]()

        for (index, point) in face.enumerated() {
            let coords: [Float] = [point.x, point.y, point.z]

            if eyeIndices.contains(index) {
                eyeFeatures.append(coords)
            } else {
                headFeatures.append(coords)
            }
        }

        return (eye: eyeFeatures, head: headFeatures)
    }
    
    func extractPoseFeatures(from result: PoseLandmarkerResult, poseIndices: Set<Int>) -> ([[Float]]) {
        guard let pose = result.landmarks.first else { return ([]) }

        var poseFeatures = [[Float]]()

        for (index, point) in pose.enumerated() {
            let coords: [Float] = [point.x, point.y, point.z]

            if poseIndices.contains(index) {
                poseFeatures.append(coords)
            }
        }

        return (poseFeatures)
    }
    
    func extractFeatures(
        frames: [CGImage],
        faceLandmarker: FaceLandmarker,
        poseLandmarker: PoseLandmarker,
        eyeIndices: Set<Int>,
        poseIndices: Set<Int>) -> (eye: [[[Float]]], head: [[[Float]]], pose: [[[Float]]]) {
            
            var eyeFeatures = [[[Float]]]()
            var headFeatures = [[[Float]]]()
            var poseFeatures = [[[Float]]]()
            let MPImageFrames = convertCGImagesToMPImages(frames: frames)
        
            for mpImage in MPImageFrames{
                do {
                    let faceResult = try faceLandmarker.detect(image: mpImage)
                    let poseResult = try poseLandmarker.detect(image: mpImage)

                    let (eye, head) = extractEyeAndHeadFeatures(from: faceResult, eyeIndices: eyeIndices)
                    let pose = extractPoseFeatures(from: poseResult, poseIndices: poseIndices)

                    eyeFeatures.append(eye)
                    headFeatures.append(head)
                    poseFeatures.append(pose)
                } catch {
                    print("Pose or face detection failed on one of the frames: \(error)")
                }
        }

            return (eye: eyeFeatures, head: headFeatures, pose: poseFeatures)
    }
    

    func prepareData(input: [[[Float]]], featureCount: Int) -> [Float] {
        // 2D padding for one frame: featureCount rows of [0.0, 0.0, 0.0]
        let padding = Array(repeating: Array(repeating: Float(0), count: 3), count: featureCount)

        var paddedSample: [[[Float]]] = []

        for frame in input {
            if frame.isEmpty {
                paddedSample.append(padding)
            } else {
                paddedSample.append(frame)
            }
        }

        let flattened = paddedSample.flatMap { $0 }.flatMap { $0 }
        return flattened
    }

    struct DecisionTree: Codable {
        let childrenLeft: [Int]
        let childrenRight: [Int]
        let feature: [Int]
        let threshold: [Double]
        let value: [[Double]]
    }

    struct AdaBoostModel: Codable {
        let trees: [DecisionTree]
    }

    class AdaBoostClassifier {
        private let trees: [DecisionTree]
        private init(trees: [DecisionTree]) {
            self.trees = trees
        }
        convenience init(modelName: String) throws {
            guard let path = Bundle.main.path(forResource: modelName, ofType: "json") else {
                throw NSError(domain: "AdaBoostClassifier", code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "File \(modelName).json not found"])
            }
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let model = try decoder.decode(AdaBoostModel.self, from: data)
                self.init(trees: model.trees)
            } catch {
                print("Decoding failed: \(error)")
                throw error
            }
        }
        
        private init(jsonData: Data) throws {
            let model = try JSONDecoder().decode(AdaBoostModel.self, from: jsonData)
            self.trees = model.trees
        }
        
        
        func predictProbability(features: [Double]) -> Double {
            var sum: Double = 0.0
            
            for tree in trees {
                sum += predictSingleTree(tree: tree, features: features)
            }
            
            // AdaBoost produces a weighted sum that we need to convert to probability
            let probability = 1.0 / (1.0 + exp(-sum))
            return probability
        }
        
        private func predictSingleTree(tree: DecisionTree, features: [Double]) -> Double {
            var node = 0
            
            while true {
                let leftChild = tree.childrenLeft[node]
                let rightChild = tree.childrenRight[node]
                
                // If it's a leaf node
                if leftChild == -1 && rightChild == -1 {
                    // Return the positive class value (assuming binary classification)
                    return tree.value[node][1]
                }
                
                let featureIndex = tree.feature[node]
                let threshold = tree.threshold[node]
                
                if features[featureIndex] <= threshold {
                    node = leftChild
                } else {
                    node = rightChild
                }
            }
        }
    }

    func sigmoid(_ x: Double) -> Double {
        return 1.0 / (1.0 + exp(-x))
    }
    
    func predict(frames: [CGImage]) -> Bool? {
        guard let faceLandmarker = faceLandmarker, let poseLandmarker = poseLandmarker else {
            print("Landmarkers not initialized")
            return nil
        }
        
        // Initialize models
        let modelNames = ["eye_model", "head_model", "pose_model"]
        for name in modelNames {
            if Bundle.main.path(forResource: name, ofType: "json") != nil {
                print("Found: \(name).json")
            } else {
                print("Missing: \(name).json")
            }
        }
        guard let eyeModel = try? AdaBoostClassifier(modelName: "eye_model"),
              let headModel = try? AdaBoostClassifier(modelName: "head_model"),
              let poseModel = try? AdaBoostClassifier(modelName: "pose_model") else {
            print("Failed to initialize one or more models")
            return nil
        }
        
        // Extract features
        let (eye, head, pose) = extractFeatures(
            frames: frames,
            faceLandmarker: faceLandmarker,
            poseLandmarker: poseLandmarker,
            eyeIndices: eyeIndices,
            poseIndices: poseIndices
        )
        
        // Prepare input data
        let eyeInput = prepareData(input: eye, featureCount: eyeIndices.count)
        let headInput = prepareData(input: head, featureCount: 438)
        let poseInput = prepareData(input: pose, featureCount: poseIndices.count)
        
        // Convert to Double
        let doubleEye = eyeInput.map { Double($0) }
        let doubleHead = headInput.map { Double($0) }
        let doublePose = poseInput.map { Double($0) }
        
        do {
            // Make predictions
            let eyePred = try eyeModel.predictProbability(features: doubleEye)
            let headPred = try headModel.predictProbability(features: doubleHead)
            let posePred = try poseModel.predictProbability(features: doublePose)
            let preds: [Double] = [eyePred, headPred, posePred]
            print(preds)
            let result = zip(preds, weights).map(*)
            let sum = result.reduce(0, +)
            let weightedPrediction:Double = sum + offset
            
            let predProb = sigmoid(weightedPrediction)
            let pred = predProb > threshold
            print(predProb)
            return pred
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
    
    
}





