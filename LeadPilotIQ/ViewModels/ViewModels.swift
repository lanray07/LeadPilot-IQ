import Foundation
import Observation
import SwiftData

struct LeadPhotoDraft: Identifiable, Equatable {
    let id = UUID()
    var imageData: Data
    var caption: String = ""
}

struct DashboardMetrics: Equatable {
    var newLeads: Int
    var hotLeads: Int
    var quotesSent: Int
    var pendingFollowUps: Int
    var conversionRate: Double
    var estimatedPipelineValue: Double
}

@MainActor
@Observable
final class DashboardViewModel {
    func metrics(
        leads: [Lead],
        proposals: [Proposal],
        qualifications: [QualificationResult],
        followUps: [FollowUpMessage]
    ) -> DashboardMetrics {
        let newLeads = leads.filter { $0.status == .new }.count
        let hotLeadIDs = Set(qualifications.filter { $0.leadScore >= 75 || $0.category == .hot || $0.category == .urgent || $0.category == .highValue }.map(\.leadId))
        let quotesSent = proposals.filter { $0.status == .sent }.count
        let pendingFollowUps = max(0, leads.filter { $0.status == .followUpDue }.count + followUps.count - leads.filter { $0.status == .converted }.count)
        let converted = leads.filter { $0.status == .converted }.count
        let conversionRate = leads.isEmpty ? 0 : Double(converted) / Double(leads.count)
        let pipeline = proposals
            .filter { $0.status == .draft || $0.status == .sent }
            .map(\.estimatedValue)
            .reduce(0, +)

        return DashboardMetrics(
            newLeads: newLeads,
            hotLeads: hotLeadIDs.count,
            quotesSent: quotesSent,
            pendingFollowUps: pendingFollowUps,
            conversionRate: conversionRate,
            estimatedPipelineValue: pipeline
        )
    }
}

@MainActor
@Observable
final class LeadFormViewModel {
    var name = ""
    var phone = ""
    var email = ""
    var serviceRequested = ""
    var budgetRange = ""
    var location = ""
    var urgency: LeadUrgency = .thisMonth
    var source: LeadSource = .website
    var notes = ""
    var photoDrafts: [LeadPhotoDraft] = []
    var errorMessage: String?

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !serviceRequested.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(in context: ModelContext) throws -> Lead {
        guard canSave else {
            errorMessage = "Lead name and service requested are required."
            throw ValidationError.missingRequiredFields
        }

        let lead = Lead(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            serviceRequested: serviceRequested.trimmingCharacters(in: .whitespacesAndNewlines),
            budgetRange: budgetRange.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            urgency: urgency,
            source: source,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        context.insert(lead)
        photoDrafts.forEach { draft in
            context.insert(LeadPhoto(leadId: lead.id, imageData: draft.imageData, caption: draft.caption))
        }
        try context.save()
        reset()
        return lead
    }

    func reset() {
        name = ""
        phone = ""
        email = ""
        serviceRequested = ""
        budgetRange = ""
        location = ""
        urgency = .thisMonth
        source = .website
        notes = ""
        photoDrafts = []
        errorMessage = nil
    }
}

@MainActor
@Observable
final class QualificationViewModel {
    var isLoading = false
    var result: AILeadQualification?
    var errorMessage: String?

    func qualify(
        lead: Lead,
        businessType: BusinessType,
        photos: [LeadPhoto],
        aiService: any AIService
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            result = try await aiService.qualifyLead(lead, businessType: businessType, photos: photos)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveResult(for lead: Lead, in context: ModelContext) throws -> QualificationResult? {
        guard let result else { return nil }
        let model = QualificationResult(
            leadId: lead.id,
            leadScore: result.leadScore,
            projectValueEstimate: result.projectValueEstimate,
            urgencyLevel: result.urgencyLevel,
            conversionLikelihood: result.conversionLikelihood,
            recommendedAction: result.recommendedAction,
            followUpTimingSuggestion: result.followUpTimingSuggestion,
            category: result.category
        )
        lead.status = .qualified
        context.insert(model)
        try context.save()
        return model
    }
}

@MainActor
@Observable
final class QuoteViewModel {
    var isLoading = false
    var draft: AIProposalDraft?
    var editableTitle = ""
    var editableContent = ""
    var estimatedValue: Double = 0
    var errorMessage: String?

    var hasGeneratedDraft: Bool {
        draft != nil || !editableContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func generate(
        lead: Lead,
        businessType: BusinessType,
        qualification: QualificationResult?,
        aiService: any AIService
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let proposal = try await aiService.generateProposal(for: lead, businessType: businessType, qualification: qualification)
            draft = proposal
            editableTitle = proposal.title
            editableContent = proposal.content
            estimatedValue = proposal.estimatedValue
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProposal(for lead: Lead?, in context: ModelContext) throws -> Proposal {
        let title = editableTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Proposal" : editableTitle
        let proposal = Proposal(
            leadId: lead?.id,
            title: title,
            content: editableContent,
            estimatedValue: estimatedValue,
            status: .draft
        )
        if let lead {
            lead.status = .quoteSent
        }
        context.insert(proposal)
        try context.save()
        return proposal
    }

    func saveTemplate(in context: ModelContext) throws -> Proposal {
        let baseTitle = editableTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Proposal" : editableTitle
        let template = Proposal(
            leadId: nil,
            title: "\(baseTitle) Template",
            content: editableContent,
            estimatedValue: estimatedValue,
            status: .draft
        )
        context.insert(template)
        try context.save()
        return template
    }
}

@MainActor
@Observable
final class FollowUpViewModel {
    var type: FollowUpType = .sms
    var tone: FollowUpTone = .professional
    var context = ""
    var generatedContent = ""
    var isLoading = false
    var errorMessage: String?

    var canSave: Bool {
        !generatedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func generate(lead: Lead, aiService: any AIService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let draft = try await aiService.generateFollowUp(for: lead, type: type, tone: tone, context: context)
            generatedContent = draft.content
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(for lead: Lead?, in context: ModelContext) throws -> FollowUpMessage {
        let followUp = FollowUpMessage(
            leadId: lead?.id,
            type: type,
            tone: tone,
            content: generatedContent
        )
        if let lead {
            lead.status = .followUpDue
        }
        context.insert(followUp)
        try context.save()
        return followUp
    }
}

@MainActor
@Observable
final class VoiceNotesViewModel {
    var summary: VoiceLeadSummary?
    var isLoading = false
    var errorMessage: String?

    func summarize(transcript: String, businessType: BusinessType, aiService: any AIService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            summary = try await aiService.summarizeVoiceNotes(transcript, businessType: businessType)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createLeadFromSummary(in context: ModelContext, source: LeadSource = .phoneCall) throws -> Lead? {
        guard let summary else { return nil }
        let lead = Lead(
            name: "Voice note lead",
            serviceRequested: "Review voice note",
            urgency: .thisMonth,
            source: source,
            notes: """
            Lead summary:
            \(summary.leadSummary)

            Quote notes:
            \(summary.quoteNotes)

            Follow-up tasks:
            \(summary.followUpTasks)

            CRM notes:
            \(summary.crmNotes)
            """
        )
        context.insert(lead)
        try context.save()
        return lead
    }
}

@MainActor
@Observable
final class AnalyticsViewModel {
    var insights: SalesInsights?
    var isLoading = false
    var errorMessage: String?

    func refresh(
        leads: [Lead],
        proposals: [Proposal],
        followUps: [FollowUpMessage],
        businessType: BusinessType,
        aiService: any AIService
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            insights = try await aiService.generateSalesInsights(
                leads: leads,
                proposals: proposals,
                followUps: followUps,
                businessType: businessType
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class ProposalCenterViewModel {
    var errorMessage: String?

    func duplicate(_ proposal: Proposal, in context: ModelContext) throws {
        let copy = Proposal(
            leadId: proposal.leadId,
            title: "\(proposal.title) Copy",
            content: proposal.content,
            estimatedValue: proposal.estimatedValue,
            status: .draft
        )
        context.insert(copy)
        try context.save()
    }

    func updateStatus(_ proposal: Proposal, status: ProposalStatus, in context: ModelContext) throws {
        proposal.status = status
        try context.save()
    }
}

enum ValidationError: LocalizedError {
    case missingRequiredFields

    var errorDescription: String? {
        "Please complete all required fields."
    }
}

enum ProfileResolver {
    static func currentProfile(from profiles: [BusinessProfile]) -> BusinessProfile? {
        profiles.sorted(by: { $0.createdAt < $1.createdAt }).first
    }

    static func businessType(from profiles: [BusinessProfile]) -> BusinessType {
        currentProfile(from: profiles)?.businessType ?? .localContractor
    }
}
