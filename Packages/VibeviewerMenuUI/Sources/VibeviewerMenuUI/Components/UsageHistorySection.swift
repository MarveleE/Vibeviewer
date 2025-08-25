import SwiftUI
import VibeviewerModel

@MainActor
struct UsageHistorySection: View {
    let isLoading: Bool
    @Bindable var settings: AppSettings
    let events: [UsageEvent]
    let onReload: () -> Void
    let onToday: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack {
                DatePicker("选择日期", selection: $settings.usageHistory.dateRange.start, displayedComponents: .date)
                Spacer()
                Stepper("条数: \(settings.usageHistory.limit)", value: $settings.usageHistory.limit, in: 1...100)
                    .frame(minWidth: 120)
            }
            .font(.callout)

            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("加载用量历史") { onReload() }
                }
                Button("今天") { onToday() }
            }

            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(events.prefix(settings.usageHistory.limit).enumerated()), id: \.offset) { _, e in
                        HStack(alignment: .top, spacing: 8) {
                            Text(formatTimestamp(e.occurredAtMs))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 120, alignment: .leading)
                            Text(e.modelName)
                                .font(.callout)
                                .frame(minWidth: 90, alignment: .leading)
                            Spacer(minLength: 6)
                            Text("req: \(e.requestCostCount)")
                                .font(.caption)
                            Text(e.usageCostDisplay)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 4)
            } else {
                Text("暂无用量历史").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func formatTimestamp(_ msString: String) -> String {
        guard let ms = Double(msString) else { return msString }
        let date = Date(timeIntervalSince1970: ms / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}


