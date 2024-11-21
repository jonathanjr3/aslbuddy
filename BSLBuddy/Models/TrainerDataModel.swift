//
//  TrainerDataModel.swift
//  BSLBuddy
//
//  Created by Guest 2 on 16/11/2024.
//


import SwiftUI
import CoreML
#if canImport(CreateML)
import CreateML
#endif

final class TrainerDataModel: ObservableObject {
    enum State: String {
        case inactive
        case active
        case finished
        case error
    }

    var trainingMetrics = TrainingMetrics()

    @Published var modelName: String?
    @Published var currentTrainer: HandPoseTrainer?
    @Published var currentTrainingDataset: Dataset?
    @Published var currentValidationDataset: Dataset?
    @Published var completed: Double = 0.0
    @Published var currentPhase: String = ""
    @Published var currentState: State = .inactive

    var disableTrainingButton: Bool {
        guard let modelName = modelName, !modelName.isEmpty, let trainingDataset = currentTrainingDataset else { return true }
        return !trainingDataset.hasEnoughImages
    }
    
    var localTrainingDatasets: [Dataset] {
        guard let trainingDirectory = URL.trainingDirectoryInResources else { return [] }
        var datasets: [Dataset] = []
        for localURL in trainingDirectory.directoryContents {
            let folderName = localURL.lastPathComponent
            let dataset = Dataset(name: folderName,
                    type: .training,
                    moves: moves,
                    resourceDirectory: localURL)
            datasets.append(dataset)
        }
        return datasets
    }
    
    var localValidationDatasets: [Dataset] {
        guard let trainingDirectory = URL.validationDirectoryInResources else { return [] }
        var datasets: [Dataset] = []
        for localURL in trainingDirectory.directoryContents {
            let folderName = localURL.lastPathComponent
            let dataset = Dataset(name: folderName,
                    type: .validation,
                    moves: moves,
                    resourceDirectory: localURL)
            datasets.append(dataset)
        }
        return datasets
    }

    var localValidationDatasetNames: [String] {
        localValidationDatasets.map { $0.name }
    }

    var moves: [String] {
        BSLAlphabetsNumbers.allCases.map(\.rawValue)
    }

    func reset() {
        trainingMetrics = TrainingMetrics()
#if os(macOS)
        currentTrainer?.cancel()
#endif
        currentTrainer = nil
        currentTrainingDataset = nil
        currentValidationDataset = nil
        completed = 0.0
        currentPhase = ""
        currentState = .inactive
    }
}

extension TrainerDataModel: @unchecked Sendable {}
