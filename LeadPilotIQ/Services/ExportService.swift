import Foundation

enum ExportService {
    static func exportJSON(
        leads: [Lead],
        proposals: [Proposal],
        followUps: [FollowUpMessage],
        qualifications: [QualificationResult]
    ) throws -> URL {
        let snapshot = ExportSnapshot(
            exportedAt: .now,
            leads: leads.map(LeadExport.init),
            proposals: proposals.map(ProposalExport.init),
            followUps: followUps.map(FollowUpExport.init),
            qualifications: qualifications.map(QualificationExport.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = directory.appendingPathComponent("LeadPilotIQ-Export-\(Int(Date().timeIntervalSince1970)).json")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

private struct ExportSnapshot: Codable {
    var exportedAt: Date
    var leads: [LeadExport]
    var proposals: [ProposalExport]
    var followUps: [FollowUpExport]
    var qualifications: [QualificationExport]
}

private struct LeadExport: Codable {
    var id: UUID
    var name: String
    var phone: String
    var email: String
    var serviceRequested: String
    var budgetRange: String
    var location: String
    var urgency: String
    var source: String
    var notes: String
    var status: String
    var createdAt: Date

    init(_ lead: Lead) {
        id = lead.id
        name = lead.name
        phone = lead.phone
        email = lead.email
        serviceRequested = lead.serviceRequested
        budgetRange = lead.budgetRange
        location = lead.location
        urgency = lead.urgency.displayName
        source = lead.source.displayName
        notes = lead.notes
        status = lead.status.displayName
        createdAt = lead.createdAt
    }
}

private struct ProposalExport: Codable {
    var id: UUID
    var leadId: UUID?
    var title: String
    var content: String
    var estimatedValue: Double
    var status: String
    var pdfLocalURL: URL?
    var createdAt: Date

    init(_ proposal: Proposal) {
        id = proposal.id
        leadId = proposal.leadId
        title = proposal.title
        content = proposal.content
        estimatedValue = proposal.estimatedValue
        status = proposal.status.displayName
        pdfLocalURL = proposal.pdfLocalURL
        createdAt = proposal.createdAt
    }
}

private struct FollowUpExport: Codable {
    var id: UUID
    var leadId: UUID?
    var type: String
    var tone: String
    var content: String
    var createdAt: Date

    init(_ followUp: FollowUpMessage) {
        id = followUp.id
        leadId = followUp.leadId
        type = followUp.type.displayName
        tone = followUp.tone.displayName
        content = followUp.content
        createdAt = followUp.createdAt
    }
}

private struct QualificationExport: Codable {
    var id: UUID
    var leadId: UUID
    var leadScore: Int
    var projectValueEstimate: Double
    var urgencyLevel: String
    var conversionLikelihood: Double
    var recommendedAction: String
    var followUpTimingSuggestion: String
    var category: String
    var createdAt: Date

    init(_ qualification: QualificationResult) {
        id = qualification.id
        leadId = qualification.leadId
        leadScore = qualification.leadScore
        projectValueEstimate = qualification.projectValueEstimate
        urgencyLevel = qualification.urgencyLevel
        conversionLikelihood = qualification.conversionLikelihood
        recommendedAction = qualification.recommendedAction
        followUpTimingSuggestion = qualification.followUpTimingSuggestion
        category = qualification.category.displayName
        createdAt = qualification.createdAt
    }
}
