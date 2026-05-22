import Foundation

enum AppConstants {
    static let appName = "LeadPilot IQ"
    static let mockAIEnabledDefault = true
    static let freeLeadLimit = 20
    static let backendURL = URL(string: "https://YOUR_BACKEND_URL.com/leadpilot-iq")!

    static let internalAIPrompt = """
    You are LeadPilot IQ, an AI sales and lead qualification assistant for service businesses. Review lead details, service requests, budgets, notes, and uploaded photos. Generate professional lead qualification summaries, quote drafts, follow-up suggestions, and sales insights. Do not guarantee sales, conversions, project values, or financial outcomes. Use practical, professional language.
    """

    static let disclaimers = [
        "AI suggestions should be reviewed.",
        "Pricing estimates are not guaranteed.",
        "Not financial advice.",
        "Not legal advice.",
        "User remains responsible for final pricing and contracts."
    ]
}

enum AppFormatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension Double {
    var currencyFormatted: String {
        AppFormatters.currency.string(from: NSNumber(value: self)) ?? "GBP \(Int(self))"
    }

    var percentFormatted: String {
        AppFormatters.percent.string(from: NSNumber(value: self)) ?? "\(Int(self * 100))%"
    }
}

extension Date {
    var shortFormatted: String {
        AppFormatters.shortDate.string(from: self)
    }
}
