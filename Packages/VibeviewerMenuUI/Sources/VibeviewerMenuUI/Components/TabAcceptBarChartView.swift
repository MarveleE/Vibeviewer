import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

struct TabAcceptBarChartView: View {
    let data: TabAcceptChartData
    
    @State private var selectedDate: String?
    
    var body: some View {
        if data.dataPoints.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                chartView
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
                    BarMark(
                        x: .value("Date", item.dateLabel),
                        y: .value("Accepted", item.acceptedCount)
                    )
                    .foregroundStyle(barColor(for: item.dateLabel))
                    .cornerRadius(4)
                    .opacity(shouldDimBar(for: item.dateLabel) ? 0.4 : 1.0)
                }
                
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected", selectedDate))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                        .foregroundStyle(Color.green.opacity(0.3))
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
    
    private func barColor(for dateLabel: String) -> AnyShapeStyle {
        if selectedDate == dateLabel {
            return AnyShapeStyle(Color.green.opacity(0.9))
        } else {
            return AnyShapeStyle(Color.green.gradient)
        }
    }
    
    private func shouldDimBar(for dateLabel: String) -> Bool {
        guard selectedDate != nil else { return false }
        return selectedDate != dateLabel
    }
    
    private func tooltipView(for item: TabAcceptChartData.DataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.dateLabel)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            Text("\(item.acceptedCount) tabs")
                .font(.app(.satoshiBold, size: 13))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
        let values = data.dataPoints.map { $0.acceptedCount }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }
    
    private var averageValue: Double? {
        guard let total = totalValue, !data.dataPoints.isEmpty else { return nil }
        return Double(total) / Double(data.dataPoints.count)
    }
    
    private var maxValue: Int? {
        data.dataPoints.map { $0.acceptedCount }.max()
    }
}

