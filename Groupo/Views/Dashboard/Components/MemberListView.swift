import SwiftUI

struct MemberListView: View {
    @State private var viewModel: MemberListViewModel
    
    init(
        groupService: any GroupServiceProtocol,
        challengeService: any ChallengeServiceProtocol
    ) {
        _viewModel = State(wrappedValue: MemberListViewModel(
            groupService: groupService,
            challengeService: challengeService
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            filterSection
                .padding(.vertical, 12)
                .background(Color("PrimaryBackground"))
            
            Divider()
            
            if viewModel.isLoading {
                SkeletonView()
                    .padding()
                Spacer()
            } else if viewModel.filteredMembers.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "person.2.slash",
                    description: Text(emptyDescription)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredMembers) { member in
                            NavigationLink(destination: MemberDetailView(member: member, viewModel: viewModel)) {
                                MemberRow(member: member, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                            Divider()
                                .padding(.leading, 76) 
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(Color("PrimaryBackground"))
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var filterSection: some View {
        HStack(spacing: 4) {
             ForEach(MemberListViewModel.UserStatusFilter.allCases) { filter in
                 FilterButton(
                     title: filter.rawValue,
                     isSelected: viewModel.selectedStatus == filter,
                     action: { viewModel.selectedStatus = filter }
                 )
             }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyTitle: String {
        switch viewModel.selectedStatus {
        case .active: return "No Active Members"
        case .inactive: return "No Inactive Members"
        case .all: return "No Members Found"
        }
    }
    
    private var emptyDescription: String {
        switch viewModel.selectedStatus {
        case .active: return "There are no members currently active in this group."
        case .inactive: return "There are no inactive members at this time."
        case .all: return "This group has no members yet."
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primary.opacity(0.1) : Color.clear)
                )
        }
    }
}

struct MemberRow: View {
    let member: User
    let viewModel: MemberListViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            avatarView
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 6) {
                    Text(member.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if member.status != .active {
                        Text(member.status.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    Label("\(member.reputationScore)", systemImage: "star.fill")
                        .foregroundStyle(.secondary)
                    
                    Label("\(member.challengesWon)W", systemImage: "trophy.fill")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            
            Spacer()
            
            equityInfo
        }
        .padding(16)
        .contentShape(Rectangle())
    }
    
    private var avatarView: some View {
        Image(systemName: member.avatar)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 44, height: 44)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                if member.status == .active {
                    Circle()
                        .fill(Color.green)
                        .stroke(Color("PrimaryBackground"), lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
    }
    
    private var equityInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(member.currentEquity.formatted(.currency(code: "BRL")))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.primary)
            
            if viewModel.isFrozen(member: member) {
                HStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                    Text(viewModel.getFrozenAmount(for: member).formatted(.currency(code: "BRL")))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}


#Preview("Populated") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        MemberListView(
            groupService: services.groupService,
            challengeService: services.challengeService
        )
        .environmentObject(services)
    }
}

#Preview("Empty") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        MemberListView(
            groupService: services.groupService,
            challengeService: services.challengeService
        )
        .environmentObject(services)
    }
}

#Preview("Dark Mode") {
    let services = AppServiceContainer.preview()
    NavigationStack {
        MemberListView(
            groupService: services.groupService,
            challengeService: services.challengeService
        )
        .environmentObject(services)
    }
    .preferredColorScheme(.dark)
}
