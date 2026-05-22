import SwiftUI

private struct AIServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue: any AIService = MockAIService()
}

extension EnvironmentValues {
    var aiService: any AIService {
        get { self[AIServiceEnvironmentKey.self] }
        set { self[AIServiceEnvironmentKey.self] = newValue }
    }
}
