import Foundation
import SwiftData

enum BusinessType: String, CaseIterable, Identifiable, Codable {
    case landscaping
    case roofing
    case cleaning
    case plumbing
    case electrician
    case propertyServices
    case marketingAgency
    case freelancer
    case localContractor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .landscaping: "Landscaping"
        case .roofing: "Roofing"
        case .cleaning: "Cleaning services"
        case .plumbing: "Plumbing"
        case .electrician: "Electricians"
        case .propertyServices: "Property services"
        case .marketingAgency: "Marketing agencies"
        case .freelancer: "Freelancers"
        case .localContractor: "Local contractors"
        }
    }

    var defaultEstimate: Double {
        switch self {
        case .roofing: 8500
        case .landscaping: 3600
        case .cleaning: 650
        case .plumbing: 1200
        case .electrician: 1400
        case .propertyServices: 2400
        case .marketingAgency: 3000
        case .freelancer: 1250
        case .localContractor: 2200
        }
    }
}

enum PrimaryGoal: String, CaseIterable, Identifiable, Codable {
    case moreBookings
    case qualifyLeadsFaster
    case sendQuotesFaster
    case automateFollowUp
    case increaseConversions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .moreBookings: "More bookings"
        case .qualifyLeadsFaster: "Qualify leads faster"
        case .sendQuotesFaster: "Send quotes faster"
        case .automateFollowUp: "Automate follow-up"
        case .increaseConversions: "Increase conversions"
        }
    }
}

enum LeadUrgency: String, CaseIterable, Identifiable, Codable {
    case flexible
    case thisMonth
    case thisWeek
    case asap
    case emergency

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flexible: "Flexible"
        case .thisMonth: "This month"
        case .thisWeek: "This week"
        case .asap: "ASAP"
        case .emergency: "Emergency"
        }
    }
}

enum LeadSource: String, CaseIterable, Identifiable, Codable {
    case website
    case whatsapp
    case facebook
    case instagram
    case referral
    case phoneCall
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .website: "Website"
        case .whatsapp: "WhatsApp"
        case .facebook: "Facebook"
        case .instagram: "Instagram"
        case .referral: "Referral"
        case .phoneCall: "Phone call"
        case .other: "Other"
        }
    }
}

enum LeadStatus: String, CaseIterable, Identifiable, Codable {
    case new
    case qualified
    case quoteSent
    case followUpDue
    case converted
    case lost

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new: "New"
        case .qualified: "Qualified"
        case .quoteSent: "Quote sent"
        case .followUpDue: "Follow-up due"
        case .converted: "Converted"
        case .lost: "Lost"
        }
    }
}

enum LeadCategory: String, CaseIterable, Identifiable, Codable {
    case cold
    case warm
    case hot
    case urgent
    case highValue

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cold: "Cold"
        case .warm: "Warm"
        case .hot: "Hot"
        case .urgent: "Urgent"
        case .highValue: "High-value"
        }
    }
}

enum ProposalStatus: String, CaseIterable, Identifiable, Codable {
    case draft
    case sent
    case accepted
    case rejected

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .sent: "Sent"
        case .accepted: "Accepted"
        case .rejected: "Rejected"
        }
    }
}

enum FollowUpType: String, CaseIterable, Identifiable, Codable {
    case sms
    case email
    case whatsapp
    case objectionHandling
    case reminder
    case reviewRequest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sms: "SMS"
        case .email: "Email"
        case .whatsapp: "WhatsApp-style"
        case .objectionHandling: "Objection handling"
        case .reminder: "Reminder"
        case .reviewRequest: "Review request"
        }
    }
}

enum FollowUpTone: String, CaseIterable, Identifiable, Codable {
    case professional
    case friendly
    case premium
    case persuasive
    case urgent

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
    case free
    case proMonthly
    case proYearly
    case businessMonthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: "Free"
        case .proMonthly: "Pro Monthly"
        case .proYearly: "Pro Yearly"
        case .businessMonthly: "Business Monthly"
        }
    }

    var productID: String? {
        switch self {
        case .free: nil
        case .proMonthly: "com.leadpilotiq.pro.monthly"
        case .proYearly: "com.leadpilotiq.pro.yearly"
        case .businessMonthly: "com.leadpilotiq.business.monthly"
        }
    }

    var pricePlaceholder: String {
        switch self {
        case .free: "Free"
        case .proMonthly: "\u{00A3}19.99/month"
        case .proYearly: "\u{00A3}149.99/year"
        case .businessMonthly: "\u{00A3}79.99/month"
        }
    }

    var subscriptionLength: String {
        switch self {
        case .free: "No paid subscription"
        case .proMonthly, .businessMonthly: "1 month"
        case .proYearly: "1 year"
        }
    }

    var renewalSummary: String {
        switch self {
        case .free: "No automatic renewal."
        case .proMonthly, .businessMonthly: "Auto-renews monthly until cancelled."
        case .proYearly: "Auto-renews yearly until cancelled."
        }
    }

    var isPaid: Bool { self != .free }

    static var paidPlans: [SubscriptionPlan] {
        [.proMonthly, .proYearly, .businessMonthly]
    }
}

@Model
final class Lead {
    @Attribute(.unique) var id: UUID
    var name: String
    var phone: String
    var email: String
    var serviceRequested: String
    var budgetRange: String
    var location: String
    var urgencyRaw: String
    var sourceRaw: String
    var notes: String
    var statusRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        phone: String = "",
        email: String = "",
        serviceRequested: String,
        budgetRange: String = "",
        location: String = "",
        urgency: LeadUrgency = .thisMonth,
        source: LeadSource = .website,
        notes: String = "",
        status: LeadStatus = .new,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.serviceRequested = serviceRequested
        self.budgetRange = budgetRange
        self.location = location
        self.urgencyRaw = urgency.rawValue
        self.sourceRaw = source.rawValue
        self.notes = notes
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }

    var urgency: LeadUrgency {
        get { LeadUrgency(rawValue: urgencyRaw) ?? .thisMonth }
        set { urgencyRaw = newValue.rawValue }
    }

    var source: LeadSource {
        get { LeadSource(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }

    var status: LeadStatus {
        get { LeadStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }
}

@Model
final class LeadPhoto {
    @Attribute(.unique) var id: UUID
    var leadId: UUID
    @Attribute(.externalStorage) var imageData: Data?
    var localImageURL: URL?
    var caption: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        leadId: UUID,
        imageData: Data? = nil,
        localImageURL: URL? = nil,
        caption: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.leadId = leadId
        self.imageData = imageData
        self.localImageURL = localImageURL
        self.caption = caption
        self.createdAt = createdAt
    }
}

@Model
final class QualificationResult {
    @Attribute(.unique) var id: UUID
    var leadId: UUID
    var leadScore: Int
    var projectValueEstimate: Double
    var urgencyLevel: String
    var conversionLikelihood: Double
    var recommendedAction: String
    var followUpTimingSuggestion: String
    var categoryRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        leadId: UUID,
        leadScore: Int,
        projectValueEstimate: Double,
        urgencyLevel: String,
        conversionLikelihood: Double,
        recommendedAction: String,
        followUpTimingSuggestion: String,
        category: LeadCategory,
        createdAt: Date = .now
    ) {
        self.id = id
        self.leadId = leadId
        self.leadScore = leadScore
        self.projectValueEstimate = projectValueEstimate
        self.urgencyLevel = urgencyLevel
        self.conversionLikelihood = conversionLikelihood
        self.recommendedAction = recommendedAction
        self.followUpTimingSuggestion = followUpTimingSuggestion
        self.categoryRaw = category.rawValue
        self.createdAt = createdAt
    }

    var category: LeadCategory {
        get { LeadCategory(rawValue: categoryRaw) ?? .warm }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class Proposal {
    @Attribute(.unique) var id: UUID
    var leadId: UUID?
    var title: String
    var content: String
    var estimatedValue: Double
    var statusRaw: String
    var pdfLocalURL: URL?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        leadId: UUID? = nil,
        title: String,
        content: String,
        estimatedValue: Double = 0,
        status: ProposalStatus = .draft,
        pdfLocalURL: URL? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.leadId = leadId
        self.title = title
        self.content = content
        self.estimatedValue = estimatedValue
        self.statusRaw = status.rawValue
        self.pdfLocalURL = pdfLocalURL
        self.createdAt = createdAt
    }

    var status: ProposalStatus {
        get { ProposalStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
}

@Model
final class FollowUpMessage {
    @Attribute(.unique) var id: UUID
    var leadId: UUID?
    var typeRaw: String
    var toneRaw: String
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        leadId: UUID? = nil,
        type: FollowUpType,
        tone: FollowUpTone,
        content: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.leadId = leadId
        self.typeRaw = type.rawValue
        self.toneRaw = tone.rawValue
        self.content = content
        self.createdAt = createdAt
    }

    var type: FollowUpType {
        get { FollowUpType(rawValue: typeRaw) ?? .sms }
        set { typeRaw = newValue.rawValue }
    }

    var tone: FollowUpTone {
        get { FollowUpTone(rawValue: toneRaw) ?? .professional }
        set { toneRaw = newValue.rawValue }
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var planRaw: String
    var isActive: Bool
    var renewsAt: Date?

    init(
        id: UUID = UUID(),
        plan: SubscriptionPlan = .free,
        isActive: Bool = false,
        renewsAt: Date? = nil
    ) {
        self.id = id
        self.planRaw = plan.rawValue
        self.isActive = isActive
        self.renewsAt = renewsAt
    }

    var plan: SubscriptionPlan {
        get { SubscriptionPlan(rawValue: planRaw) ?? .free }
        set { planRaw = newValue.rawValue }
    }
}

@Model
final class BusinessProfile {
    @Attribute(.unique) var id: UUID
    var businessName: String
    var businessTypeRaw: String
    var primaryGoalRaw: String
    var proposalFooter: String
    var brandingName: String
    var onboardingCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        businessName: String = "",
        businessType: BusinessType = .localContractor,
        primaryGoal: PrimaryGoal = .qualifyLeadsFaster,
        proposalFooter: String = "Thank you for considering us. All estimates are subject to final review and site confirmation.",
        brandingName: String = "LeadPilot IQ",
        onboardingCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.businessName = businessName
        self.businessTypeRaw = businessType.rawValue
        self.primaryGoalRaw = primaryGoal.rawValue
        self.proposalFooter = proposalFooter
        self.brandingName = brandingName
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
    }

    var businessType: BusinessType {
        get { BusinessType(rawValue: businessTypeRaw) ?? .localContractor }
        set { businessTypeRaw = newValue.rawValue }
    }

    var primaryGoal: PrimaryGoal {
        get { PrimaryGoal(rawValue: primaryGoalRaw) ?? .qualifyLeadsFaster }
        set { primaryGoalRaw = newValue.rawValue }
    }
}
