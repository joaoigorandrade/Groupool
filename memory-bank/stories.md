Project Board: SwiftUI Frontend (Mock Data Phase)

Phase 1: Project Foundation & Design System

Setting up the architectural backbone and visual identity.

Task 1.1: Project Initialization & Folder Structure

Description: Create the Xcode project targeting iOS 17+ (SwiftUI 5.0). Implement the MVVM-C (Model-View-ViewModel-Coordinator) or standard MVVM folder structure. Groups: Models, Views, ViewModels, Services, Utils, Resources. Expected Result: A clean Xcode project with a logical folder hierarchy that separates concerns effectively.

Task 1.2: Design System & Theming (HIG)

Description: Define the App Theme using Swift Assets and Typography helpers.

Colors: Define semantic colors (AccentColor, PrimaryBackground, SecondaryBackground, FrozenBlue, AvailableGreen, DangerRed, TextPrimary, TextSecondary).
Typography: Create a Font extension with styles (.titleLarge, .bodyBold, .caption) utilizing SF Pro. Expected Result: A reusable styling system ensuring UI consistency across all screens.
Task 1.3: Component Library - Part 1 (Atomic Components)

Description: Create reusable SwiftUI views adhering to HIG.

PrimaryButton: Handles loading states and disabled states.
SecondaryButton: For tertiary actions.
InputField: Standard text field with validation state styling and support for FloatingPointFormatStyle for currency (BRL). Expected Result: A library of UI components ready to be assembled into complex screens.
Task 1.4: Mock Data Models

Description: Create the Swift Codable structs representing the data entities.

User: ID, Name, Avatar, ReputationScore, Status.
Group: ID, Name, TotalPool, Members.
Transaction: ID, Description, Amount, Type (Expense/Withdrawal/Win), Timestamp.
Challenge: ID, Title, BuyIn, Deadline, Status (Active/Voting/Complete).
Vote: ID, TargetID, Type (Approval/Contest), Deadline. Expected Result: A complete data model file reflecting the specification.
Phase 2: Core Navigation & Onboarding

Building the app skeleton and the entry point.

Task 2.1: Main Navigation Container (TabView)

Description: Implement the main TabView container. Use the .toolbar modifier to place the "Central Action Button" (FAB) in the center of the bottom bar (between tabs 2 and 3). Expected Result: A persistent bottom navigation bar with 4 tabs (Dashboard, Ledger, Governance, Profile) and a prominent central "+" button.

Task 2.2: Onboarding - Invite Landing Screen

Description: Build the UI for InviteLandingView.

Header: Large group name.
Card: Inviter name and Buy-in amount (formatted as BRL currency).
The Contract: A stylized list of the 3 immutable rules.
Action: "Connect PIX & Deposit" button. Expected Result: A visually polished screen that simulates the user clicking a deep link. The button currently triggers a mock navigation action.
Task 2.3: Mock Data Service (Singleton)

Description: Create an ObservableObject class called MockDataService. It should hold the current User, Group state, and arrays of Challenge and Transaction. It must provide methods to mutate this state (e.g., addExpense, castVote). Expected Result: A centralized mock backend logic class injected into the SwiftUI environment as an EnvironmentObject.

Phase 3: The Dashboard (Home)

The primary financial view.

Task 3.1: Dashboard - Top Pool Card

Description: Create DashboardView.

Display "Total Pool Value" prominently.
Member Health Row: Use a horizontal stack of circular avatar images. Apply a grayscale filter to inactive members. Expected Result: A card displaying the group's total capital and member status visualization.
Task 3.2: Dashboard - Personal Stake Card

Description: Create a card splitting the user's balance.

Available: Display in Green.
Frozen: Display in Blue (locked in challenges).
Total Equity: Sum of both. Expected Result: A clear financial status card that dynamically updates based on Mock Data state.
Task 3.3: Dashboard - Activity Feed

Description: Create a small vertical list showing the last 3 events.

Row design: Icon + Description + Timestamp relative time.
Navigate to "Ledger" on tap. Expected Result: A "Mini Feed" populated with mock recent transactions.
Phase 4: The Action Hub (FAB Flows)

The core creation mechanisms.

Task 4.1: FAB Action Menu Overlay

Description: Implement a .sheet or .fullScreenCover triggered by the central "+" button.

UI: A modal sheet with three large buttons: Split Expense, Create Challenge, Request Withdrawal.
Dismissal logic on selection. Expected Result: A functional modal menu that routes to the specific creation screens.
Task 4.2: Create Expense Flow

Description: Build CreateExpenseView.

Inputs: Description TextField, Amount TextField (Currency format).
Split Selector: Seged Control (Equal vs Custom).
Validation Logic: Check User.AvailableBalance >= Amount. Expected Result: A form that creates a mock expense, updates the MockDataService, and dismisses upon success.
Task 4.3: Create Challenge Flow

Description: Build CreateChallengeView.

Inputs: Title, Description, Buy-in amount, Deadline (DatePicker).
Logic: Display the calculated "Prize Pool" in real-time.
Validation: Check for "Active Challenge" existence (enforce 1 active challenge limit). Expected Result: A flow that creates a mock challenge and reflects it in the Governance tab.
Task 4.4: Request Withdrawal Flow

Description: Build RequestWithdrawalView.

Input: Amount (pre-filled with max available).
Warning Banner: Show a text warning about the security cooldown/pump & dump protection. Expected Result: A screen that creates a pending withdrawal request in the Governance list.
Phase 5: Governance Center

The voting and conflict resolution engine.

Task 5.1: Governance List View

Description: Build GovernanceView.

List of active votes.
Row UI: Type Icon (Challenge/Withdrawal), Title, and a Countdown Timer (using a Timer publisher to tick down). Expected Result: A list showing all active polls with live countdown timers.
Task 5.2: Challenge Voting Interface

Description: Build ChallengeVotingView.

Display Challenge details and "Proof" placeholder image.
Voting Buttons: "Vote Winner" (Green) and "Abstain" (Gray).
Tie-Breaker Logic UI: A caption explaining the refund rule. Expected Result: An interface where a user can cast a vote. The UI updates to reflect "Vote Cast".
Task 5.3: Withdrawal Integrity Check

Description: Build WithdrawalVotingView.

Header: "User X wants to withdraw R$ X".
Selection: Radio-style buttons for "No (Approve)" and "Yes (Contest)".
Contest Logic: If "Yes" is selected, reveal a dropdown of specific reasons (Pending Debt, Fraud). Expected Result: A binary voting interface with conditional logic for contesting.
Phase 6: Profile & Ledger

Secondary screens and history.

Task 6.1: Ledger (History) View

Description: Build LedgerView.

List of all Transaction objects.
Section Headers: Group by Date (Today, Yesterday, This Month).
Row Detail: Negative numbers (Red) for expenses, Positive (Green) for wins. Expected Result: An immutable chronological record of all money movements.
Task 6.2: Profile View

Description: Build ProfileView.

User Stats: Challenges Won/Lost, Reliability Score (Progress View).
Status Badge: "Good Standing" (Green) or "Restricted" (Yellow).
Settings Links: PIX Keys, App Settings (placeholder). Expected Result: A profile screen displaying the user's reputation stats.
Phase 7: Final Polish & Local Logic

Simulating the backend logic locally.

Task 7.1: Logic - "Frozen Funds" Implementation

Description: Refine the Dashboard logic.

When a user joins a challenge, move that amount from "Available" to "Frozen" in the MockDataService.
When a user tries to Spend/Withdraw, check only the "Available" balance. Expected Result: The UI correctly reflects frozen assets and prevents spending of locked funds.
Task 7.2: Logic - "Antifragile" Validation

Description: Implement the specific validation rules in the ViewModels.

Spam Check: Disable "Create Challenge" button if an active challenge exists in MockDataService.
Cooldown Check: Show a Toast/Alert if user tries to withdraw immediately after a mock "Win". Expected Result: The frontend correctly enforces business rules before any backend exists.
Task 7.3: UI Polish - HIG Compliance & Animations

Description: Review all transitions.

Ensure NavigationStack animations are smooth.
Add haptic feedback (UIImpactFeedbackGenerator) to button presses and voting actions.
Verify Dark Mode support for all components. Expected Result: A professional, fluid app experience ready for backend integration.