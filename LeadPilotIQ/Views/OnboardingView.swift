import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BusinessProfile]

    @State private var businessType: BusinessType = .localContractor
    @State private var primaryGoal: PrimaryGoal = .qualifyLeadsFaster
    @State private var businessName = ""

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppConstants.appName)
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.lpCharcoal)
                        Text("Qualify leads, build quotes, and follow up faster from one mobile-first workspace.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Business profile")
                            .font(.headline)
                        TextField("Business name", text: $businessName)
                            .textInputAutocapitalization(.words)
                        Picker("Business type", selection: $businessType) {
                            ForEach(BusinessType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        Picker("Primary goal", selection: $primaryGoal) {
                            ForEach(PrimaryGoal.allCases) { goal in
                                Text(goal.displayName).tag(goal)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.lpSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    DisclaimerBlock()

                    Button {
                        saveProfile()
                        onComplete()
                    } label: {
                        Label("Start qualifying leads", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.lpBlue)
                }
                .padding()
            }
            .navigationTitle("Welcome")
        }
    }

    private func saveProfile() {
        let profile = profiles.first ?? BusinessProfile()
        profile.businessName = businessName
        profile.businessType = businessType
        profile.primaryGoal = primaryGoal
        profile.onboardingCompleted = true

        if profiles.isEmpty {
            modelContext.insert(profile)
        }

        try? modelContext.save()
    }
}
