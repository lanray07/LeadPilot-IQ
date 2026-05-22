import Foundation

struct MockAIService: AIService {
    nonisolated init() {}

    func qualifyLead(_ lead: Lead, businessType: BusinessType, photos: [LeadPhoto]) async throws -> AILeadQualification {
        try await Task.sleep(nanoseconds: 450_000_000)

        let notes = "\(lead.serviceRequested) \(lead.budgetRange) \(lead.notes)".lowercased()
        var score = 42

        if !lead.phone.isEmpty || !lead.email.isEmpty { score += 10 }
        if lead.source == .referral { score += 12 }
        if lead.urgency == .asap || lead.urgency == .emergency { score += 18 }
        if notes.contains("ready") || notes.contains("book") || notes.contains("start") { score += 10 }
        if notes.contains("cheap") || notes.contains("just looking") { score -= 10 }
        if !photos.isEmpty { score += 5 }

        let estimate = estimatedValue(for: lead, businessType: businessType)
        if estimate > 5_000 { score += 10 }
        if estimate > 12_000 { score += 8 }

        score = min(max(score, 8), 98)

        let category: LeadCategory
        if lead.urgency == .emergency {
            category = .urgent
        } else if estimate >= 10_000 {
            category = .highValue
        } else if score >= 78 {
            category = .hot
        } else if score >= 52 {
            category = .warm
        } else {
            category = .cold
        }

        return AILeadQualification(
            leadScore: score,
            projectValueEstimate: estimate,
            urgencyLevel: lead.urgency.displayName,
            conversionLikelihood: Double(score) / 100,
            recommendedAction: recommendedAction(score: score, urgency: lead.urgency, estimate: estimate),
            followUpTimingSuggestion: score >= 75 || lead.urgency == .emergency ? "Follow up within 15 minutes." : "Follow up within 24 hours with a concise next step.",
            category: category
        )
    }

    func generateProposal(for lead: Lead, businessType: BusinessType, qualification: QualificationResult?) async throws -> AIProposalDraft {
        try await Task.sleep(nanoseconds: 550_000_000)

        let estimate = qualification?.projectValueEstimate ?? estimatedValue(for: lead, businessType: businessType)
        let timeline = timeline(for: lead.urgency)
        let service = lead.serviceRequested.isEmpty ? businessType.displayName : lead.serviceRequested
        let title = "\(service) Proposal for \(lead.name)"
        let upsells = upsells(for: businessType)
        let breakdown = [
            "Initial review of the enquiry, goals, location, and access requirements.",
            "Recommended service plan for \(service.lowercased()).",
            "Materials, labour, scheduling, and project coordination assumptions.",
            "Quality check and client handover after completion."
        ]
        let exclusions = [
            "Major scope changes after approval.",
            "Third-party permits, specialist surveys, or structural reports unless listed.",
            "Hidden issues discovered after site inspection."
        ]

        let content = """
        Hi \(lead.name),

        Thank you for your enquiry about \(service). Based on the details provided, we recommend the following approach.

        Estimate summary
        The current working estimate is \(estimate.currencyFormatted). This is a planning estimate and should be confirmed after final review, measurements, and any site-specific checks.

        Service breakdown
        - \(breakdown.joined(separator: "\n- "))

        Pricing structure
        \(pricingStructure(for: businessType, estimate: estimate))

        Optional upsells
        - \(upsells.joined(separator: "\n- "))

        Timeline estimate
        \(timeline)

        Exclusions
        - \(exclusions.joined(separator: "\n- "))

        Recommended next step
        \(qualification?.recommendedAction ?? "Confirm the scope, answer any questions, and book a discovery call or site visit.")

        Disclaimer
        AI-generated pricing and wording should be reviewed. Estimates are not guaranteed and are not legal or financial advice. Final pricing, contracts, and client communication remain your responsibility.
        """

        return AIProposalDraft(
            title: title,
            content: content,
            estimatedValue: estimate,
            serviceBreakdown: breakdown,
            pricingStructure: pricingStructure(for: businessType, estimate: estimate),
            optionalUpsells: upsells,
            timelineEstimate: timeline,
            exclusions: exclusions
        )
    }

    func generateFollowUp(for lead: Lead, type: FollowUpType, tone: FollowUpTone, context: String) async throws -> AIFollowUpDraft {
        try await Task.sleep(nanoseconds: 350_000_000)

        let service = lead.serviceRequested.isEmpty ? "your project" : lead.serviceRequested
        let nextStep = context.isEmpty ? "Would you like me to confirm the next available slot?" : context
        let content: String

        switch type {
        case .sms:
            content = "Hi \(lead.name), thanks again for your \(service) enquiry. I can help with the next step: \(nextStep)"
        case .email:
            content = """
            Subject: Next step for your \(service) enquiry

            Hi \(lead.name),

            Thanks for reaching out. I reviewed the details you shared and can help you move this forward.

            \(nextStep)

            Best,
            LeadPilot IQ
            """
        case .whatsapp:
            content = "Hi \(lead.name), just following up on \(service). I can send over the next steps and an estimate once we confirm a couple of details. \(nextStep)"
        case .objectionHandling:
            content = "I completely understand wanting to compare options. The best way to avoid surprises is to confirm scope, timeline, and exclusions up front. I can walk you through the estimate and adjust it around your priorities."
        case .reminder:
            content = "Hi \(lead.name), quick reminder that your \(service) estimate is ready to review. I can answer questions or update the proposal if anything has changed."
        case .reviewRequest:
            content = "Hi \(lead.name), thanks again for working with us. If you were happy with the service, a short review would really help other local customers choose with confidence."
        }

        return AIFollowUpDraft(type: type, tone: tone, content: apply(tone: tone, to: content))
    }

    func summarizeVoiceNotes(_ transcript: String, businessType: BusinessType) async throws -> VoiceLeadSummary {
        try await Task.sleep(nanoseconds: 400_000_000)

        let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = cleaned.isEmpty ? "No voice note transcript was captured." : cleaned

        return VoiceLeadSummary(
            leadSummary: "Potential \(businessType.displayName.lowercased()) lead. Summary: \(summary)",
            quoteNotes: "Check scope, location, urgency, access requirements, budget expectations, and whether photos or a site visit are needed.",
            followUpTasks: "Send acknowledgement, ask one clarifying question, and propose a next step within 24 hours.",
            crmNotes: "Voice note converted by mock AI. Review before saving to the lead record."
        )
    }

    func generateSalesInsights(
        leads: [Lead],
        proposals: [Proposal],
        followUps: [FollowUpMessage],
        businessType: BusinessType
    ) async throws -> SalesInsights {
        try await Task.sleep(nanoseconds: 300_000_000)

        let converted = leads.filter { $0.status == .converted }.count
        let conversionRate = leads.isEmpty ? 0 : Double(converted) / Double(leads.count)
        let sentOrAccepted = proposals.filter { $0.status == .sent || $0.status == .accepted }
        let averageQuote = proposals.isEmpty ? 0 : proposals.map(\.estimatedValue).reduce(0, +) / Double(proposals.count)
        let pipeline = proposals.filter { $0.status == .draft || $0.status == .sent }.map(\.estimatedValue).reduce(0, +)

        let sourceCounts = Dictionary(grouping: leads, by: { $0.source.displayName })
            .map { SalesInsightMetric(label: $0.key, value: Double($0.value.count)) }
            .sorted { $0.value > $1.value }

        let serviceCounts = Dictionary(grouping: leads, by: { $0.serviceRequested.isEmpty ? businessType.displayName : $0.serviceRequested })
        let bestService = serviceCounts.max(by: { $0.value.count < $1.value.count })?.key ?? businessType.displayName
        let followUpEffectiveness = leads.isEmpty ? 0 : min(Double(followUps.count) / Double(max(leads.count, 1)), 1)

        return SalesInsights(
            headline: "\(sentOrAccepted.count) active quotes with \(pipeline.currencyFormatted) in estimated pipeline.",
            sourcePerformance: sourceCounts,
            conversionRate: conversionRate,
            averageQuoteValue: averageQuote,
            bestPerformingService: bestService,
            followUpEffectiveness: followUpEffectiveness,
            estimatedRevenuePipeline: pipeline,
            recommendations: [
                "Prioritize high-score leads and referrals first.",
                "Send quotes within the same business day for urgent enquiries.",
                "Add a clear exclusion section to reduce back-and-forth before approval."
            ]
        )
    }

    private func estimatedValue(for lead: Lead, businessType: BusinessType) -> Double {
        let numbers = extractedNumbers(from: lead.budgetRange)
        if let average = numbers.isEmpty ? nil : numbers.reduce(0, +) / Double(numbers.count) {
            return max(average, 100)
        }

        let text = "\(lead.serviceRequested) \(lead.notes)".lowercased()
        var estimate = businessType.defaultEstimate
        if text.contains("large") || text.contains("full") || text.contains("commercial") { estimate *= 1.8 }
        if text.contains("small") || text.contains("repair") || text.contains("basic") { estimate *= 0.55 }
        if lead.urgency == .emergency { estimate *= 1.2 }
        return estimate.rounded()
    }

    private func extractedNumbers(from text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: #"[\d,]+(?:\.\d+)?"#) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let tokenRange = Range(match.range, in: text) else { return nil }
            let token = String(text[tokenRange]).replacingOccurrences(of: ",", with: "")
            return Double(token)
        }
    }

    private func recommendedAction(score: Int, urgency: LeadUrgency, estimate: Double) -> String {
        if urgency == .emergency {
            return "Call immediately, confirm availability, and send a short written next-step summary."
        }
        if estimate >= 10_000 {
            return "Book a discovery call or site visit and prepare a premium proposal with clear scope options."
        }
        if score >= 75 {
            return "Send a same-day quote and ask for confirmation of timing and decision criteria."
        }
        if score >= 50 {
            return "Ask one clarifying question, then send a concise estimate range."
        }
        return "Qualify budget and timeline before investing time in a detailed proposal."
    }

    private func timeline(for urgency: LeadUrgency) -> String {
        switch urgency {
        case .emergency: "Response today where availability allows. Full schedule to be confirmed immediately."
        case .asap: "Target start within 1-2 weeks after scope approval and deposit if required."
        case .thisWeek: "Target start this week subject to access, materials, and calendar availability."
        case .thisMonth: "Typical schedule is 2-4 weeks from approval."
        case .flexible: "Flexible scheduling, usually within 4-8 weeks depending on scope."
        }
    }

    private func pricingStructure(for businessType: BusinessType, estimate: Double) -> String {
        switch businessType {
        case .marketingAgency, .freelancer:
            "Fixed project fee from \(estimate.currencyFormatted), with optional monthly support quoted separately."
        case .cleaning:
            "Service package from \(estimate.currencyFormatted), adjusted by property size, frequency, access, and specialist requirements."
        default:
            "Estimated project range from \(estimate.currencyFormatted), subject to measurements, materials, site access, and final scope."
        }
    }

    private func upsells(for businessType: BusinessType) -> [String] {
        switch businessType {
        case .landscaping:
            ["Seasonal maintenance plan", "Premium planting package", "Lighting or irrigation add-on"]
        case .roofing:
            ["Gutter inspection", "Drone roof survey", "Preventative maintenance plan"]
        case .cleaning:
            ["Recurring service plan", "Deep-clean add-on", "Carpet or upholstery treatment"]
        case .plumbing:
            ["System health check", "Emergency cover plan", "Fixture upgrade options"]
        case .electrician:
            ["Safety inspection", "Smart controls", "Consumer unit review"]
        case .propertyServices:
            ["Ongoing maintenance retainer", "Inventory report", "Priority callout support"]
        case .marketingAgency:
            ["Landing page package", "Paid ads setup", "Monthly reporting dashboard"]
        case .freelancer:
            ["Priority turnaround", "Monthly support retainer", "Additional revision package"]
        case .localContractor:
            ["Maintenance plan", "Premium materials option", "Priority scheduling"]
        }
    }

    private func apply(tone: FollowUpTone, to message: String) -> String {
        switch tone {
        case .professional:
            message
        case .friendly:
            "\(message)\n\nHappy to help whenever suits you."
        case .premium:
            "\(message)\n\nWe will keep the process clear, polished, and carefully managed from first estimate to completion."
        case .persuasive:
            "\(message)\n\nThe sooner we confirm the scope, the easier it is to secure the best slot and avoid delays."
        case .urgent:
            "\(message)\n\nIf timing matters, reply today and I will prioritize the next step."
        }
    }
}
