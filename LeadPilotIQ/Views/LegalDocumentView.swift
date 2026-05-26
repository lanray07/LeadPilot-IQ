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

                if document == .privacyPolicy {
                    Link("Open full Privacy Policy", destination: AppConstants.privacyPolicyURL)
                }

                if document == .termsOfUse {
                    Link("Open Apple Standard Terms of Use (EULA)", destination: AppConstants.termsOfUseURL)
                }

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
            LeadPilot IQ stores leads, proposals, follow-ups, and analytics locally on this device using SwiftData unless you choose to export, share, or transmit information.

            When mock AI mode is enabled, lead content is processed locally by deterministic mock logic. When remote AI mode is enabled, lead details may be sent to your configured secure backend endpoint. Never place API keys in the iOS app. Configure authentication, logging, retention, and deletion policies on the backend before production release.

            LeadPilot IQ may request access to the camera, photo library, microphone, and speech recognition so you can attach photos and convert voice notes into lead notes. Subscription purchases are handled by Apple through StoreKit and the App Store.
            """
        case .termsOfUse:
            """
            LeadPilot IQ is a sales productivity tool for organizing enquiries, drafting estimates, creating proposals, and preparing follow-up messages.

            Users remain responsible for final pricing, contracts, promises made to customers, legal compliance, tax handling, and financial decisions. AI-assisted output should be reviewed before it is sent or relied on.

            LeadPilot IQ uses Apple's Standard End User License Agreement for apps distributed on the App Store. Paid plans are auto-renewable subscriptions managed through your Apple ID and App Store account settings.
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
