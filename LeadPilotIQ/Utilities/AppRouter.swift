import SwiftUI

enum AppRoute: Hashable {
    case addLead
    case leadDetail(UUID)
    case qualification(UUID?)
    case quote(UUID?)
    case followUp(UUID?)
    case voiceNote
    case proposalCenter
    case analytics
    case paywall
    case legal(LegalDocument)
}

enum LegalDocument: String, Hashable, Identifiable {
    case privacyPolicy
    case termsOfUse
    case aiDisclaimer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: "Privacy Policy"
        case .termsOfUse: "Terms of Use"
        case .aiDisclaimer: "AI Disclaimer"
        }
    }
}

extension View {
    func withAppNavigationDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            AppRouteDestination(route: route)
        }
    }
}

private struct AppRouteDestination: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .addLead:
            LeadCaptureView()
        case .leadDetail(let leadID):
            LeadDetailView(leadID: leadID)
        case .qualification(let leadID):
            AIQualificationView(initialLeadID: leadID)
        case .quote(let leadID):
            AIQuoteGeneratorView(initialLeadID: leadID)
        case .followUp(let leadID):
            AIFollowUpGeneratorView(initialLeadID: leadID)
        case .voiceNote:
            VoiceToLeadNotesView()
        case .proposalCenter:
            ProposalCenterView()
        case .analytics:
            AnalyticsDashboardView()
        case .paywall:
            PaywallView()
        case .legal(let document):
            LegalDocumentView(document: document)
        }
    }
}
