//
//  ContentView.swift
//  BSLBuddy
//
//  Created by Guest 2 on 16/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var appModel: AppModel = AppModel()
    @State var predictedMove: String = BSLAlphabetsNumbers.unknown.rawValue
    
    @State private var isPresentingTrainingView: Bool = false
    @State private var isPresentingDebugView: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                CameraView()
                    .environmentObject(appModel)
                    .onChange(of: appModel.predictionLabel) { _, _ in
                        updatePredictions(with: appModel.predictionLabel)

                    }
                    .overlay(alignment: .bottom) {
                        if !appModel.isQuizMode {
                            VStack {
                                PredictionLabelOverlay(label: appModel.predictionLabel, confidence: appModel.confidence)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                    .overlay(alignment: .top) {
                        if appModel.isQuizMode {
                            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                                .fill(Color.translucentBlack)
                                .frame(maxWidth: .infinity, maxHeight: 40)
                                .padding()
                                .overlay {
                                    Text(appModel.currentQuestion)
                                        .font(.system(.callout, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                HStack {
                    Button(appModel.isQuizMode ? "Go to practice mode" : "Go to quiz mode") {
                        appModel.isQuizMode.toggle()
                        appModel.currentQuestion = appModel.getRandomQuestion() ?? ""
                        appModel.hasQuestionGenerated = true
                    }
#if os(macOS)
                    Button("Train Model", systemImage: "chevron.forward") {
                        isPresentingTrainingView.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
#endif
                    Button("Debug View", systemImage: "chevron.forward") {
                        isPresentingDebugView.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .task {
                await appModel.useLastTrainedModel()
            }
            .navigationDestination(isPresented: $isPresentingTrainingView) {
                DatasetView()
                    .environmentObject(appModel)
            }
            .navigationDestination(isPresented: $isPresentingDebugView) {
                DebugModeView()
                    .environmentObject(appModel)
            }
        }
    }
}

extension ContentView {
    func updatePredictions(with predictionLabel: String) {
        predictedMove = predictionLabel
    }
}

#Preview {
    ContentView()
}
