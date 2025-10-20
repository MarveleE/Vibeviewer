import SwiftUI

struct RequestsCompareView: View {
    let requestToday: Int
    let requestYestoday: Int

    init(requestToday: Int, requestYestoday: Int) {
        self.requestToday = requestToday
        self.requestYestoday = requestYestoday
    }

    var body: some View {
        HStack(alignment: .center) {
            compareView(title: "Today", value: requestToday, isToday: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("vs")
                .font(.app(.satoshiBold, size: 12))
                .foregroundStyle(.primary)
            compareView(title: "Yesterday", value: requestYestoday, isToday: false)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func compareView(title: String, value: Int, isToday: Bool) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(value)")
                .font(.app(.satoshiRegular, size: 68))
                .foregroundStyle(isToday ? Color(hex: "B09E56") : .secondary)
                .contentTransition(.numericText())
            Text(title)
                .font(.app(.satoshiBold, size: 12))
                .foregroundStyle(.primary)
        }
    }
}