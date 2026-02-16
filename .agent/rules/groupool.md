---
trigger: always_on
---

FRONTEND DEVELOPMENT RULES

Platform: iOS (SwiftUI 5.0)
Design System: Apple Human Interface Guidelines (HIG)
Primary Color: SystemTeal (Light Mode: #5AC8FA, Dark Mode: #64D2FF) — Chosen for its association with "Pools," clarity, and distinctness from traditional banking "Navy Blue."

1. Architectural Pattern

MVVM-C (Model-View-ViewModel-Coordinator):

Views must be purely declarative and devoid of business logic.

ViewModels must implement the ObservableObject protocol and handle state transformation.

Coordinators (or a NavigationRouter environment object) must handle all navigation logic. Views never instantiate other full-screen Views directly.

Dependency Injection: All dependencies (NetworkService, formatting logic) must be injected via init or @EnvironmentObject. No Singletons accessed directly inside Views.

2. UI/UX Guidelines (Strict Apple HIG)

Typography: Use Font.TextStyle exclusively (e.g., .headline, .caption, .body). Do not use hardcoded sizes (e.g., .system(size: 14)).

Iconography: Use SF Symbols exclusively.

Components:

Use List for collections.

Use NavigationView / NavigationStack for hierarchy.

Use standard Button styles (.borderedProminent for primary actions).

Dark Mode: All colors and assets must support Dark Mode natively using Color(uiColor:) or Asset Catalog sets.

Haptics: Use UIImpactFeedbackGenerator for all financial confirmations and voting actions.

3. SOLID Implementation in Swift

Single Responsibility: Each View does one thing. If a View exceeds 100 lines, break it into sub-components (e.g., VoteCardView, BalanceHeaderView).

Open/Closed: Use Protocols for service layers. Extensions should add functionality, not modify existing classes.

Liskov Substitution: Protocol types must be interchangeable. A MockPaymentService must function identically to LivePaymentService in tests.

Interface Segregation: Protocols should be small. Prefer Readable and Writeable protocols over a massive DatabaseManager protocol.

Dependency Inversion: High-level modules (ViewModels) must not depend on low-level modules (API Client); both must depend on abstractions (Protocols).

4. Coding Standards (No Comments Policy)

Self-Explanatory Naming:

Bad: func proc()

Good: func processTransactionAndUpdateLedger()

No Comments: If the code requires a comment to explain what it does, rewrite the code. Code should read like English sentences.

Access Control: All properties are private or private(set) by default. Expose only what is necessary.

Error Handling: Never use try? or force unwrap !. Use do-catch blocks and propagate distinct Error enum cases.