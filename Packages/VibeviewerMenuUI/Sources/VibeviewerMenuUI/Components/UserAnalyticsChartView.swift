import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

@MainActor
public struct UserAnalyticsChartView: View {
    let analytics: UserAnalytics
    
    @State private var selectedDate: String?
    @State private var hoveredDate: String?
    
    public init(analytics: UserAnalytics) {
        self.analytics = analytics
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            titleView
            
            // 柱状图
            if !chartData.isEmpty {
                chartView
                
                summaryView
            } else {
                Text("暂无数据")
                    .font(.app(.satoshiRegular, size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Subviews
    
    private var titleView: some View {
        Text("Usage")
            .font(.app(.satoshiBold, size: 14))
            .foregroundStyle(.primary)
    }
    
    private var chartView: some View {
        ZStack(alignment: .top) {
            Chart {
                ForEach(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.dateLabel),
                        y: .value("Requests", item.value)
                    )
                    .foregroundStyle(barColor(for: item.dateLabel))
                    .cornerRadius(4)
                    .opacity(shouldDimBar(for: item.dateLabel) ? 0.4 : 1.0)
                }
                
                // 使用 RuleMark 显示选中列的竖线标记
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected", selectedDate))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                        .foregroundStyle(Color.blue.opacity(0.3))
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
            
            // Tooltip 悬浮显示，不使用 overlay
            if let selectedDate = selectedDate,
               let selectedItem = chartData.first(where: { $0.dateLabel == selectedDate }) {
                tooltipView(for: selectedItem)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .padding(.top, 8)
            }
        }
    }
    
    private func barColor(for dateLabel: String) -> AnyShapeStyle {
        let isSelected = selectedDate == dateLabel
        let isHovered = hoveredDate == dateLabel
        
        switch (isSelected, isHovered) {
        case (true, _):
            // 选中状态：深蓝色且更醒目
            return AnyShapeStyle(Color.blue.opacity(0.9))
        case (false, true):
            // 悬停状态：中等蓝色
            return AnyShapeStyle(Color.blue.opacity(0.65))
        default:
            // 默认状态：使用渐变色
            return AnyShapeStyle(Color.blue.gradient)
        }
    }
    
    private func shouldDimBar(for dateLabel: String) -> Bool {
        // 如果有选中项，且当前项未被选中，则变暗
        guard selectedDate != nil else { return false }
        return selectedDate != dateLabel
    }
    
    private func tooltipView(for item: ChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.dateLabel)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            Text("\(item.value) requests")
                .font(.app(.satoshiBold, size: 13))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
    
    // MARK: - Computed Properties
    
    private var chartData: [ChartDataPoint] {
        analytics.dailyMetrics.compactMap { metric in
            guard let value = metric.subscriptionIncludedReqs,
                  value > 0 else { return nil }
            
            let dateLabel = formatDateLabel(metric.date)
            return ChartDataPoint(date: metric.date, dateLabel: dateLabel, value: value)
        }
    }
    
    private var totalValue: Int? {
        let values = chartData.map { $0.value }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }
    
    private var averageValue: Double? {
        guard let total = totalValue, !chartData.isEmpty else { return nil }
        return Double(total) / Double(chartData.count)
    }
    
    private var maxValue: Int? {
        chartData.map { $0.value }.max()
    }
    
    private func formatDateLabel(_ dateString: String) -> String {
        guard let date = DateUtils.date(fromMillisecondsString: dateString) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

private struct ChartDataPoint {
    let date: String
    let dateLabel: String
    let value: Int
}

