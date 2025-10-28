import SwiftUI
import VibeviewerModel
import VibeviewerCore
import Charts

struct AgentLineChangesChartView: View {
    let data: AgentLineChangesChartData
    
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
                // 建议的行数线
                ForEach(data.dataPoints, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.dateLabel),
                        y: .value("Lines", item.suggestedLines),
                        series: .value("Type", "Suggested")
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)
                    .symbolSize(40)
                }
                
                // 接受的行数线
                ForEach(data.dataPoints, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.dateLabel),
                        y: .value("Lines", item.acceptedLines),
                        series: .value("Type", "Accepted")
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)
                    .symbolSize(40)
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
            .chartLegend(position: .top, alignment: .leading) {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("Suggested")
                            .font(.app(.satoshiRegular, size: 10))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Accepted")
                            .font(.app(.satoshiRegular, size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 200)
            .animation(.easeInOut(duration: 0.2), value: selectedDate)
            
            if let selectedDate = selectedDate,
               let selectedItem = data.dataPoints.first(where: { $0.dateLabel == selectedDate }) {
                tooltipView(for: selectedItem)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .padding(.top, 24)
            }
        }
    }
    
    private func tooltipView(for item: AgentLineChangesChartData.DataPoint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.dateLabel)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(.blue)
                    .frame(width: 6, height: 6)
                Text("Suggested: \(item.suggestedLines)")
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.primary)
            }
            
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Accepted: \(item.acceptedLines)")
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 10)
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Suggested")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
                Text("\(totalSuggested)")
                    .font(.app(.satoshiBold, size: 14))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Accepted")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
                Text("\(totalAccepted)")
                    .font(.app(.satoshiBold, size: 14))
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Acceptance Rate")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f%%", acceptanceRate))
                    .font(.app(.satoshiBold, size: 14))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.top, 8)
    }
    
    private var totalSuggested: Int {
        data.dataPoints.map { $0.suggestedLines }.reduce(0, +)
    }
    
    private var totalAccepted: Int {
        data.dataPoints.map { $0.acceptedLines }.reduce(0, +)
    }
    
    private var acceptanceRate: Double {
        guard totalSuggested > 0 else { return 0.0 }
        return (Double(totalAccepted) / Double(totalSuggested)) * 100.0
    }
}

