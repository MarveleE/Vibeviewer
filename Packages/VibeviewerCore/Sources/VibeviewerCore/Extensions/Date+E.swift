import Foundation

public extension Date {
    /// 毫秒时间戳（字符串）
    public var millisecondsSince1970String: String {
        String(Int(self.timeIntervalSince1970 * 1000))
    }

    /// 由毫秒时间戳字符串构造 Date
    public static func fromMillisecondsString(_ msString: String) -> Date? {
        guard let ms = Double(msString) else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }
}

public extension Calendar {
    /// 给定日期所在天的起止 [start, end]
    public func dayRange(for date: Date) -> (start: Date, end: Date) {
        let startOfDay = self.startOfDay(for: date)
        let nextDay = self.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let endOfDay = Date(timeInterval: -0.001, since: nextDay)
        return (startOfDay, endOfDay)
    }

    /// 昨天 00:00 到当前时刻的区间 [yesterdayStart, now]
    public func yesterdayToNowRange(from now: Date = Date()) -> (start: Date, end: Date) {
        let startOfToday = self.startOfDay(for: now)
        let startOfYesterday = self.date(byAdding: .day, value: -1, to: startOfToday) ?? now
        return (startOfYesterday, now)
    }
}


