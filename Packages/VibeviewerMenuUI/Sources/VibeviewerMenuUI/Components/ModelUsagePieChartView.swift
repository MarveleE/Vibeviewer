import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

struct ModelUsagePieChartView: View {
    let data: ModelUsageChartData
    
    @State private var selectedModel: String?
    
    var body: some View {
        if data.modelDistribution.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                chartView
                legendView
            }
        }
    }
    
    private var emptyView: some View {
        Text("暂无数据")
            .font(.app(.satoshiRegular, size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(data.modelDistribution) { model in
                SectorMark(
                    angle: .value("Count", model.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Model", model.modelName))
                .opacity(selectedModel == nil || selectedModel == model.id ? 1.0 : 0.4)
            }
        }
        .chartAngleSelection(value: $selectedModel)
        .frame(height: 200)
        .animation(.easeInOut(duration: 0.2), value: selectedModel)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data.modelDistribution.prefix(5)) { model in
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForModel(model.modelName))
                        .frame(width: 8, height: 8)
                    
                    Text(model.modelName)
                        .font(.app(.satoshiRegular, size: 11))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(model.count)")
                        .font(.app(.satoshiMedium, size: 11))
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.1f%%", model.percentage))
                        .font(.app(.satoshiBold, size: 11))
                        .foregroundStyle(.primary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            
            if data.modelDistribution.count > 5 {
                Text("+ \(data.modelDistribution.count - 5) more models")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    private func colorForModel(_ modelName: String) -> Color {
        // 简单的颜色映射策略
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .indigo, .mint]
        let index = abs(modelName.hashValue) % colors.count
        return colors[index]
    }
}

