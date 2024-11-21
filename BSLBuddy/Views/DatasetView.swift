//
//  DatasetView.swift
//  BSLBuddy
//
//  Created by Guest 2 on 17/11/2024.
//


import SwiftUI

struct DatasetView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var trainerDataModel = TrainerDataModel()

    @State private var localDatasets: [Dataset] = []
    @State private var newDatasets: [Dataset] = []
    @State private var datasetName: String = ""
    @FocusState private var focusField: Bool

    private var allDatasetNames: [String] {
        localDatasets.map { $0.name } + newDatasets.map { $0.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(localDatasets) { dataset in
                        datasetCell(dataset)
                    }
                    ForEach(newDatasets) { dataset in
                        datasetCell(dataset)
                    }
                }
                .padding()
            }
            .toolbar {
                addDatasetToolbarItem()
            }
            .navigationTitle("Training Datasets")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .accentColor(.accentColor)
        .onAppear {
            localDatasets = getLocalDatasets()
        }
    }

    private func datasetCell(_ dataset: Dataset) -> some View {
        TrainingDatasetCell(trainerDataModel: trainerDataModel, dataset: dataset)
            .environmentObject(appModel)
    }

    private func addDatasetToolbarItem() -> some ToolbarContent {
        #if os(macOS)
        ToolbarItem(placement: .confirmationAction) {
            NavigationLink {
                TrainingView(trainerDataModel: trainerDataModel, newDatasets: $newDatasets)
                    .environmentObject(appModel)
                    .onAppear {
                        let newDataset = Dataset(type: .training, moves: trainerDataModel.moves, isNew: true)
                        trainerDataModel.currentTrainingDataset = newDataset
                    }
            } label: {
                Label("Create a new dataset", systemImage: "plus")
                    .labelStyle(.iconOnly)

            }
        }
        #else
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                TrainingView(trainerDataModel: trainerDataModel, newDatasets: $newDatasets)
                    .environmentObject(appModel)
                    .onAppear {
                        let newDataset = Dataset(type: .training, moves: trainerDataModel.moves, isNew: true)
                        trainerDataModel.currentTrainingDataset = newDataset
                    }
            } label: {
                Label("Create a new dataset", systemImage: "plus")
                    .labelStyle(.iconOnly)

            }
        }
        #endif
    }
    
    private func getLocalDatasets() -> [Dataset] {
        return trainerDataModel.localTrainingDatasets
    }
}

struct DatasetView_Previews: PreviewProvider {
    static var previews: some View {
        DatasetView()
            .environmentObject(AppModel())
    }
}
