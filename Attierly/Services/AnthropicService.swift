import Foundation
import UIKit

enum AnthropicError: LocalizedError {
    case invalidImage
    case networkError(Error)
    case apiError(Int, String)
    case decodingError(String)
    case emptyResults

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process the image."
        case .networkError:
            return "Unable to connect. Check your internet connection."
        case .apiError:
            return "Something went wrong. Please try again."
        case .decodingError(let detail):
            return "Failed to parse the response: \(detail)"
        case .emptyResults:
            return "No clothing items detected. Try a clearer photo."
        }
    }
}

struct AnthropicService {
    private static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-sonnet-4-20250514"
    private static let maxTokens = 4096

    private static let analysisPrompt = """
    Analyze this image and identify every clothing item visible. For each item, return a JSON object with these fields:

    - type: specific item type (e.g., "Crew Neck T-Shirt", "Slim Jeans", "Chelsea Boots")
    - category: one of "Top", "Bottom", "Outerwear", "Footwear", "Accessory", "Full Body" (for dresses, jumpsuits)
    - primary_color: the dominant color (e.g., "Navy Blue", "Charcoal", "Cream")
    - secondary_color: accent or secondary color if present, otherwise null
    - pattern: one of "Solid", "Striped", "Plaid", "Floral", "Graphic", "Abstract", "Polka Dot", "Geometric", "Camo", "Other"
    - fabric_estimate: best guess at material (e.g., "Cotton", "Denim", "Wool", "Polyester", "Linen", "Leather", "Suede", "Silk", "Knit", "Fleece")
    - weight: one of "Lightweight", "Midweight", "Heavyweight"
    - formality: one of "Casual", "Smart Casual", "Business Casual", "Business", "Formal"
    - season: array of applicable seasons from ["Spring", "Summer", "Fall", "Winter"]
    - fit: one of "Slim", "Regular", "Relaxed", "Oversized", "Cropped", or null if not determinable
    - statement_level: one of "Low", "Medium", "High" — how much visual attention the piece draws
    - description: a brief one-sentence description of the item, noting any distinguishing features (graphics, logos, unique details, texture, visible wear, etc.)

    Return ONLY a valid JSON array of objects. No markdown, no explanation, no code fences. Just the raw JSON array.

    If no clothing items are detected, return an empty array: []
    """

    static func analyzeClothing(image: UIImage) async throws -> [ClothingItem] {
        let apiKey = try ConfigManager.apiKey()

        guard let jpegData = image.jpegData(compressionQuality: 0.6) else {
            throw AnthropicError.invalidImage
        }

        let base64Image = jpegData.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": analysisPrompt
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AnthropicError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AnthropicError.apiError(httpResponse.statusCode, body)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String
        else {
            throw AnthropicError.decodingError("Unexpected response structure.")
        }

        let cleanedText = stripCodeFences(text)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw AnthropicError.decodingError("Invalid text encoding.")
        }

        let items: [ClothingItem]
        do {
            items = try JSONDecoder().decode([ClothingItem].self, from: jsonData)
        } catch {
            throw AnthropicError.decodingError(error.localizedDescription)
        }

        return items
    }

    private static func stripCodeFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            }
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}
