import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

struct ModelsUsageBarChartView: View {
    let data: ModelsUsageChartData
    
    @State private var selectedDate: String?
    
    // 基于“模型前缀 → 基础色”的分组映射，整体采用墨绿色系的相近色
    // 这里的颜色是几种不同明度/偏色的墨绿色，方便同一前缀下做细微区分
    private let mossGreenPalette: [Color] = [
        Color(red: 0/255, green: 92/255, blue: 66/255),   // 深墨绿
        Color(red: 24/255, green: 120/255, blue: 88/255), // 偏亮墨绿
        Color(red: 16/255, green: 104/255, blue: 80/255), // 略偏蓝的墨绿
        Color(red: 40/255, green: 132/255, blue: 96/255), // 柔和一点的墨绿
        Color(red: 6/255, green: 76/255, blue: 60/255)    // 更深一点的墨绿
    ]
    
    /// 不同模型前缀对应的基础 palette 偏移量（同一前缀颜色更接近）
    private let modelPrefixOffsets: [String: Int] = [
        "gpt-": 0,
        "claude-": 1,
        "composer-": 2,
        "grok-": 3,
        "Other": 4
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
        // 确保 X 轴始终展示所有日期标签（即使某些日期没有数据）
        .chartXScale(domain: data.dataPoints.map { $0.dateLabel })
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
        // 1. 根据模型名前缀找到对应的基础偏移量
        let prefixOffset: Int = {
            for (prefix, offset) in modelPrefixOffsets {
                if modelName.hasPrefix(prefix) {
                    return offset
                }
            }
            // 没有匹配到已知前缀时，统一归为 "Other" 分组
            return modelPrefixOffsets["Other"] ?? 0
        }()
        
        // 2. 使用模型名的哈希生成一个稳定的索引，叠加前缀偏移，让同一前缀的颜色彼此相近
        let hash = abs(modelName.hashValue)
        let index = (prefixOffset + hash) % mossGreenPalette.count
        
        return mossGreenPalette[index]
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

