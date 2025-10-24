import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

@MainActor
public struct UserAnalyticsChartView: View {
    let analytics: UserAnalytics
    
    @State private var selectedDate: String?
    
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
        Text("订阅包含请求数趋势")
            .font(.app(.satoshiBold, size: 14))
            .foregroundStyle(.primary)
    }
    
    private var chartView: some View {
        Chart {
            ForEach(chartData, id: \.date) { item in
                BarMark(
                    x: .value("日期", item.dateLabel),
                    y: .value("请求数", item.value)
                )
                .foregroundStyle(barColor(for: item.dateLabel))
                .cornerRadius(4)
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
        .overlay(alignment: .top) {
            if let selectedDate = selectedDate,
               let selectedItem = chartData.first(where: { $0.dateLabel == selectedDate }) {
                tooltipView(for: selectedItem)
                    .offset(y: -10)
            }
        }
    }
    
    private func barColor(for dateLabel: String) -> AnyShapeStyle {
        if selectedDate == dateLabel {
            return AnyShapeStyle(Color.blue.opacity(0.8))
        } else {
            return AnyShapeStyle(Color.blue.gradient)
        }
    }
    
    private func tooltipView(for item: ChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.dateLabel)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            Text("\(item.value) 次请求")
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
                    Text("总计")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                    Text("\(total)")
                        .font(.app(.satoshiBold, size: 14))
                        .foregroundStyle(.primary)
                }
            }
            
            if let avg = averageValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text("日均")
                        .font(.app(.satoshiRegular, size: 10))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", avg))
                        .font(.app(.satoshiBold, size: 14))
                        .foregroundStyle(.primary)
                }
            }
            
            if let max = maxValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text("峰值")
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

