import SwiftData
import SwiftUI

struct VoiceToLeadNotesView: View {
    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService

    @Query private var profiles: [BusinessProfile]

    @State private var speechService = SpeechRecognitionService()
    @State private var viewModel = VoiceNotesViewModel()
    @State private var statusMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !subscriptionService.isActive {
                    UpgradeBanner(feature: "Voice-to-lead conversion is included with Pro and Business plans.")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Voice note")
                        .font(.headline)
                    TextEditor(text: $speechService.transcript)
                        .frame(minHeight: 220)
                        .padding(8)
                        .background(Color.lpSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    HStack {
                        Button {
                            toggleRecording()
                        } label: {
                            Label(speechService.isRecording ? "Stop" : "Record", systemImage: speechService.isRecording ? "stop.circle" : "mic.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(speechService.isRecording ? .red : .lpBlue)

                        Button {
                            Task { await summarize() }
                        } label: {
                            Label("Summarize", systemImage: "sparkles")
                        }
                        .buttonStyle(.bordered)
                        .disabled(speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    }
                }
                .cardStyle()

                if viewModel.isLoading {
                    LoadingOverlay(title: "Converting voice note")
                }

                if let error = speechService.errorMessage ?? viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                if let summary = viewModel.summary {
                    summaryCard(summary)
                }

                DisclaimerBlock()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Voice to Lead")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            Task {
                let allowed = await speechService.requestAuthorization()
                guard allowed else {
                    speechService.errorMessage = "Speech recognition permission is required."
                    return
                }

                do {
                    try speechService.startRecording()
                } catch {
                    speechService.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func summarize() async {
        await viewModel.summarize(
            transcript: speechService.transcript,
            businessType: ProfileResolver.businessType(from: profiles),
            aiService: aiService
        )
        statusMessage = nil
    }

    private func createLead() {
        do {
            _ = try viewModel.createLeadFromSummary(in: modelContext)
            statusMessage = "Lead created from voice note."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func summaryCard(_ summary: VoiceLeadSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI conversion")
                .font(.headline)

            summaryRow(title: "Lead summary", value: summary.leadSummary)
            summaryRow(title: "Quote notes", value: summary.quoteNotes)
            summaryRow(title: "Follow-up tasks", value: summary.followUpTasks)
            summaryRow(title: "CRM notes", value: summary.crmNotes)

            Button {
                createLead()
            } label: {
                Label("Create lead", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.lpGreen)

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.lpGreen)
            }
        }
        .cardStyle()
    }

    private func summaryRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
