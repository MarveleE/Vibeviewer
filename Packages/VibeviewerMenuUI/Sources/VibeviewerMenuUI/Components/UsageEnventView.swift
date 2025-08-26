import SwiftUI
import VibeviewerModel
import VibeviewerShareUI
import VibeviewerCore

struct UsageEventView: View {
    var events: [UsageEvent]
    
    @State var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: isHovered ? 6 : -16) {
            ForEach(Array(events.prefix(3).enumerated()), id: \.element.occurredAtMs) { index, event in
                EventItemView(event: event, isHovered: isHovered)
                    .scaleEffect(isHovered ? 1.0 : (1 - (Double(index) * 0.05)))
                    .blur(radius: isHovered ? 0 : Double(index) * 2)
                    .opacity(1 - (Double(index) * 0.2))
                    .zIndex(-Double(index))
            }
        }
        .contentShape(.rect)
        .onTapGesture { 
            withAnimation(.spring(duration: 0.35)) {
                isHovered.toggle()
            }
        }
    }

    struct EventItemView: View {
        let event: UsageEvent
        let isHovered: Bool

        var body: some View {
            HStack(spacing: 8) {
                event.brand.logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)

                Text(DateUtils.timeString(fromMillisecondsString: event.occurredAtMs, format: .hms))
                    .font(.app(.satoshiRegular, size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(event.usageCostDisplay)")
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .overlay {
                Text(event.modelName)
                    .font(.app(.satoshiMedium, size: 12))
                    .foregroundStyle(.primary)
            }
            .background {
                ZStack {
                    if isHovered {
                        Color.white.opacity(0.1)
                    } else {
                        Rectangle().fill(.thinMaterial)
                    }
                }
            }
            .cornerRadiusWithCorners(8)
            .overlayBorder(color: .black.opacity(0.1), lineWidth: 1, cornerRadius: 8)
        }
    }
}