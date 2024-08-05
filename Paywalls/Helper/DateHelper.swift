import Foundation

struct DateHelper {
    private static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }

    static func toDateString(_ date: Date, format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }

    static func fromDateString(_ date: String, format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") -> Date? {
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: date)
    }
}
