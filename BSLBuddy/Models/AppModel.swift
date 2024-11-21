//
//  AppModel.swift
//  BSLBuddy
//
//  Created by Guest 2 on 16/11/2024.
//


import SwiftUI
import Vision
import CoreML

final class AppModel: ObservableObject {
//    static let defaultMLModelName = "bslinterpreter.mlmodelc"
//    static let defaultMLModelName = "rockpaperscissors.mlmodelc"
    static let defaultMLModelName = "ASLClassifier.mlmodelc"
//    static let defaultMLModelName = "aslclassifier.mlmodelc"
    let camera = MLCamera()
    let predictionTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    @Published var currentMLModel: HandPoseMLModel? {
        didSet {
            guard let model = currentMLModel else { return }
            camera.mlDelegate?.updateMLModel(with: model)
        }
    }
    
    @Published var defaultMLModel: HandPoseMLModel?
    @Published var availableHandPoseMLModels = Set<HandPoseMLModel>()
    
    @Published var nodePoints: [CGPoint] = []
    @Published var isHandInFrame: Bool = false {
        didSet {
            if isQuizMode && !oldValue && !hasQuestionGenerated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.currentQuestion = self.getRandomQuestion() ?? ""
                    self.hasQuestionGenerated = true
                }
            }
        }
    }

    @Published var predictionProbability = PredictionMetrics()
    @Published var canPredict: Bool = false
    @Published var predictionLabel: String = ""
    @Published var confidence: String = ""
    @Published var isGatheringObservations: Bool = true
    @Published var isQuizMode: Bool = false
    @Published var currentQuestion: String = ""

    @Published var viewfinderImage: Image?
    @Published var shouldPauseCamera: Bool = false {
        didSet {
            if shouldPauseCamera {
                camera.stop()
                isGatheringObservations = false
            } else {
                Task {
                    await camera.start()
                }
            }
        }
    }
    
    var hasQuestionGenerated: Bool = false
    
    let aslDictionary: [String: String] = [
        "What is the ASL sign for the letter 'A'?": "a",
        "How is the letter 'B' represented in ASL?": "b",
        "Can you demonstrate the ASL sign for 'C'?": "c",
        "What does the ASL sign for 'D' look like?": "d",
        "How do you sign the letter 'E' in ASL?": "e",
        "What is the correct handshape for 'F' in ASL?": "f",
        "How do you represent the letter 'G' in ASL?": "g",
        "What is the ASL sign for the letter 'H'?": "h",
        "How do you sign the letter 'I' in ASL?": "i",
        "How is the letter 'K' signed in ASL?": "k",
        "What is the ASL handshape for the letter 'L'?": "l",
        "Can you show how to sign the letter 'M' in ASL?": "m",
        "What does the ASL sign for the letter 'N' look like?": "n",
        "How is the letter 'O' represented in ASL?": "o",
        "What is the ASL sign for the letter 'P'?": "p",
        "How do you form the letter 'Q' in ASL?": "q",
        "What is the handshape for 'R' in ASL?": "r",
        "How do you sign the letter 'S' in ASL?": "s",
        "What does the ASL sign for 'T' look like?": "t",
        "How is the letter 'U' represented in ASL?": "u",
        "What is the ASL sign for the letter 'V'?": "v",
        "How do you sign the letter 'W' in ASL?": "w",
        "What is the ASL representation for 'X'?": "x",
        "How is the letter 'Y' signed in ASL?": "y"
    ]

   private var handposeMLModelURLs: [URL] {
        let urls = availableHandPoseMLModels.map { $0.url }
        return urls
    }
    
    init() {
        camera.mlDelegate = self
        setDefaultMLModel()
        Task {
            await handleCameraPreviews()
        }
    }
    
    func findExistingModels() async {
        let models = await HandPoseMLModel.findExistingModels(exclude: handposeMLModelURLs)
        for model in models {
            availableHandPoseMLModels.insert(model)
        }
    }
    
    func getRandomQuestion() -> String? {
        aslDictionary.keys.randomElement()
    }

    func useLastTrainedModel() async {
        guard let lastTrained = await HandPoseMLModel.getLastTrainedModel() else {
            print("Couldn't find any recently trained ML models.")
            return
        }
        
        Task { @MainActor in
            self.currentMLModel = lastTrained
            print("Using last trained ML model in your RPS game: \(lastTrained.name)")
        }
    }

    private func handleCameraPreviews() async {
        let imageStream = camera.previewStream.map { $0.image }
        for await image in imageStream {
            Task { @MainActor in
                self.viewfinderImage = image
            }
        }
    }
    
    private func setDefaultMLModel() {
        Task {
            guard let mlModel = await HandPoseMLModel.getDefaultMLModel() else { return }
            Task { @MainActor in
                self.defaultMLModel = mlModel
                self.currentMLModel = mlModel
                self.availableHandPoseMLModels.insert(mlModel)
            }
        }
    }
}

extension AppModel: MLDelegate {
    func updateMLModel(with model: NSObject) {
        guard let mlModel = model as? HandPoseMLModel else { return }
        camera.currentMLModel = mlModel
    }

    func gatherObservations(pixelBuffer: CVImageBuffer) async {
        guard canPredict else { return }
        
        Task { @MainActor in
            canPredict = false
        }

        guard let mlModel = camera.currentMLModel else {
            await resetPrediction()
            return
        }
        
        Task {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try imageRequestHandler.perform([camera.handPoseRequest])
                //TODO: Add chriality here
                guard let observation = camera.handPoseRequest.results?.first else {
                    await resetPrediction()
                    return
                }

                Task { @MainActor in
                    isHandInFrame = true
                    isGatheringObservations = true
                }

                let poseMultiArray = try observation.keypointsMultiArray()
                
                let input = HandPoseInput(poses: poseMultiArray)
                guard let output = try mlModel.predict(poses: input) else { return }
                print("Predictions: \(output.labelProbabilities)")
                await updatePredictions(output: output)

                let jointPoints = try gatherHandPosePoints(from: observation)
                await updateNodes(points: jointPoints)
            } catch {
                print("Error performing request: \(error)")
            }
        }
        
    }

    private func gatherHandPosePoints(from observation: VNHumanHandPoseObservation) throws -> [CGPoint] {
        let allPointsDict = try observation.recognizedPoints(.all)
        var allPoints: [VNRecognizedPoint] = Array(allPointsDict.values)
        allPoints = allPoints.filter { $0.confidence > 0.5 }
        let points: [CGPoint] = allPoints.map { $0.location }
        return points
    }
    
    @MainActor
    private func updateNodes(points: [CGPoint]) {
        self.nodePoints = points
    }

    @MainActor
    private func updatePredictions(output: HandPoseOutput) {
        predictionLabel = output.label.capitalized
        let confidenceNum = round(output.labelProbabilities.max(by: { $0.value < $1.value })?.value ?? 0) * 100
        if isQuizMode && confidenceNum >= 80 && isHandInFrame && hasQuestionGenerated {
            hasQuestionGenerated = false
            currentQuestion = "Correct answer ✅"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.currentQuestion = self.getRandomQuestion() ?? ""
                self.hasQuestionGenerated = true
            }
        }
        confidence = "\(String(confidenceNum))%"
        predictionProbability.getNewPredictions(from: output.labelProbabilities)
    }
    
    @MainActor
    private func resetPrediction() {
        nodePoints = []
        predictionLabel = ""
        predictionProbability = PredictionMetrics()
        isHandInFrame = false
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

extension AppModel: @unchecked Sendable {}
extension Image: @unchecked Sendable {}
