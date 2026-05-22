import Foundation

struct AILeadQualification: Equatable {
    var leadScore: Int
    var projectValueEstimate: Double
    var urgencyLevel: String
    var conversionLikelihood: Double
    var recommendedAction: String
    var followUpTimingSuggestion: String
    var category: LeadCategory
}

struct AIProposalDraft: Equatable {
    var title: String
    var content: String
    var estimatedValue: Double
    var serviceBreakdown: [String]
    var pricingStructure: String
    var optionalUpsells: [String]
    var timelineEstimate: String
    var exclusions: [String]
}

struct AIFollowUpDraft: Equatable {
    var type: FollowUpType
    var tone: FollowUpTone
    var content: String
}

struct VoiceLeadSummary: Equatable {
    var leadSummary: String
    var quoteNotes: String
    var followUpTasks: String
    var crmNotes: String
}

struct SalesInsightMetric: Identifiable, Equatable {
    let id = UUID()
    var label: String
    var value: Double
}

struct SalesInsights: Equatable {
    var headline: String
    var sourcePerformance: [SalesInsightMetric]
    var conversionRate: Double
    var averageQuoteValue: Double
    var bestPerformingService: String
    var followUpEffectiveness: Double
    var estimatedRevenuePipeline: Double
    var recommendations: [String]
}

enum AIServiceError: LocalizedError {
    case invalidResponse
    case backendNotConfigured

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The AI service returned an invalid response."
        case .backendNotConfigured:
            "Configure your secure backend endpoint before disabling mock AI mode."
        }
    }
}

@MainActor
protocol AIService {
    func qualifyLead(_ lead: Lead, businessType: BusinessType, photos: [LeadPhoto]) async throws -> AILeadQualification
    func generateProposal(for lead: Lead, businessType: BusinessType, qualification: QualificationResult?) async throws -> AIProposalDraft
    func generateFollowUp(for lead: Lead, type: FollowUpType, tone: FollowUpTone, context: String) async throws -> AIFollowUpDraft
    func summarizeVoiceNotes(_ transcript: String, businessType: BusinessType) async throws -> VoiceLeadSummary
    func generateSalesInsights(
        leads: [Lead],
        proposals: [Proposal],
        followUps: [FollowUpMessage],
        businessType: BusinessType
    ) async throws -> SalesInsights
}
