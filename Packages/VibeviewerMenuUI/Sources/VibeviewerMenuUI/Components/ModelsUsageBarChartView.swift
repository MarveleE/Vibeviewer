import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

struct ModelsUsageBarChartView: View {
    let data: ModelsUsageChartData
    
    @State private var selectedDate: String?
    
    // 模型名称到颜色的映射（基于 Cursor Dashboard 的颜色方案）
    private let modelColorMap: [String: Color] = [
        "gpt-5": Color(red: 0/255, green: 92/255, blue: 66/255),
        "claude-4.5-sonnet": Color(red: 31/255, green: 138/255, blue: 101/255),
        "composer-1": Color(red: 150/255, green: 194/255, blue: 172/255),
        "gpt-5-high": Color(red: 60/255, green: 124/255, blue: 171/255),
        "claude-4.5-haiku": Color(red: 5/255, green: 81/255, blue: 128/255),
        "grok-code-fast-1": Color(red: 219/255, green: 112/255, blue: 75/255),
        "claude-4.5-sonnet-thinking": Color(red: 163/255, green: 57/255, blue: 0/255),
        "claude-4-sonnet": Color(red: 252/255, green: 212/255, blue: 199/255),
        "Other": Color(red: 208/255, green: 107/255, blue: 166/255)
    ]
    
    // 默认颜色数组，用于未映射的模型
    private let defaultColors: [Color] = [
        .blue, .orange, .green, .purple, .pink, .cyan, .indigo, .mint
    ]
    
    var body: some View {
        if data.dataPoints.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                chartView
                legendView
                summaryView
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
            ForEach(data.dataPoints, id: \.date) { item in
                let stackedData = calculateStackedData(for: item)
                
                ForEach(Array(stackedData.enumerated()), id: \.offset) { index, stackedItem in
                    BarMark(
                        x: .value("Date", item.dateLabel),
                        yStart: .value("Start", stackedItem.start),
                        yEnd: .value("End", stackedItem.end)
                    )
                    .foregroundStyle(barColor(for: stackedItem.modelName, dateLabel: item.dateLabel))
                    .cornerRadius(4)
                    .opacity(shouldDimBar(for: item.dateLabel) ? 0.4 : 1.0)
                }
            }
            
            if let selectedDate = selectedDate,
               let selectedItem = data.dataPoints.first(where: { $0.dateLabel == selectedDate }) {
                RuleMark(x: .value("Selected", selectedDate))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .annotation(
                        position: annotationPosition(for: selectedDate),
                        alignment: .center,
                        spacing: 8,
                        overflowResolution: AnnotationOverflowResolution(x: .disabled, y: .disabled)
                    ) {
                        annotationView(for: selectedItem)
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.app(.satoshiRegular, size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.2))
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.app(.satoshiRegular, size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 180)
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
    }
    
    private func barColor(for modelName: String, dateLabel: String) -> AnyShapeStyle {
        let color = colorForModel(modelName)
        if selectedDate == dateLabel {
            return AnyShapeStyle(color.opacity(0.9))
        } else {
            return AnyShapeStyle(color.gradient)
        }
    }
    
    private func colorForModel(_ modelName: String) -> Color {
        // 优先使用预定义的模型颜色映射
        if let color = modelColorMap[modelName] {
            return color
        }
        
        // 如果没有映射，使用哈希值从默认颜色数组中选择，确保相同模型总是使用相同颜色
        let hash = abs(modelName.hashValue)
        let colorIndex = hash % defaultColors.count
        return defaultColors[colorIndex]
    }
    
    private func shouldDimBar(for dateLabel: String) -> Bool {
        guard selectedDate != nil else { return false }
        return selectedDate != dateLabel
    }
    
    /// 根据选中项的位置动态计算 annotation 位置
    /// 左侧使用 topTrailing，右侧使用 topLeading，中间使用 top
    private func annotationPosition(for dateLabel: String) -> AnnotationPosition {
        guard let selectedIndex = data.dataPoints.firstIndex(where: { $0.dateLabel == dateLabel }) else {
            return .top
        }
        
        let totalCount = data.dataPoints.count
        let middleIndex = totalCount / 2
        
        if selectedIndex < middleIndex {
            // 左侧：使用 topTrailing，annotation 显示在右侧
            return .topTrailing
        } else if selectedIndex > middleIndex {
            // 右侧：使用 topLeading，annotation 显示在左侧
            return .topLeading
        } else {
            // 中间：使用 top
            return .top
        }
    }
    
    /// 计算堆叠数据：为每个模型计算起始和结束位置
    private func calculateStackedData(for item: ModelsUsageChartData.DataPoint) -> [(modelName: String, start: Int, end: Int)] {
        var cumulativeY: Int = 0
        var result: [(modelName: String, start: Int, end: Int)] = []
        
        for modelUsage in item.modelUsages {
            if modelUsage.requests > 0 {
                result.append((
                    modelName: modelUsage.modelName,
                    start: cumulativeY,
                    end: cumulativeY + modelUsage.requests
                ))
                cumulativeY += modelUsage.requests
            }
        }
        
        return result
    }
    
    private var legendView: some View {
        // 获取所有唯一的模型名称
        let uniqueModels = Set(data.dataPoints.flatMap { $0.modelUsages.map { $0.modelName } })
            .sorted()
        
        // 限制显示的模型数量（最多显示前8个）
        let displayedModels = Array(uniqueModels.prefix(8))
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(displayedModels, id: \.self) { modelName in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForModel(modelName).gradient)
                            .frame(width: 12, height: 12)
                        Text(modelName)
                            .font(.app(.satoshiRegular, size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if uniqueModels.count > 8 {
                    Text("+\(uniqueModels.count - 8) more")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func annotationView(for item: ModelsUsageChartData.DataPoint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.dateLabel)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 3) {
                ForEach(item.modelUsages.prefix(5), id: \.modelName) { modelUsage in
                    if modelUsage.requests > 0 {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForModel(modelUsage.modelName))
                                .frame(width: 6, height: 6)
                            Text("\(modelUsage.modelName): \(modelUsage.requests)")
                                .font(.app(.satoshiRegular, size: 11))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                if item.modelUsages.count > 5 {
                    Text("... and \(item.modelUsages.count - 5) more")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 12)
                }
                
                if item.modelUsages.count > 1 {
                    Divider()
                        .padding(.vertical, 2)
                    
                    Text("Total: \(item.totalValue)")
                        .font(.app(.satoshiBold, size: 13))
                        .foregroundStyle(.primary)
                } else if let firstModel = item.modelUsages.first {
                    Text("\(firstModel.requests) requests")
                        .font(.app(.satoshiBold, size: 13))
                        .foregroundStyle(.primary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .fixedSize(horizontal: true, vertical: false)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var summaryView: some View {
        HStack(spacing: 16) {
            if let total = totalValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(total)")
                        .font(.app(.satoshiBold, size: 14))
                        .foregroundStyle(.primary)
                }
            }
            
            if let avg = averageValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", avg))
                        .font(.app(.satoshiBold, size: 14))
                        .foregroundStyle(.primary)
                }
            }
            
            if let max = maxValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Peak")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(max)")
                        .font(.app(.satoshiBold, size: 14))
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    private var totalValue: Int? {
        guard !data.dataPoints.isEmpty else { return nil }
        return data.dataPoints.reduce(0) { $0 + $1.totalValue }
    }
    
    private var averageValue: Double? {
        guard let total = totalValue, !data.dataPoints.isEmpty else { return nil }
        return Double(total) / Double(data.dataPoints.count)
    }
    
    private var maxValue: Int? {
        data.dataPoints.map { $0.totalValue }.max()
    }
}

