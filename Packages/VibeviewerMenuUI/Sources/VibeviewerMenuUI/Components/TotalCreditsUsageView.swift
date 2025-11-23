import SwiftUI
import VibeviewerModel
import VibeviewerCore
import VibeviewerShareUI

struct TotalCreditsUsageView: View {
    let snapshot: DashboardSnapshot?
    
    @State private var isModelsUsageExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if let billingCycleText {
                Text(billingCycleText)
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.secondary)
            }

            headerView
            
            if isModelsUsageExpanded, let modelsUsageSummary = snapshot?.modelsUsageSummary {
                modelsUsageDetailView(modelsUsageSummary)
            }

            Text(snapshot?.displayTotalUsageCents.dollarStringFromCents ?? "0")
                .font(.app(.satoshiBold, size: 16))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .maxFrame(true, false, alignment: .trailing)
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Total Credits Usage")
                .font(.app(.satoshiRegular, size: 12))
                .foregroundStyle(.secondary)
            
            // 如果有模型用量数据，显示展开/折叠箭头
            if snapshot?.modelsUsageSummary != nil {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isModelsUsageExpanded ? 180 : 0))
            }
        }
        .onTapGesture {
            if snapshot?.modelsUsageSummary != nil {
                isModelsUsageExpanded.toggle()
            }
        }
        .maxFrame(true, false, alignment: .trailing)
    }
    
    private func modelsUsageDetailView(_ summary: ModelsUsageSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(summary.modelsSortedByCost.prefix(5), id: \.modelName) { model in
                UsageEventView.EventItemView(event: makeAggregateEvent(from: model))
            }
        }
        
    }
    
    /// 将模型聚合数据映射为一个“虚构”的 UsageEvent，供 UsageEventView.EventItemView 复用 UI
    private func makeAggregateEvent(from model: ModelUsageInfo) -> UsageEvent {
        let tokenUsage = TokenUsage(
            outputTokens: model.outputTokens,
            inputTokens: model.inputTokens,
            totalCents: model.costCents,
            cacheWriteTokens: model.cacheWriteTokens,
            cacheReadTokens: model.cacheReadTokens
        )
        
        // occurredAtMs 使用 "0" 即可，这里不会参与分组和排序，仅用于展示
        return UsageEvent(
            occurredAtMs: "0",
            modelName: model.modelName,
            kind: "aggregate",
            requestCostCount: 0,
            usageCostDisplay: model.formattedCost,
            usageCostCents: Int(model.costCents.rounded()),
            isTokenBased: true,
            userDisplayName: "",
            cursorTokenFee: 0,
            tokenUsage: tokenUsage
        )
    }
    
    /// 当前计费周期展示文案（如 "Billing cycle: Oct 1 – Oct 31"）
    private var billingCycleText: String? {
        guard
            let startMs = snapshot?.billingCycleStartMs,
            let endMs = snapshot?.billingCycleEndMs,
            let startDate = Date.fromMillisecondsString(startMs),
            let endDate = Date.fromMillisecondsString(endMs)
        else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        
        return "\(start) – \(end)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

