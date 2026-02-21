import SwiftUI
import PhotosUI
import Observation

@Observable
class ChallengeDetailViewModel {
    let challenge: Challenge
    private let services: AppServiceContainer
    
    var selectedItem: PhotosPickerItem? = nil {
        didSet {
            handleSelectedItemChange()
        }
    }
    var selectedImage: UIImage? = nil
    var isSubmitting = false
    var errorMessage: String?
    
    var prizePool: Decimal {
        challenge.buyIn * Decimal(challenge.participants.count)
    }
    
    var statusColor: Color {
        switch challenge.status {
        case .active: return .blue
        case .voting: return .orange
        case .complete: return .green
        case .failed: return .red
        }
    }
    
    init(challenge: Challenge, services: AppServiceContainer) {
        self.challenge = challenge
        self.services = services
    }
    
    func handleSelectedItemChange() {
        guard let selectedItem else { return }
        Task {
            if let data = try? await selectedItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = uiImage
                }
            }
        }
    }
    
    @MainActor
    func submitProof() async {
        guard let image = selectedImage else { return }
        isSubmitting = true
        
        let imageData = await Task.detached(priority: .userInitiated) {
            image.jpegData(compressionQuality: 0.5)
        }.value
        
        guard let data = imageData else {
            isSubmitting = false
            return
        }
        
        do {
            try await services.challengeService.submitProof(challengeID: challenge.id, imageData: data)
            HapticManager.notificationSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

struct ChallengeDetailView: View {
    let challenge: Challenge
    @Environment(\.services) var services
    @State private var viewModel: ChallengeDetailViewModel?
    
    var body: some View {
        content
            .navigationTitle("Challenge Details")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel == nil {
                    viewModel = ChallengeDetailViewModel(challenge: challenge, services: services)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if let viewModel = viewModel {
            ScrollView {
                ChallengeDetailContent(viewModel: viewModel)
                    .padding()
            }
        } else {
            ProgressView()
        }
    }
}

struct ChallengeDetailContent: View {
    let viewModel: ChallengeDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ChallengeHeaderSection(challenge: viewModel.challenge, statusColor: viewModel.statusColor)
            
            Divider()
            
            ChallengeInfoSection(challenge: viewModel.challenge, prizePool: viewModel.prizePool)
            
            if !viewModel.challenge.participants.isEmpty {
                ChallengeParticipantsSection(participantCount: viewModel.challenge.participants.count)
            }
            
            ChallengeProofOrUploadSection(viewModel: viewModel)
            
            ChallengeStatusResultSection(challenge: viewModel.challenge, prizePool: viewModel.prizePool)
        }
    }
}

// MARK: - Subviews

private struct ChallengeHeaderSection: View {
    let challenge: Challenge
    let statusColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(challenge.title)
                    .font(.title)
                    .bold()
                    .lineLimit(2)
                
                Spacer()
                
                StatusBadge(status: challenge.status.rawValue, color: statusColor)
            }
            
            Text(challenge.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

private struct StatusBadge: View {
    let status: String
    let color: Color
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

private struct ChallengeInfoSection: View {
    let challenge: Challenge
    let prizePool: Decimal
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                DetailRow(icon: "dollarsign.circle.fill", title: "Buy-In", value: challenge.buyIn.formatted(.currency(code: "BRL")))
                Spacer()
                DetailRow(icon: "trophy.fill", title: "Prize Pool", value: prizePool.formatted(.currency(code: "BRL")))
            }
            
            HStack {
                DetailRow(icon: "calendar", title: "Deadline", value: challenge.deadline.formatted(date: .abbreviated, time: .shortened))
                Spacer()
            }
        }
    }
}

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.callout)
                    .fontWeight(.medium)
            }
        }
    }
}

private struct ChallengeParticipantsSection: View {
    let participantCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants (\(participantCount))")
                .font(.headline)
            
            Text("Participant details will be shown when connected to live services.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct ChallengeProofOrUploadSection: View {
    var viewModel: ChallengeDetailViewModel
    
    var body: some View {
        @ViewBuilder
        var view: some View {
            if let proof = viewModel.challenge.proofImage, !proof.isEmpty {
                ProofDisplayView(proof: proof)
            } else if viewModel.challenge.status == .active && (viewModel.challenge.validationMode ?? .proof) == .proof {
                ProofUploadView(viewModel: viewModel)
            }
        }
        
        return view
    }
}

private struct ProofDisplayView: View {
    let proof: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proof")
                .font(.headline)
            
            if let data = Data(base64Encoded: proof),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

private struct ProofUploadView: View {
    var viewModel: ChallengeDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submit Proof")
                .font(.headline)
            
            VStack(spacing: 16) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    
                    Button(action: {
                        Task {
                            await viewModel.submitProof()
                        }
                    }) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Proof")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSubmitting)
                    
                    Button("Change Photo") {
                        viewModel.selectedItem = nil
                        viewModel.selectedImage = nil
                    }
                    .font(.subheadline)
                    .disabled(viewModel.isSubmitting)
                    
                } else {
                    PhotosPicker(selection: Binding(
                        get: { viewModel.selectedItem },
                        set: { viewModel.selectedItem = $0 }
                    ), matching: .images) {
                        Label("Select Photo", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

private struct ChallengeStatusResultSection: View {
    let challenge: Challenge
    let prizePool: Decimal
    
    var body: some View {
        @ViewBuilder
        var view: some View {
            if challenge.status == .complete {
                ResultsView(prizePool: prizePool)
            } else if challenge.status == .failed {
                FailedView()
            }
        }
        
        return view
    }
}

private struct ResultsView: View {
    let prizePool: Decimal
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 16) {
                Image(systemName: "flag.checkered")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Winner")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Won \(prizePool.formatted(.currency(code: "BRL")))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

private struct FailedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text("Challenge Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Refunds issued")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview("Active") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        ChallengeDetailView(challenge: Challenge(
            id: UUID(),
            title: "Mock Challenge",
            description: "Description of the mock challenge.",
            buyIn: 50,
            createdDate: Date(),
            deadline: Date().addingTimeInterval(86400),
            participants: [],
            status: .active
        ))
        .environment(\.services, services)
    }
}

#Preview("Completed") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        ChallengeDetailView(challenge: Challenge(
            id: UUID(),
            title: "Completed Challenge",
            description: "Challenge finished.",
            buyIn: 50,
            createdDate: Date().addingTimeInterval(-86400),
            deadline: Date().addingTimeInterval(-3600),
            participants: [],
            status: .complete
        ))
        .environment(\.services, services)
    }
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        ChallengeDetailView(challenge: Challenge(
            id: UUID(),
            title: "Mock Challenge",
            description: "Description of the mock challenge.",
            buyIn: 50,
            createdDate: Date(),
            deadline: Date().addingTimeInterval(86400),
            participants: [],
            status: .active
        ))
        .environment(\.services, services)
        .preferredColorScheme(.dark)
    }
}
