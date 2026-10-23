import Foundation

enum CommunicationLinks {
    static func phone(_ value: String) -> URL? {
        let digits = value.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    static func message(_ value: String) -> URL? {
        let digits = value.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "sms:\(digits)")
    }

    static func email(_ value: String) -> URL? {
        guard !value.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = value
        return components.url
    }

    static func linkedIn(_ value: String) -> URL? {
        social(value, base: "https://www.linkedin.com/in/")
    }

    static func instagram(_ value: String) -> URL? {
        social(value.trimmingCharacters(in: CharacterSet(charactersIn: "@")), base: "https://www.instagram.com/")
    }

    static func whatsApp(_ value: String) -> URL? {
        let digits = value.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "https://wa.me/\(digits)")
    }

    static func website(_ value: String) -> URL? {
        social(value, base: "https://")
    }

    private static func social(_ value: String, base: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
            return url
        }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: base + encoded)
    }
}
