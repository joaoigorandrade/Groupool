import SwiftUI
import PhotosUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @EnvironmentObject var mockDataService: MockDataService
    
    var body: some View {
        ScrollView {
            ChallengeDetailContent(challenge: challenge)
                .padding()
        }
        .navigationTitle("Challenge Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChallengeDetailContent: View {
    let challenge: Challenge
    @EnvironmentObject var mockDataService: MockDataService
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isSubmitting = false
    
    // Resolve participants from IDs
    private var participants: [User] {
        mockDataService.currentGroup.members.filter { challenge.participants.contains($0.id) }
    }
    
    private var winner: User? {
        guard challenge.status == .complete, let winnerID = challenge.proofSubmissionUserID else { return nil }
        return mockDataService.currentGroup.members.first(where: { $0.id == winnerID })
    }
    
    private var prizePool: Decimal {
        challenge.buyIn * Decimal(challenge.participants.count)
    }
    
    private var isParticipant: Bool {
        challenge.participants.contains(mockDataService.currentUser.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            
            Divider()
            
            infoSection
            
            if !participants.isEmpty {
                participantsSection
            }
            
            if let proof = challenge.proofImage, !proof.isEmpty {
                proofSection(proof: proof)
            } else if challenge.status == .active && isParticipant && (challenge.validationMode ?? .proof) == .proof {
                // Only show upload section if active, user is participant, no proof yet, AND mode is proof
                uploadSection
            }
            
            if challenge.status == .complete {
                resultsSection
            } else if challenge.status == .failed {
                 failedSection
            }
        }
    }
}

// MARK: - Subviews
private extension ChallengeDetailContent {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(challenge.title)
                    .font(.title)
                    .bold()
                    .lineLimit(2)
                
                Spacer()
                
                statusBadge
            }
            
            Text(challenge.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    var statusBadge: some View {
        Text(challenge.status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    var statusColor: Color {
        switch challenge.status {
        case .active: return .blue
        case .voting: return .orange
        case .complete: return .green
        case .failed: return .red
        }
    }
    
    var infoSection: some View {
        VStack(spacing: 16) {
            HStack {
                detailRow(icon: "dollarsign.circle.fill", title: "Buy-In", value: challenge.buyIn.formatted(.currency(code: "BRL")))
                Spacer()
                detailRow(icon: "trophy.fill", title: "Prize Pool", value: prizePool.formatted(.currency(code: "BRL")))
            }
            
            HStack {
                detailRow(icon: "calendar", title: "Deadline", value: challenge.deadline.formatted(date: .abbreviated, time: .shortened))
                Spacer()
            }
        }
    }
    
    func detailRow(icon: String, title: String, value: String) -> some View {
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
    
    var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(participants) { participant in
                        VStack(spacing: 8) {
                            Image(systemName: participant.avatar) // Using SF Symbol as avatar for now based on MockData
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(participant.name.split(separator: " ").first ?? "")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 60)
                    }
                }
            }
        }
    }
    
    var uploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submit Proof")
                .font(.headline)
            
            VStack(spacing: 16) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    
                    Button(action: submitProof) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send Proof")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSubmitting)
                    
                    Button("Change Photo") {
                        selectedItem = nil
                        selectedImage = nil
                    }
                    .font(.subheadline)
                    .disabled(isSubmitting)
                    
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
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
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
    
    func proofSection(proof: String) -> some View {
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
    
    var resultsSection: some View {
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
                    
                    if let winner = winner {
                        Text(winner.name)
                            .font(.title3)
                            .bold()
                        Text("Won \(prizePool.formatted(.currency(code: "BRL")))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unknown")
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    var failedSection: some View {
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
    
    func submitProof() {
        guard let image = selectedImage else { return }
        isSubmitting = true
        
        // Convert to base64
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            isSubmitting = false
            return
        }
        let base64String = imageData.base64EncodedString()
        
        // Submit
        mockDataService.submitProof(challengeID: challenge.id, image: base64String)
        
        isSubmitting = false
    }
}

#Preview("Active") {
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
        .environmentObject(MockDataService.preview)
    }
}

#Preview("Completed") {
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
        .environmentObject(MockDataService.preview)
    }
}

#Preview("Dark Mode") {
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
        .environmentObject(MockDataService.preview)
        .preferredColorScheme(.dark)
    }
}

