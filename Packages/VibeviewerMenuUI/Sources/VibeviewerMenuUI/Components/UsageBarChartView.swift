import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

struct UsageBarChartView: View {
    let data: UsageChartData
    
    @State private var selectedDate: String?
    
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
        ZStack(alignment: .top) {
            Chart {
                ForEach(data.dataPoints, id: \.date) { item in
                    // 订阅包含的请求（蓝色，底部）
                    if item.subscriptionReqs > 0 {
                        BarMark(
                            x: .value("Date", item.dateLabel),
                            y: .value("Subscription", item.subscriptionReqs)
                        )
                        .foregroundStyle(subscriptionBarColor(for: item.dateLabel))
                        .cornerRadius(4)
                        .opacity(shouldDimBar(for: item.dateLabel) ? 0.4 : 1.0)
                    }
                    
                    // 基于使用量的请求（橙色，堆叠在上面）
                    if item.usageBasedReqs > 0 {
                        BarMark(
                            x: .value("Date", item.dateLabel),
                            y: .value("Usage Based", item.usageBasedReqs)
                        )
                        .foregroundStyle(usageBasedBarColor(for: item.dateLabel))
                        .cornerRadius(4)
                        .opacity(shouldDimBar(for: item.dateLabel) ? 0.4 : 1.0)
                    }
                }
                
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected", selectedDate))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.3))
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
            
            if let selectedDate = selectedDate,
               let selectedItem = data.dataPoints.first(where: { $0.dateLabel == selectedDate }) {
                tooltipView(for: selectedItem)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .padding(.top, 8)
            }
        }
    }
    
    private func subscriptionBarColor(for dateLabel: String) -> AnyShapeStyle {
        if selectedDate == dateLabel {
            return AnyShapeStyle(Color.blue.opacity(0.9))
        } else {
            return AnyShapeStyle(Color.blue.gradient)
        }
    }
    
    private func usageBasedBarColor(for dateLabel: String) -> AnyShapeStyle {
        if selectedDate == dateLabel {
            return AnyShapeStyle(Color.orange.opacity(0.9))
        } else {
            return AnyShapeStyle(Color.orange.gradient)
        }
    }
    
    private func shouldDimBar(for dateLabel: String) -> Bool {
        guard selectedDate != nil else { return false }
        return selectedDate != dateLabel
    }
    
    private var legendView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.gradient)
                    .frame(width: 12, height: 12)
                Text("Subscription")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange.gradient)
                    .frame(width: 12, height: 12)
                Text("Usage Based")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func tooltipView(for item: UsageChartData.DataPoint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.dateLabel)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 3) {
                if item.subscriptionReqs > 0 {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text("Subscription: \(item.subscriptionReqs)")
                            .font(.app(.satoshiRegular, size: 11))
                            .foregroundStyle(.primary)
                    }
                }
                
                if item.usageBasedReqs > 0 {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("Usage Based: \(item.usageBasedReqs)")
                            .font(.app(.satoshiRegular, size: 11))
                            .foregroundStyle(.primary)
                    }
                }
                
                // 只在有多个数据源时显示分隔线和总计
                if item.subscriptionReqs > 0 && item.usageBasedReqs > 0 {
                    Divider()
                        .padding(.vertical, 2)
                    
                    Text("Total: \(item.totalValue)")
                        .font(.app(.satoshiBold, size: 13))
                        .foregroundStyle(.primary)
                } else {
                    // 只有一个数据源时，直接显示该值
                    Text("\(item.totalValue) requests")
                        .font(.app(.satoshiBold, size: 13))
                        .foregroundStyle(.primary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

