import SwiftUI

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(document.title)
                    .font(.largeTitle.bold())

                Text(content)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if document == .aiDisclaimer {
                    DisclaimerBlock()
                }
            }
            .padding()
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: String {
        switch document {
        case .privacyPolicy:
            """
            LeadPilot IQ stores leads, proposals, follow-ups, and analytics locally on this device using SwiftData.

            When mock AI mode is enabled, lead content is processed locally by deterministic mock logic. When remote AI mode is enabled, lead details may be sent to your configured secure backend endpoint. Never place API keys in the iOS app. Configure authentication, logging, retention, and deletion policies on the backend before production release.

            Replace this placeholder with a policy reviewed for your business, region, data processors, and App Store listing.
            """
        case .termsOfUse:
            """
            LeadPilot IQ is a sales productivity tool for organizing enquiries, drafting estimates, creating proposals, and preparing follow-up messages.

            Users remain responsible for final pricing, contracts, promises made to customers, legal compliance, tax handling, and financial decisions. AI-assisted output should be reviewed before it is sent or relied on.

            Replace this placeholder with terms reviewed for your business model, subscription products, and jurisdiction.
            """
        case .aiDisclaimer:
            """
            LeadPilot IQ can generate lead qualification summaries, estimated project values, proposal wording, follow-up messages, and sales insights.

            AI suggestions should be reviewed. Pricing estimates are not guaranteed. Output is not financial advice, not legal advice, and does not guarantee sales, conversions, revenue, or project outcomes.

            The user remains responsible for final pricing, contracts, client communication, and compliance.
            """
        }
    }
}
