import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upgrade LeadPilot IQ")
                        .font(.largeTitle.bold())
                    Text("Unlock unlimited leads, AI qualification, proposal generation, PDF exports, voice-to-lead conversion, and advanced analytics.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PlanCard(
                    plan: .free,
                    title: SubscriptionPlan.free.displayName,
                    price: SubscriptionPlan.free.pricePlaceholder,
                    isCurrent: subscriptionService.currentPlan == .free,
                    features: [
                        "20 leads/month",
                        "Basic quotes",
                        "Limited AI follow-ups",
                        "LeadPilot IQ branding"
                    ],
                    actionTitle: "Current starter plan",
                    action: {}
                )

                ForEach(SubscriptionPlan.paidPlans) { plan in
                    PlanCard(
                        plan: plan,
                        title: subscriptionService.product(for: plan)?.displayName ?? plan.displayName,
                        price: subscriptionService.product(for: plan)?.displayPrice ?? plan.pricePlaceholder,
                        isCurrent: subscriptionService.currentPlan == plan,
                        features: features(for: plan),
                        actionTitle: subscriptionService.currentPlan == plan ? "Active" : "Choose \(plan.displayName)",
                        action: {
                            Task { await subscriptionService.purchase(plan) }
                        }
                    )
                }

                Button {
                    Task { await subscriptionService.restorePurchases() }
                } label: {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if subscriptionService.isLoading {
                    LoadingOverlay(title: "Checking subscription")
                }

                if let error = subscriptionService.errorMessage {
                    ErrorBanner(message: error)
                }

                SubscriptionLegalFooter()
                DisclaimerBlock()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscriptionService.loadProducts()
        }
    }

    private func features(for plan: SubscriptionPlan) -> [String] {
        switch plan {
        case .free:
            []
        case .proMonthly, .proYearly:
            [
                "Unlimited leads",
                "AI qualification scoring",
                "AI proposal generator",
                "AI follow-ups",
                "Voice-to-lead conversion",
                "Analytics dashboard",
                "PDF exports",
                "Pipeline tracking"
            ]
        case .businessMonthly:
            [
                "Everything in Pro",
                "Team workflow placeholder",
                "Advanced analytics",
                "Custom branding",
                "Multi-user placeholder",
                "CRM integration placeholder"
            ]
        }
    }
}

private struct PlanCard: View {
    var plan: SubscriptionPlan
    var title: String
    var price: String
    var isCurrent: Bool
    var features: [String]
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                    Text(price)
                        .font(.headline)
                        .foregroundStyle(Color.lpBlue)
                    Text("Length: \(plan.subscriptionLength)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(plan.renewalSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isCurrent {
                    StatusPill(title: "Current", systemImage: "checkmark.seal", color: .lpGreen)
                }
            }

            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: action) {
                Text(actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCurrent ? .secondary : .lpBlue)
            .disabled(isCurrent || plan == .free)
        }
        .cardStyle()
    }
}

private struct SubscriptionLegalFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subscription information")
                .font(.headline)
            Text("Payment is charged to your Apple ID at confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Renewal is charged within 24 hours before the end of the current period. You can manage or cancel subscriptions in your App Store account settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: AppConstants.privacyPolicyURL)
                Link("Terms of Use (EULA)", destination: AppConstants.termsOfUseURL)
            }
            .font(.caption.bold())
        }
        .cardStyle()
    }
}
