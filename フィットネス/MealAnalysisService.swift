import Foundation

struct MealAnalysis: Codable {
    let calories: Double
    let protein: Double
    let notes: String?
}

enum MealAnalysisError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case refusal(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI APIキーを入力してください。"
        case .invalidResponse:
            return "食事データを解析できませんでした。"
        case .refusal(let message):
            return message
        }
    }
}

struct MealAnalysisService {
    func analyzeMeal(ingredients: String, apiKey: String) async throws -> MealAnalysis {
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw MealAnalysisError.missingAPIKey
        }

        let requestBody = ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [
                .init(
                    role: "developer",
                    content: """
                    あなたは栄養推定アシスタントです。入力された食材や料理名から、合計カロリー(kcal)と合計タンパク質(g)を推定してください。
                    曖昧な量は一般的な1食分として補完し、数値は現実的な範囲にしてください。
                    出力は指定されたJSONスキーマに厳密に従ってください。
                    """
                ),
                .init(
                    role: "user",
                    content: "次の食事の合計カロリーと合計タンパク質を推定してください: \(ingredients)"
                ),
            ],
            responseFormat: .mealAnalysisSchema
        )

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw MealAnalysisError.refusal(apiError.error.message)
            }
            throw MealAnalysisError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        if let refusal = decoded.choices.first?.message.refusal, !refusal.isEmpty {
            throw MealAnalysisError.refusal(refusal)
        }

        guard
            let content = decoded.choices.first?.message.content,
            let jsonData = content.data(using: .utf8)
        else {
            throw MealAnalysisError.invalidResponse
        }

        return try JSONDecoder().decode(MealAnalysis.self, from: jsonData)
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ResponseFormat: Encodable {
    let type: String
    let jsonSchema: JSONSchema

    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }

    static let mealAnalysisSchema = ResponseFormat(
        type: "json_schema",
        jsonSchema: JSONSchema(
            name: "meal_analysis",
            strict: true,
            schema: SchemaDefinition(
                type: "object",
                properties: [
                    "calories": .number(description: "Estimated total calories in kcal"),
                    "protein": .number(description: "Estimated total protein in grams"),
                    "notes": .string(description: "Optional short explanation of assumptions"),
                ],
                required: ["calories", "protein", "notes"],
                additionalProperties: false
            )
        )
    )
}

private struct JSONSchema: Encodable {
    let name: String
    let strict: Bool
    let schema: SchemaDefinition
}

private struct SchemaDefinition: Encodable {
    let type: String
    let properties: [String: SchemaProperty]
    let required: [String]
    let additionalProperties: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case properties
        case required
        case additionalProperties = "additionalProperties"
    }
}

private struct SchemaProperty: Encodable {
    let type: String
    let description: String

    static func number(description: String) -> SchemaProperty {
        SchemaProperty(type: "number", description: description)
    }

    static func string(description: String) -> SchemaProperty {
        SchemaProperty(type: "string", description: description)
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
        let refusal: String?
    }
}

private struct OpenAIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
