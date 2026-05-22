import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct LeadCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = LeadFormViewModel()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showCamera = false

    var body: some View {
        Form {
            Section("Lead") {
                TextField("Lead name", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                TextField("Phone", text: $viewModel.phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section("Enquiry") {
                TextField("Service requested", text: $viewModel.serviceRequested)
                TextField("Budget range", text: $viewModel.budgetRange)
                TextField("Location", text: $viewModel.location)
                Picker("Urgency", selection: $viewModel.urgency) {
                    ForEach(LeadUrgency.allCases) { urgency in
                        Text(urgency.displayName).tag(urgency)
                    }
                }
                Picker("Source", selection: $viewModel.source) {
                    ForEach(LeadSource.allCases) { source in
                        Text(source.displayName).tag(source)
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 130)
            }

            Section("Photos") {
                HStack {
                    PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 8, matching: .images) {
                        Label("Add photos", systemImage: "photo.on.rectangle")
                    }
                    Spacer()
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }

                if !viewModel.photoDrafts.isEmpty {
                    PhotoThumbnailGrid(drafts: viewModel.photoDrafts)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    ErrorBanner(message: error)
                }
            }
        }
        .navigationTitle("Add Lead")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!viewModel.canSave)
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await loadPhotos(from: newItems)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                if let data = image.jpegData(compressionQuality: 0.82) {
                    viewModel.photoDrafts.append(LeadPhotoDraft(imageData: data))
                }
            }
        }
    }

    private func save() {
        do {
            _ = try viewModel.save(in: modelContext)
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               !viewModel.photoDrafts.contains(where: { $0.imageData == data }) {
                viewModel.photoDrafts.append(LeadPhotoDraft(imageData: data))
            }
        }
        selectedPhotoItems = []
    }
}
