import Foundation

public enum DateUtils {
    public enum TimeFormat {
        case hm        // HH:mm
        case hms       // HH:mm:ss

        fileprivate var dateFormat: String {
            switch self {
            case .hm: return "HH:mm"
            case .hms: return "HH:mm:ss"
            }
        }
    }

    /// 给定日期所在天的起止 [start, end]
    public static func dayRange(for date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let endOfDay = Date(timeInterval: -0.001, since: nextDay)
        return (startOfDay, endOfDay)
    }

    /// 昨天 00:00 到当前时刻的区间 [yesterdayStart, now]
    public static func yesterdayToNowRange(from now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? now
        return (startOfYesterday, now)
    }
    
    /// 7 天前的 00:00 到明天 00:00 的区间 [sevenDaysAgoStart, tomorrowStart]
    public static func sevenDaysAgoToNowRange(from now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        let startOfSevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? now
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        return (startOfSevenDaysAgo, startOfTomorrow)
    }

    /// 指定天数前的 00:00 到明天 00:00 的区间 [nDaysAgoStart, tomorrowStart]
    public static func daysAgoToNowRange(days: Int, from now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        let startOfNDaysAgo = calendar.date(byAdding: .day, value: -days, to: startOfToday) ?? now
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        return (startOfNDaysAgo, startOfTomorrow)
    }

    /// 将 Date 转为毫秒字符串
    public static func millisecondsString(from date: Date) -> String {
        String(Int(date.timeIntervalSince1970 * 1000))
    }

    /// 由毫秒字符串转 Date
    public static func date(fromMillisecondsString msString: String) -> Date? {
        guard let ms = Double(msString) else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }

    /// 将 Date 按指定格式转为时间字符串（默认 HH:mm:ss）
    public static func timeString(from date: Date,
                                  format: TimeFormat = .hms,
                                  timeZone: TimeZone = .current,
                                  locale: Locale = Locale(identifier: "en_US_POSIX")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format.dateFormat
        return formatter.string(from: date)
    }

    /// 由毫秒级时间戳转为时间字符串
    public static func timeString(fromMilliseconds ms: Int64,
                                  format: TimeFormat = .hms,
                                  timeZone: TimeZone = .current,
                                  locale: Locale = .current) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        return timeString(from: date, format: format, timeZone: timeZone, locale: locale)
    }

    /// 由秒级时间戳转为时间字符串
    public static func timeString(fromSeconds s: Int64,
                                  format: TimeFormat = .hms,
                                  timeZone: TimeZone = .current,
                                  locale: Locale = .current) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(s))
        return timeString(from: date, format: format, timeZone: timeZone, locale: locale)
    }

    /// 由毫秒级时间戳（字符串）转为时间字符串；非法输入返回空字符串
    public static func timeString(fromMillisecondsString msString: String,
                                  format: TimeFormat = .hms,
                                  timeZone: TimeZone = .current,
                                  locale: Locale = .current) -> String {
        guard let ms = Int64(msString) else { return "" }
        return timeString(fromMilliseconds: ms, format: format, timeZone: timeZone, locale: locale)
    }
}


