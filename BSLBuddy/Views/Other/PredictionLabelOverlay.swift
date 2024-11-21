import SwiftUI

struct PredictionLabelOverlay: View {
    var label: String
    var confidence: String
    
    @ScaledMetric private var size: CGFloat = 80

    var body: some View {
        if label.isEmpty {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .fill(Color.translucentBlack)
                .frame(width: size, height: size)
                .padding()
                .overlay {
                    VStack {
                        Text(label)
                        Text(confidence)
                    }
                    .foregroundColor(.white)
                }
        }
    }
}
