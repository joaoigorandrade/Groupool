---
trigger: manual
---

Here is a sequence of rules designed to guide you from basic structure to advanced architecture. Each rule includes an explanation of **why** it matters and a comparison of **"Standard"** vs. **"Well-Written"** code.

---

### Rule 1: The Single Responsibility Principle (Decomposition)
**The Rule:** A SwiftUI View struct should fit on one screen. If it becomes too long, break it down into smaller, private subviews or extraction functions.

**Why:** Large views are hard to debug, slow to compile, and difficult to read. SwiftUI re-renders the entire `body`; keeping bodies small improves performance.

**Standard Code:**
```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            // 50 lines of header logic
            Image("avatar")
            Text("Name")
            // ... 
            
            // 30 lines of statistics logic
            HStack { /* ... */ }
            
            // 40 lines of bio text
            Text("Bio...")
        }
    }
}
```

**Well-Written Code:**
```swift
struct ProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProfileHeaderView() // Extracted logic
            ProfileStatisticsView() // Extracted logic
            ProfileBioView() // Extracted logic
        }
        .padding()
    }
}

// MARK: - Subviews
private extension ProfileView {
    struct ProfileHeaderView: View {
        var body: some View {
            // concise, readable code
        }
    }
}
```

---

### Rule 2: Logic belongs in View Models (MVVM Pattern)
**The Rule:** The `body` property should strictly contain layout and view hierarchy. Business logic, data formatting, and API calls should live in an `ObservableObject` (ViewModel).

**Why:** Separating logic from UI makes code testable (you can unit test the ViewModel without running the UI) and makes the view code readable.

**Standard Code:**
```swift
struct WeatherView: View {
    @State private var temperature: Double = 0.0
    
    var body: some View {
        let celsius = (temperature - 32) * 5/9 // Logic in View
        Text("Temp: \(celsius)")
    }
}
```

**Well-Written Code:**
```swift
struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        Text("Temp: \(viewModel.temperatureCelsius)")
    }
}

class WeatherViewModel: ObservableObject {
    @Published var temperatureFahrenheit: Double = 0.0
    
    var temperatureCelsius: Double {
        (temperatureFahrenheit - 32) * 5/9
    }
}
```

---

### Rule 3: Hoist State Upwards
**The Rule:** Prefer passing data down (`let` properties) and events up (`closures` or `Bindings`) rather than managing state deep inside child views.

**Why:** This creates a "Single Source of Truth." When data is centralized, it prevents bugs where two parts of your app show different data for the same thing.

**Standard Code:**
```swift
struct ParentView: View {
    var body: some View {
        VStack {
            // Child manages its own state internally
            ChildCounterView() 
            Text("Parent doesn't know the count")
        }
    }
}

struct ChildCounterView: View {
    @State private var count = 0 // Hidden state
    // ...
}
```

**Well-Written Code:**
```swift
struct ParentView: View {
    @State private var count = 0 // Parent owns the truth
    
    var body: some View {
        VStack {
            Text("Total count: \(count)")
            ChildCounterView(count: $count) // Pass control down
        }
    }
}

struct ChildCounterView: View {
    @Binding var count: Int
    
    var body: some View {
        Button("Increment") { count += 1 }
    }
}
```

---

### Rule 4: Use Custom ViewModifiers for Styling
**The Rule:** If you repeat the same set of modifiers (fonts, colors, paddings) across multiple views, extract them into a custom `ViewModifier` or extension.

**Why:** It reduces boilerplate code and ensures design consistency. If your brand color changes, you update it in one place.

**Standard Code:**
```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Title")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            Text("Subtitle")
                .font(.headline) // Repeated styling
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
    }
}
```

**Well-Written Code:**
```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Title").cardStyle()
            Text("Subtitle").cardStyle()
        }
    }
}

// Reusable Extension
extension View {
    func cardStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.blue)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
    }
}
```

---

### Rule 5: Modifier Order Matters (and should be logical)
**The Rule:** Apply modifiers in a logical order: **Layout $\to$ Style $\to$ Accessibility/Interaction**. Understand that order changes results (e.g., padding before background vs. padding after background).

**Why:** Incorrect ordering is a common source of layout bugs. Logical grouping makes it easier to scan the code.

**Standard Code:**
```swift
Text("Hello")
    .background(Color.red) // Frame not set yet, background hugs text
    .frame(width: 100, height: 100)
    .padding() // Padding outside the frame
```

**Well-Written Code:**
```swift
Text("Hello")
    // 1. Layout
    .frame(width: 100, height: 100)
    
    // 2. Style
    .background(Color.red) // Fills the frame
    .cornerRadius(8)
    
    // 3. Accessibility/Extras
    .padding() // Adds space around the styled component
    .accessibilityLabel("Greeting label")
```

---

### Rule 6: Leverage Previews for Iteration
**The Rule:** Use `#Preview` (Xcode 15+) to define multiple states of your view (e.g., Loading, Error, Dark Mode, RTL). Do not rely solely on the simulator.

**Why:** It speeds up development drastically and ensures your view handles edge cases gracefully.

**Well-Written Code:**
```swift
struct ProfileView: View {
    // ... view definition ...
}

#Preview("Standard") {
    ProfileView()
}

#Preview("Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
}

#Preview("Error State") {
    ProfileView(user: nil) // Assuming it handles optional user
}
```

Rule 7: Never use Group

```swift
    struct ActivityCalendarLink: View {
        let ledgerViewModel: LedgerViewModel
        let governanceViewModel: GovernanceViewModel
        
        var body: some View {
            Group {
                if !ledgerViewModel.isLoading {
                    TransactionCalendarView(
                        summaries: ledgerViewModel.dailySummaries,
                        size: governanceViewModel.activeItems.isEmpty ? .full : .half
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    SkeletonView()
                        .frame(maxWidth: .infinity, minHeight: 160)
                }
            }
        }
    }
```

**Well-Written Code:**
```swift
    struct ActivityCalendarLink: View {
        let ledgerViewModel: LedgerViewModel
        let governanceViewModel: GovernanceViewModel
        
        var body: some View {
            view
                .frame(maxWidth: .infinity)
        }
        
        @ViewBuilder
        private var view: some View {
            if !ledgerViewModel.isLoading {
                TransactionCalendarView(
                    summaries: ledgerViewModel.dailySummaries,
                    size: governanceViewModel.activeItems.isEmpty ? .full : .half
                )
            } else {
                SkeletonView()
            }
        }
    }

```

---

### Summary Checklist
If you are reviewing your code, check against this list:

1.  **Readability:** Can I understand the hierarchy in 5 seconds?
2.  **Responsibility:** Is this view doing logic that belongs in a ViewModel?
3.  **Reusability:** Am I copy-pasting modifiers that could be a custom style?
4.  **State:** Is the "Source of Truth" clear and located as high up the tree as necessary?
5.  **Safety:** Does this view handle optional data safely (e.g., showing skeletons or error messages)?