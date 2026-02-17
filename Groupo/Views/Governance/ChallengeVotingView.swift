import SwiftUI
import PhotosUI

struct ChallengeVotingView: View {
    let challenge: Challenge
    @StateObject private var viewModel = GovernanceViewModel()
    @EnvironmentObject var mockDataService: MockDataService
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var proofImageString: String?
    @State private var hasUserVoted = false
    
    private var currentChallenge: Challenge {
        mockDataService.challenges.first(where: { $0.id == challenge.id }) ?? challenge
    }
    
    private var isParticipant: Bool {
        currentChallenge.participants.contains(mockDataService.currentUser.id)
    }
    
    private var isCreator: Bool {
        currentChallenge.participants.first == mockDataService.currentUser.id
    }
    
    private var hasProofBeenSubmitted: Bool {
        if let proof = currentChallenge.proofImage {
            return !proof.isEmpty
        }
        return false
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                Divider()
                statusContent
                footerSection
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setService(mockDataService)
        }
        .onChange(of: selectedItem) { _, newItem in
            processPhotoSelection(newItem)
        }
    }
}

// MARK: - Subviews
private extension ChallengeVotingView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentChallenge.title)
                .font(.title)
                .bold()
                .padding(.top)
            
            Text(currentChallenge.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    var statusContent: some View {
        switch currentChallenge.status {
        case .active:
            activePhaseView
        case .voting:
            votingPhaseView
        case .complete:
            completedPhaseView
        case .failed:
            EmptyView()
        }
    }
    
    var footerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text("If the majority does not vote 'Winner', the buy-in will be refunded.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Active Phase Views
private extension ChallengeVotingView {
    @ViewBuilder
    var activePhaseView: some View {
        VStack(spacing: 16) {
            if isParticipant {
                participantUploadView
            } else {
                joinChallengeView
            }
        }
    }
    
    var participantUploadView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submit Your Proof")
                .font(.headline)
            
            if let selectedImage {
                imagePreviewView(image: selectedImage)
            } else {
                imagePickerView
            }
        }
    }
    
    func imagePreviewView(image: Image) -> some View {
        VStack(spacing: 16) {
            image
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            HStack(spacing: 12) {
                Button(action: submitProof) {
                    Text("Submit & Start Voting")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: clearSelection) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    var imagePickerView: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "camera")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Tap to Upload Proof")
                                .foregroundColor(.blue)
                        }
                    )
            }
            
            Button(action: submitProofWithoutImage) {
                Text("Start Voting Without Proof")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }
    
    var joinChallengeView: some View {
        VStack(spacing: 12) {
            Text("Join this challenge to participate")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: joinChallenge) {
                Text("Join Challenge")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Text("Buy-in: \(currentChallenge.buyIn.formatted(.currency(code: "BRL")))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Voting Phase Views
private extension ChallengeVotingView {
    @ViewBuilder
    var votingPhaseView: some View {
        VStack(spacing: 24) {
            if isParticipant {
                if hasUserVoted {
                    voteConfirmationView
                } else {
                    votingControlsView
                }
            } else {
                Text("Only participants can vote")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    var votingControlsView: some View {
        if hasProofBeenSubmitted {
            proofDisplayView
        } else {
            Text("No proof was submitted for this challenge.")
                .italic()
                .foregroundColor(.secondary)
                .padding(.vertical)
        }
        
        Divider()
        
        votingButtons
    }
    
    var proofDisplayView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Submitted Proof")
                .font(.headline)
            
            if let proof = currentChallenge.proofImage,
               let data = Data(base64Encoded: proof),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
        }
    }
    
    var voteConfirmationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Vote Cast")
                .font(.title2)
                .bold()
            
            Text("You can change your vote until the deadline.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Change Vote") {
                withAnimation {
                    hasUserVoted = false
                }
            }
            .font(.headline)
            .padding(.top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    var votingButtons: some View {
        VStack(spacing: 12) {
            Text("Cast Your Vote")
                .font(.headline)
            
            Button(action: { vote(.approval) }) {
                Text("Vote Winner ✓")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: { vote(.abstain) }) {
                Text("Abstain")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            
            if isCreator {
                Button(action: simulateResolution) {
                    Text("Simulate Resolution (Demo)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top)
                }
            }
        }
    }
}

// MARK: - Completed Phase Views
private extension ChallengeVotingView {
    var completedPhaseView: some View {
        VStack(spacing: 16) {
            if hasProofBeenSubmitted {
                proofDisplayView
            }
            
            VStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Challenge Complete")
                    .font(.title2)
                    .bold()
                
                Text("Results will be displayed here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Helper Methods
private extension ChallengeVotingView {
    func processPhotoSelection(_ newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = Image(uiImage: uiImage)
                    self.proofImageString = data.base64EncodedString()
                }
            }
        }
    }
    
    func clearSelection() {
        withAnimation {
            selectedItem = nil
            selectedImage = nil
            proofImageString = nil
        }
    }
    
    func submitProof() {
        viewModel.submitProof(challenge: currentChallenge, image: proofImageString)
        HapticManager.impact(style: .heavy)
        clearSelection()
    }
    
    func submitProofWithoutImage() {
        viewModel.submitProof(challenge: currentChallenge, image: nil)
        HapticManager.impact(style: .medium)
    }
    
    func joinChallenge() {
        viewModel.joinChallenge(challenge: currentChallenge)
        HapticManager.impact(style: .medium)
    }
    
    func vote(_ type: Vote.VoteType) {
        viewModel.castVote(challenge: currentChallenge, type: type)
        withAnimation {
            hasUserVoted = true
        }
        HapticManager.impact(style: .medium)
    }
    
    func simulateResolution() {
        viewModel.resolveChallenge(challenge: currentChallenge)
    }
}

#Preview {
    NavigationView {
        ChallengeVotingView(challenge: Challenge(
            id: UUID(),
            title: "Mock Challenge",
            description: "Description of the mock challenge.",
            buyIn: 50,
            deadline: Date().addingTimeInterval(3600),
            participants: [],
            status: .active
        ))
        .environmentObject(MockDataService())
    }
}
