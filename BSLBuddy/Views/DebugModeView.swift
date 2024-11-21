//
//  DebugModeView.swift
//  BSLBuddy
//
//  Created by Guest 2 on 17/11/2024.
//


import SwiftUI
import Charts

struct DebugModeView: View {
    @EnvironmentObject var appModel: AppModel
#if os(iOS)
    @State private var orientation = UIDeviceOrientation.unknown
#endif
    
    private var livePredictionData: [PredictionMetric] {
        return appModel.predictionProbability.data
    }
    
    var body: some View {
        NavigationStack {
#if os(iOS)
            if orientation.isLandscape || orientation.isFlat {
                HStack(spacing: 0) {
                    CameraView(showNodes: true)
                        .environmentObject(appModel)
                        .overlay(alignment: .bottomTrailing) {
                            PredictionLabelOverlay(label: appModel.predictionLabel, confidence: appModel.confidence)
                        }
                    predictionBarChart()
                }
                .toolbar {
                    availableMLModelsToolbarItem()
                }
                .task {
                    await appModel.findExistingModels()
                }
            } else {
                VStack(alignment: .center, spacing: 0) {
                    CameraView(showNodes: true)
                        .environmentObject(appModel)
                        .overlay(alignment: .bottomTrailing) {
                            PredictionLabelOverlay(label: appModel.predictionLabel, confidence: appModel.confidence)
                        }
                    predictionBarChart()
                }
                .task {
                    await appModel.findExistingModels()
                }
                .toolbar {
                    availableMLModelsToolbarItem()
                }
            }
#else
            VStack(alignment: .center, spacing: 0) {
                CameraView(showNodes: true)
                    .environmentObject(appModel)
                    .overlay(alignment: .bottomTrailing) {
                        PredictionLabelOverlay(label: appModel.predictionLabel, confidence: appModel.confidence)
                    }
                predictionBarChart()
            }
            .task {
                await appModel.findExistingModels()
            }
            .toolbar {
                availableMLModelsToolbarItem()
            }
#endif
        }
        .accentColor(.accentColor)
    }
    
    @ViewBuilder
    private func predictionBarChart() -> some View {
#if os(iOS)
        if (orientation.isLandscape || orientation.isFlat) {
            ScrollView(.vertical) {
                VStack {
                    Chart(livePredictionData, id: \.category) {
                        BarMark(xStart: .value("zero", 0.0),
                                xEnd: .value("Probability", $0.value),
                                y: .value("Category", $0.category))
                    }
                    .chartXScale(domain: 0...1)
                    .chartXAxisLabel("Confidence")
                    .chartXAxis(.visible)
                    .chartYAxis(.visible)
                    .animation(.easeIn, value: livePredictionData)
                    .foregroundColor(.accentColor)
                }
                .modifier(ChartViewStyle())
            }
        } else {
            ScrollView(.horizontal) {
                HStack {
                    Chart(livePredictionData, id: \.category) {
                        BarMark(x: .value("Category", $0.category),
                                yStart: .value("zero", 0.0),
                                yEnd: .value("Probability", $0.value))
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxisLabel("Confidence")
                    .chartXAxis(.visible)
                    .chartYAxis(.visible)
                    .animation(.easeIn, value: livePredictionData)
                    .foregroundColor(.accentColor)
                }
                .modifier(ChartViewStyle())
            }
        }
#else
        ScrollView(.horizontal) {
            HStack {
                Chart(livePredictionData, id: \.category) {
                    BarMark(x: .value("Category", $0.category),
                            yStart: .value("zero", 0.0),
                            yEnd: .value("Probability", $0.value))
                }
                .chartYScale(domain: 0...1)
                .chartYAxisLabel("Confidence")
                .chartXAxis(.visible)
                .chartYAxis(.visible)
                .animation(.easeIn, value: livePredictionData)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
            }
            .modifier(ChartViewStyle())
        }
#endif
    }
    
    private func availableMLModelsToolbarItem() -> some ToolbarContent {
#if os(macOS)
        ToolbarItem(placement: .confirmationAction) {
            NavigationLink {
                MLModelListView()
                    .environmentObject(appModel)
            } label: {
                Text("ML Models")
            }
        }
#else
        ToolbarItem(placement: .confirmationAction) {
            NavigationLink {
                MLModelListView()
                    .environmentObject(appModel)
            } label: {
                Text("ML Models")
            }
        }
#endif
    }
}

struct DebugModeView_Previews: PreviewProvider {
    static var previews: some View {
        DebugModeView()
            .environmentObject(AppModel())
    }
}
