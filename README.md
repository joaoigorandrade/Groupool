# Groupool
# Groupo
Here is the App Architecture and Screen Specification, organized by user journey.

## I. High-Level Navigation Structure

The app uses a Bottom Navigation Bar with 2 core tabs and a Central Action Button:

**Home** (Dashboard + Profile): Group finances, member status, personal stake, and user profile — all in one place, scrollable.

**Activity** (Ledger + Governance): The complete record of what happened (Ledger) and what needs to happen now (Governance), unified under a single tab with a segmented control.

**Central Action Button (FAB):** The "Do" button — Create Expense, Create Challenge, Request Withdrawal.

```
[ Home ]  [ + ]  [ Activity ]
```

---

## II. Detailed Screen Specifications

### 1. Onboarding & Authentication

**Context:** User arrives via a WhatsApp deep link invite. They must identify themselves before seeing anything.

**Screen 1.1: Phone Entry**

- Country code prefix (hardcoded to +55 BR)
- Phone number input field
- "Send Code" button — disabled until 10+ digits entered
- Disclaimer: "We'll send a verification code via SMS"

**Screen 1.2: OTP Verification**

- Masked phone display: "+55 11 9xxxx-9999"
- 6-digit code input (auto-reads from SMS when possible)
- "Verify" button
- Resend countdown timer starting at 30 seconds
- Inline error for wrong codes

**Logic:** Once OTP is verified, session is persisted. Returning users skip directly to the Home tab. First-time users proceed to the Invite Landing.

---

**Screen 1.3: Invite Landing**

Header: "You are joining [Group Name]"

Body:
- Inviter: [Name]
- Buy-in Required: R$ [Amount]
- The Contract (The 3 Rules):
  1. Money stays until approved exit.
  2. Inactive votes count as abstentions.
  3. Deadlines are absolute.

Action: "Connect PIX & Deposit"

**Logic:** System generates a unique PIX Copy/Paste code. User cannot enter without the deposit confirmation. On mock, a 1.5s simulated delay represents the webhook confirmation.

---

### 2. Home Tab (Dashboard + Profile)

**Context:** The main living room and personal headquarters in one scrollable view. Group reality at the top, personal identity at the bottom.

**Screen 2.1: Home**

**Section A — The Group Pool (Top Card)**
- Total Pool Value: R$ 5,000
- Member Health: 5 Active / 2 Inactive (grayed out avatar dots)
- Tapping the member row navigates to the full Member List

**Section B — Personal Stake Card**
- Total Equity: R$ 500
- Available: R$ 300 (Green)
- Frozen: R$ 200 (Blue — locked in active challenges)

**Logic:** "Frozen" balance is visually distinct. It prevents spending on expenses or withdrawals.

**Section C — Active Challenge Card**
- Shows the current active or voting challenge with status badge and time remaining
- Tapping navigates to the full Challenge Voting View
- If no active challenge: shows "No Active Challenge — Tap to create one" with a shortcut to the FAB

**Section D — Recent Activity (Mini Feed)**
- Last 3 transactions with icon, description, relative timestamp
- Tapping any row navigates to the Activity tab

**Section E — Profile Summary**
- Avatar, name, status badge (Good Standing / Restricted / Inactive)
- Stats inline: Challenges Won · Lost · Reliability %
- Links: PIX Keys → App Settings → Log Out

**Logic:** The profile section lives at the bottom of the Home scroll. There is no separate Profile tab. Settings and PIX Keys open as pushed navigation destinations from here.

---

**Screen 2.2: Member List** (pushed from Home)

- Filter bar: All / Active / Inactive
- Sorted by equity descending
- Each row: avatar, name, reputation score, wins, current equity, frozen indicator
- Tapping a row opens Member Detail View

**Screen 2.3: Member Detail View** (pushed from Member List)

- Full stats grid: Reputation, Current Equity, Frozen Balance, Reliability, Won, Lost, Votes Cast

---

### 3. Central FAB — Action Hub

**Context:** User taps the "+" button. A sheet appears with three options.

**Screen 3.1: Action Menu**
- Split Expense
- Create Challenge
- Request Withdrawal

**Screen 3.2: Create Expense**
- Inputs: Description, Amount
- Split Selector: Equal Split (Default) or Custom
- Validation: "This will deduct R$ X from your Available Balance"
- Backend Logic: Checks `User_Available_Balance >= Split_Share`. If false, button is disabled.

**Screen 3.3: Create Challenge**
- Inputs: Title, Description, Buy-in, Deadline (mandatory), Validation Mode
  - "Proof + Voting" (Default)
  - "Voting Only"
- Warning Banner: "By creating this, you are entering a cooling-off period of 48h for new challenges."
- Antifragile Check: Button disabled if another challenge is already active.

**Screen 3.4: Request Withdrawal**
- Large amount input field
- Available balance shown below
- Security Cooldown Banner: shown with countdown if user recently won a challenge
- "Request Withdrawal" button disabled during cooldown or for invalid amounts

---

### 4. Activity Tab (Ledger + Governance)

**Context:** Everything that has happened and everything that needs a decision. Unified under one tab with a segmented control at the top.

```
[ Ledger ]  [ Governance ]
```

**Screen 4.1: Ledger Segment**

- Transactions grouped by date section: Hoje / Ontem / [Month Year]
- Each row: type icon (colored), description, timestamp, formatted amount (+ or -)
- Tapping a row opens Transaction Detail View
- Pull to refresh
- Empty state: "No Transactions — Your financial activity will appear here"

**Screen 4.2: Transaction Detail View** (pushed from Ledger)

- Large icon + description + formatted amount at top
- Detail rows: Date, Type, Transaction ID
- Split breakdown if expense was split across members

---

**Screen 4.3: Governance Segment**

- List of active items sorted by deadline ascending (most urgent first)
- Two item types displayed in the same list:
  - **Challenge** (flag icon, orange): title, time remaining, buy-in badge, progress bar
  - **Withdrawal Request** (arrow icon, blue): "Withdrawal Request", time remaining, progress bar
- Red dot indicator on rows where the current user is eligible to vote and has not yet voted
- Empty state: "No Active Votes — There are no active challenges or withdrawal requests"

**Screen 4.4: Challenge Voting View** (pushed from Governance or Home active challenge card)

- Full challenge detail: title, description, buy-in, prize pool, deadline
- Proof image if submitted
- Status-driven action area:
  - **Active:** Join Challenge button (if not a participant) or Proof upload (if validation mode is proof) or Start Voting button (if voting-only mode)
  - **Voting:** Vote Winner ✓ / Contest ✗ / Abstain buttons. After voting: confirmation state with "Change Vote" option
  - **Complete:** Winner banner with payout amount
  - **Failed:** Failure reason + "Funds refunded" confirmation
- Footer: "If the majority does not vote 'Winner', the buy-in will be refunded."

**Screen 4.5: Withdrawal Voting View** (pushed from Governance)

- User avatar + name + "wants to withdraw" + amount (large)
- Auto-approval countdown timer: "Auto-Approval in 12:00:00 — Default: Approved"
- Decision selector:
  - **Approve** (default) — "Standard withdrawal"
  - **Contest** — "Flag suspicious activity" → reveals reason picker: Pending Debt / Suspicious Activity / Other
- Confirm button color reflects decision (green for approve, orange for contest)
- After voting: confirmation screen with "Return to Activity" button

---

## III. Navigation Map

```
App Launch
├── [No session] → Phone Entry → OTP → Invite Landing → Home
└── [Session found] → Home

Home (Tab 1)
├── Member List → Member Detail
├── Challenge Voting View
└── Profile Section
    ├── PIX Keys
    ├── App Settings (→ Reset Mock Data, Invite Landing Preview)
    └── Log Out (confirmation alert)

FAB (Center)
├── Create Expense (→ Custom Split Sheet)
├── Create Challenge (Step 1 → Step 2)
└── Request Withdrawal

Activity (Tab 2)
├── [Ledger Segment]
│   └── Transaction Detail
└── [Governance Segment]
    ├── Challenge Voting View
    └── Withdrawal Voting View
```

---

## IV. Functional Logic & Antifragile Rules

| Scenario | System Response | UI Feedback |
|---|---|---|
| Inactivity | User fails to vote in 3 consecutive challenges | Status → "Inactive". Removed from quorum calculation |
| Pump & Dump | User wins and immediately requests withdrawal | Cooldown banner with live countdown in withdrawal screen |
| Spamming | User tries to create 2nd challenge while one is active | "Create Challenge" FAB option shows active challenge state instead of form |
| Hostage | Group ignores withdrawal request until deadline | Timer hits 00:00:00. Auto-approved. Transaction appears in Ledger |
| Insufficient Funds | User tries to join challenge with insufficient available balance | Error toast: "Insufficient Available Balance. R$ X is locked in other challenges" |
| Tie Vote | Challenge vote ends in a tie | Status → Failed. Failure reason shown in challenge view. Refund transaction in Ledger |
| No Votes Cast | Nobody votes before deadline | Status → Failed. "No votes cast. Funds refunded." |

---

## V. WhatsApp Bot Integration Flow

The bot is the "Town Crier," not the "Judge."

| Event | Bot Message |
|---|---|
| Challenge Created | "🔥 New Challenge: '10k Run' by @User. Buy-in: R$ 50. [DeepLink]" |
| Proof Uploaded | "📸 Proof In: @User submitted proof for '10k Run'. [DeepLink]" |
| Voting Warning | "⏳ 1 Hour Left: 3 members haven't voted. Silence = Abstention. [DeepLink]" |
| Money Movement | "💸 Payout: @User won R$ 150. Congratulations!" |
| Auto-Approval | "✅ Withdrawal auto-approved for @User after timeout." |

---

## VI. Growth Control Parameters

| Parameter | Phase 1 (Default) | Phase 3 (Mature) |
|---|---|---|
| Max Active Challenges | 1 | 3 |
| Vote Window Duration | 24h fixed | Dynamic per group size |
| Withdrawal Cooldown | 48h hardcoded | Configurable |
| Quorum Threshold | 50% participation | Configurable |


Here is the complete, step-by-step user onboarding flow for Groupool, incorporating the deferred deep linking, optimized OTP strategy, and the financial commitment step.

This flow maps out exactly what the user sees and what the system does behind the scenes to ensure a frictionless, secure entry.

Phase 0: The Origin (Outside the App)

Everything starts in the WhatsApp group where the trust and context already exist.

Creation: The "Host" (User A) interacts with the Groupool WhatsApp Bot to create a new pool. They define the group name, buy-in amount, and rules.

The Link: The backend creates the group entity and generates a unique Deferred Deep Link (e.g., groupool.app/join/xyz-789).

The Share: The Bot sends a formatted message into the WhatsApp group containing the invite link.

Phase 1: The Gateway (Routing & Installation)

A group member (User B) taps the link in the WhatsApp chat.

Scenario A (App Installed): The mobile OS intercepts the deep link and immediately opens Groupool. The app captures the unique payload (xyz-789).

Scenario B (App Not Installed): The link routes User B to the App Store or Google Play. They download and open the app. Upon this first launch, the Deferred Deep Linking SDK (like AppsFlyer or Branch) securely retrieves the pending payload (xyz-789) that the user clicked prior to installation.

Phase 2: Identity & Authentication (Screens 1.1 & 1.2)

The app now knows where the user is trying to go, but needs to know who they are.

Screen 1.1 (Phone Entry): * UI: The screen acknowledges the intent context: "Welcome! Enter your number to join." The country code is hardcoded to +55 (BR).

Action: User enters their 10+ digit number and taps "Send Code".

System Logic: The backend registers the phone number request and generates a 6-digit OTP. It prioritizes sending this via the WhatsApp Business API (cheaper, faster, and keeps them in their current context). If the WhatsApp delivery fails or times out, it falls back to a standard SMS.

Screen 1.2 (OTP Verification):

UI: Displays the masked number ("+55 11 9xxxx-9999").

Action: User inputs the 6-digit code. (On Android/KMP and iOS, use native SMS autofill APIs to read the code automatically if it arrived via SMS).

System Logic: The backend validates the code. If successful, it issues a persistent JWT session token. The user is now permanently authenticated on this device.

Phase 3: Authorization & The Buy-in (Screen 1.3)

The user is authenticated, but they are not yet a member of the pool. They must put "skin in the game."

Screen 1.3 (Invite Landing):

UI: The screen dynamically populates based on the deep link payload captured in Phase 1.

Header: "You are joining [Group Name]"

Body: Inviter: [Name] | Buy-in Required: R$ [Amount]

The Contract: Displays the 3 absolute rules (Money stays until exit, Inactive votes = abstention, Deadlines are absolute).

Action: User taps "Connect PIX & Deposit".

System Logic: The backend generates a dynamic, single-use PIX Copia e Cola payload specific to this user and this group's buy-in amount.

Payment Execution: The user copies the code, switches to their banking app, and pays.

The Webhook: Groupool listens for the payment gateway webhook confirming the PIX settlement. (For your mock environment, tapping a "Simulate Payment" button triggers a 1.5-second loading spinner to represent this webhook).

Group Addition: Once the webhook fires, the backend officially binds the user's ID to the Group ID and credits their initial equity.

Phase 4: The Destination (Screen 2.1)

The onboarding is complete, and the user drops directly into the core experience.

Screen 2.1 (Home Dashboard):

The user lands on the Home tab.

They immediately see the Total Pool Value incremented by their deposit.

Their avatar appears in the Member Health row.

Their Personal Stake Card lights up in green, showing their available balance (e.g., R$ 50).

Edge Case: The "Organic" Download (Orphan Flow)

What happens if someone downloads the app directly from the store without clicking a WhatsApp invite link?

They open the app. There is no deferred deep link payload to capture.

They go through Phase 2 (Phone Entry & OTP) normally to authenticate.

Because there is no group invite context, the app skips Phase 3 (The Buy-in) entirely.

They land on an Empty State Home Screen.

UI: "You aren't in any pools yet."

Action 1: "Create a Pool via WhatsApp" -> Deep links the user out to the Groupool WhatsApp Bot to start Phase 0.

Action 2: "Have an invite code?" -> Opens a manual input field where they can paste the xyz-789 code if they somehow lost the link but have the text.