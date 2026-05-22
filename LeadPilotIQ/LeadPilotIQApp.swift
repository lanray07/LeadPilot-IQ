import SwiftData
import SwiftUI

@main
struct LeadPilotIQApp: App {
    @AppStorage("mockAIEnabled") private var mockAIEnabled = AppConstants.mockAIEnabledDefault
    @State private var subscriptionService = SubscriptionService()

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Lead.self,
            LeadPhoto.self,
            QualificationResult.self,
            Proposal.self,
            FollowUpMessage.self,
            SubscriptionState.self,
            BusinessProfile.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()

    private var configuredAIService: any AIService {
        mockAIEnabled ? MockAIService() : RemoteAIService()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(modelContainer)
                .environment(\.aiService, configuredAIService)
                .environment(subscriptionService)
                .task {
                    subscriptionService.start()
                }
        }
    }
}
