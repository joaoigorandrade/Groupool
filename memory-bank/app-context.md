Here is the App Architecture and Screen Specification, organized by user journey.

I. High-Level Navigation Structure

The app uses a Bottom Navigation Bar with 4 key tabs within a specific Group context:

Dashboard (Home): Balances, Members, and Status.

Ledger (History): The immutable record of money movement.

Governance (Votes): Active polls, challenges, and withdrawal requests.

Profile (Settings): PIX keys, Reputation Score, App Settings.

Central Action Button (FAB): The "Do" button (Create Expense, Challenge, Withdrawal).

II. Detailed Screen Specifications

1. Onboarding & Group Entry (The Bridge)

Context: User clicks a deep link from the WhatsApp Bot.

Screen 1.1: The Invite Landing

Header: "You are joining [Group Name]"

Body:

Inviter: [Name]

Buy-in Required: R$ [Amount]

The Contract (The 3 Rules):

Money stays until approved exit.

Inactive votes count as abstentions.

Deadlines are absolute.

Action: "Connect PIX & Deposit"

Logic: System generates a unique PIX Copy/Paste code. User cannot enter without the deposit confirmation webhook firing.

2. The Dashboard (Group Home)

Context: The main living room. Must show financial reality instantly.

Screen 2.1: Main Dashboard

Top Card (The Pool):

Total Pool Value: R$ 5,000

Member Health: 5 Active / 2 Inactive (Grayed out dots)

Personal Card (Your Stake):

Total Equity: R$ 500

Available: R$ 300 (Green)

Frozen: R$ 200 (Blue - locked in active challenges)

Activity Feed (Mini): Last 3 events (Expense paid, Challenge started).

Logic: "Frozen" balance is visually distinct. It prevents the user from spending that money on expenses or withdrawing it.

3. The Action Hub (Central FAB)

Context: User taps the "+" button.

Screen 3.1: The Menu Overlay

Option A: Split Expense (Pays immediate bills).

Option B: Create Challenge (Gamified coordination).

Option C: Request Withdrawal (Exit ramp).

Screen 3.2: Create Expense

Input: Description ("Friday Beers"), Amount.

Split Selector: Equal Split (Default) or Custom.

Validation Message: "This will deduct R$ X from your Available Balance."

Backend Logic: Checks User_Available_Balance >= Split_Share. If false, button is disabled.

Screen 3.3: Create Challenge (The Core Loop)

Inputs:

Title & Description.

Prize Pool: (Calculated automatically based on buy-in).

Buy-in per person: R$ 50.

Deadline: (Date/Time picker - mandatory).

Validation Mode:

"Proof + Voting" (Default).

"Voting Only."

Antifragile Check: "By creating this, you are entering a cooling-off period of 48h for new challenges."

4. Governance Center (The "Courtroom")

Context: Where conflict is resolved by time and code.

Screen 4.1: Active Votes

List View:

Challenge: Pushups (Ends in 04:32:10)

Withdrawal: User_X (Ends in 12:00:00)

Visual Urgency: Progress bars showing time remaining.

Screen 4.2: Challenge Voting Interface

Content:
*
*

Action: "Vote Winner" or "Abstain".

Logic:

Self-voting disabled if participants < 3.

Tie-Breaker UI: "If a tie persists at [Time], funds are refunded."

Screen 4.3: Withdrawal Integrity Check

Header: "User X wants to withdraw R$ 100."

Prompt: "Is there a valid reason to block this?"

[ ] No (Approve) - Default Selection

[ ] Yes (Contest) -> Must select from specific list:

"Pending Debt"

"Fraud Suspicion"

(Note: No "I don't like them" option).

Logic: If no votes are cast by deadline -> Auto-Approve.

5. Profile & Reputation

Context: Long-term game incentives.

Screen 5.1: User Profile

Stats:

Challenges Won/Lost.

Reliability Score: (Based on voting participation).

Status:

"Good Standing" (Green).

"Restricted" (Yellow - e.g., on cooldown).

III. Functional Logic & "Antifragile" Backend

This is how the app handles the specific edge cases you defined.

Scenario	System Response (Backend Logic)	UI Feedback
Inactivity	User fails to vote in 3 consecutive challenges.	Profile status changes to "Inactive." Future voting weight reduced or removed from quorum calculation.
Pump & Dump	User wins huge pot and immediately hits "Withdraw."	Error Toast: "Security Cooldown active. You can withdraw in 24 hours."
Spamming	User tries to create 2nd challenge while one is active.	Button Disabled. Tooltip: "Only one active challenge per group allowed."
Hostage	Group ignores a withdrawal request.	Timer hits 00:00:00. System auto-executes PIX transfer to user. Bot posts: "Withdrawal auto-approved due to timeout."
Insufficient Funds	User tries to join a R$ 50 challenge but has R$ 30 available (and R$ 100 frozen).	Error: "Insufficient Available Balance. R$ 100 is currently locked in other challenges."
IV. WhatsApp Bot Integration Flow

The bot is the "Town Crier," not the "Judge."

Event: Challenge Created in App

Bot: "🔥 New Challenge: '10k Run' created by @User. Buy-in: R$ 50. Link to Join: [DeepLink]"

Event: Proof Uploaded

Bot: "📸 Proof In: @User submitted proof for '10k Run'. Check it here: [DeepLink]"

Event: Voting Deadline Warning

Bot: "⏳ 1 Hour Left: 3 members haven't voted. Silence = Abstention. Vote now: [DeepLink]"

Event: Money Movement

Bot: "💸 Payout: @User won R$ 150. Congratulations!"

V. Growth Control Mechanics (The "Scale" Strategy)

To handle the "Phase 1 to Phase 3" transition, the app needs a System Configuration backend panel (for the super-admin):

Parameter 1: Max_Active_Challenges (Starts at 1, scales to 3 for mature groups).

Parameter 2: Vote_Window_Duration (Fixed at 24h initially, dynamic for larger groups).

Parameter 3: Cooldown_Timer (Hardcoded 48h initially).