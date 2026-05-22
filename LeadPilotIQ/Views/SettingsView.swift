import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService

    @AppStorage("mockAIEnabled") private var mockAIEnabled = AppConstants.mockAIEnabledDefault
    @AppStorage("defaultFollowUpTone") private var defaultFollowUpTone = FollowUpTone.professional.rawValue

    @Query private var profiles: [BusinessProfile]
    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]
    @Query(sort: \FollowUpMessage.createdAt, order: .reverse) private var followUps: [FollowUpMessage]
    @Query(sort: \QualificationResult.createdAt, order: .reverse) private var qualifications: [QualificationResult]

    @State private var shareItem: ShareItem?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Subscription") {
                HStack {
                    Label(subscriptionService.currentPlan.displayName, systemImage: "creditcard")
                    Spacer()
                    if let renewsAt = subscriptionService.renewsAt {
                        Text("Renews \(renewsAt.shortFormatted)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink(value: AppRoute.paywall) {
                    Label("Manage subscription", systemImage: "arrow.up.right.square")
                }
                Button {
                    Task { await subscriptionService.restorePurchases() }
                } label: {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                }
            }

            Section("Business profile") {
                if let profile = ProfileResolver.currentProfile(from: profiles) {
                    BusinessProfileSettings(profile: profile)
                } else {
                    Button {
                        let profile = BusinessProfile(onboardingCompleted: true)
                        modelContext.insert(profile)
                        try? modelContext.save()
                    } label: {
                        Label("Create business profile", systemImage: "building.2")
                    }
                }
            }

            Section("AI and follow-up preferences") {
                Toggle("Mock AI mode", isOn: $mockAIEnabled)
                Picker("Default tone", selection: $defaultFollowUpTone) {
                    ForEach(FollowUpTone.allCases) { tone in
                        Text(tone.displayName).tag(tone.rawValue)
                    }
                }
            }

            Section("Data") {
                Button {
                    exportData()
                } label: {
                    Label("Export data", systemImage: "square.and.arrow.up")
                }
                Text("Local SwiftData storage keeps the app offline-friendly. Remote AI should only be enabled after your secure backend is configured.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Legal") {
                NavigationLink(value: AppRoute.legal(.privacyPolicy)) {
                    Label("Privacy policy", systemImage: "hand.raised")
                }
                NavigationLink(value: AppRoute.legal(.termsOfUse)) {
                    Label("Terms of use", systemImage: "doc.plaintext")
                }
                NavigationLink(value: AppRoute.legal(.aiDisclaimer)) {
                    Label("AI disclaimer", systemImage: "exclamationmark.shield")
                }
            }

            if let errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private func exportData() {
        do {
            let url = try ExportService.exportJSON(
                leads: leads,
                proposals: proposals,
                followUps: followUps,
                qualifications: qualifications
            )
            shareItem = ShareItem(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct BusinessProfileSettings: View {
    @Bindable var profile: BusinessProfile

    var body: some View {
        TextField("Business name", text: $profile.businessName)
            .textInputAutocapitalization(.words)
        Picker("Business type", selection: $profile.businessTypeRaw) {
            ForEach(BusinessType.allCases) { type in
                Text(type.displayName).tag(type.rawValue)
            }
        }
        Picker("Primary goal", selection: $profile.primaryGoalRaw) {
            ForEach(PrimaryGoal.allCases) { goal in
                Text(goal.displayName).tag(goal.rawValue)
            }
        }
        TextField("Proposal branding", text: $profile.brandingName)
        TextField("Proposal footer", text: $profile.proposalFooter, axis: .vertical)
            .lineLimit(2...5)
    }
}
