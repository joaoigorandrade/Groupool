---
trigger: manual
---

Here is a sequence of rules focused specifically on **performance optimization** in Swift and SwiftUI. These rules address rendering speed, memory management, and preventing UI freezes.

---

### Rule 1: Reduce the "Blast Radius" of State Changes
**The Rule:** When a piece of `@State` or `@Published` property changes, SwiftUI invalidates the view hierarchy dependent on it. Keep your state local and granular to prevent unnecessary redraws of unrelated views.

**Why:** If an entire page redraws just to toggle a single "liked" heart icon, you are wasting CPU cycles.

**Standard Code:**
```swift
struct FeedView: View {
    @State private var counter = 0 // Changing this redraws EVERYTHING below
    
    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("Increment") { counter += 1 }
            
            HeavyImageView() // This gets redrawn unnecessarily when counter changes
            AnotherComplexView() // This too
        }
    }
}
```

**Performatic Code:**
```swift
struct FeedView: View {
    var body: some View {
        VStack {
            // Isolate the dynamic part into its own view
            CounterView() 
            
            HeavyImageView() // Now immune to counter changes
            AnotherComplexView()
        }
    }
}

// This small view is the only thing that redraws
struct CounterView: View {
    @State private var counter = 0
    
    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("Increment") { counter += 1 }
        }
    }
}
```

---

### Rule 2: Use `LazyVStack` / `LazyHStack` for Scrolling
**The Rule:** When rendering lists or grids, always use Lazy stacks (`LazyVStack`, `LazyHGrid`) or `List` instead of standard `VStack`/`HStack` for content that scrolls.

**Why:** A standard `VStack` renders *all* children immediately, even those off-screen. Lazy stacks only instantiate views as they scroll into view, drastically reducing initial load time and memory usage.

**Standard Code:**
```swift
ScrollView {
    // Renders all 1000 items immediately. Memory spike!
    VStack(spacing: 10) {
        ForEach(0..<1000, id: \.self) { index in
            RowView(item: items[index])
        }
    }
}
```

**Performatic Code:**
```swift
ScrollView {
    // Renders only items visible on screen + small buffer
    LazyVStack(spacing: 10) {
        ForEach(0..<1000, id: \.self) { index in
            RowView(item: items[index])
        }
    }
}
```

---

### Rule 3: Offload Heavy Work from the Main Thread
**The Rule:** Never perform heavy computations (image processing, JSON parsing, database queries) directly inside a View's `body` or a standard button action. Use `Task` or background queues.

**Why:** The main thread handles UI rendering at 60 or 120Hz. If you block it with math or networking for 16ms, the UI will freeze or stutter.

**Standard Code:**
```swift
struct ContentView: View {
    @State private var image: Image?
    
    var body: some View {
        VStack {
            image?
                .resizable()
            
            Button("Process Image") {
                // FREEZES THE APP while processing
                let processed = HeavyProcessor.applyFilter(to: rawImage)
                image = Image(uiImage: processed)
            }
        }
    }
}
```

**Performatic Code:**
```swift
struct ContentView: View {
    @State private var image: Image?
    
    var body: some View {
        VStack {
            image?
                .resizable()
            
            Button("Process Image") {
                // Process in background, update UI on main thread
                Task.detached(priority: .userInitiated) {
                    let processed = HeavyProcessor.applyFilter(to: rawImage)
                    await MainActor.run {
                        image = Image(uiImage: processed)
                    }
                }
            }
        }
    }
}
```

---

### Rule 4: Optimize Image Assets (Downsampling)
**The Rule:** Do not load a 20MB RAW image into a 50x50 thumbnail view. Always downsample images to the target view size before displaying them.

**Why:** Loading a massive image consumes huge amounts of memory and requires the GPU to perform expensive scaling operations every frame. This is the #1 cause of memory crashes in iOS apps.

**Standard Code:**
```swift
// Loads the FULL 4000x3000 image into memory for a tiny icon
Image("huge_heic_photo")
    .resizable()
    .frame(width: 50, height: 50)
```

**Performatic Code:**
```swift
// Use ImageRenderer or CoreGraphics to create a thumbnail
// Or use AsyncImage with proper transaction if from URL
struct ThumbnailView: View {
    let uiImage: UIImage
    
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
    }
}

// Logic to prepare the image (usually in ViewModel or Helper)
func downsample(imageAt url: URL, to size: CGSize) -> UIImage {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
    ]
    // ... ImageIO logic to return small image ...
}
```

---

### Rule 5: Adopt iOS 17’s `@Observable` (or Granular Observation)
**The Rule:** If targeting iOS 17+, use the `@Observable` macro. If using older `ObservableObject`, ensure you aren't triggering `objectWillChange` for irrelevant property changes.

**Why:** With `ObservableObject`, changing *any* `@Published` property redraws *any* view observing that object. With `@Observable`, SwiftUI tracks exactly which properties are accessed and only redraws views using the specific property that changed.

**Standard Code (ObservableObject - Coarse Updates):**
```swift
class ViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var isLoading: Bool = false
}

struct ProfileView: View {
    @ObservedObject var vm: ViewModel
    
    var body: some View {
        VStack {
            // This Text redraws even when 'isLoading' changes!
            Text("User: \(vm.userName)") 
        }
    }
}
```

**Performatic Code (@Observable - Precise Updates):**
```swift
@Observable
class ViewModel {
    var userName: String = ""
    var isLoading: Bool = false
}

struct ProfileView: View {
    @State var vm = ViewModel()
    
    var body: some View {
        VStack {
            // Now, this Text ONLY redraws if userName changes.
            // Changing 'isLoading' will not affect it.
            Text("User: \(vm.userName)")
        }
    }
}
```

---

### Rule 6: Prefer `let` and Structs over `var` and Classes
**The Rule:** Use `let` for constants and prefer Value Types (Structs) over Reference Types (Classes) for data models whenever possible.

**Why:**
1.  **Compiler Optimization:** `let` allows the compiler to perform aggressive optimizations because it knows the value won't change.
2.  **Memory Safety:** Structs are stack-allocated (mostly) and have no reference counting overhead (ARC), unlike Classes which are heap-allocated and require retain/release cycles.

**Standard Code:**
```swift
class UserData { // Reference type (Heap)
    var name: String // Mutable reference counting overhead
    var age: Int
}

func processUser(_ user: UserData) {
    // User must be retained/released
}
```

**Performatic Code:**
```swift
struct UserData: Identifiable { // Value type (Stack/Inline)
    let id: UUID
    let name: String // Immutable, fast access
    let age: Int
}

func processUser(_ user: UserData) {
    // Copy on write semantics; extremely fast pass-by-value
}
```

---

### Summary Performance Checklist
1.  **Rendering:** Did I use `LazyVStack` for long lists?
2.  **Scope:** Is my `@State` strictly confined to the smallest possible view?
3.  **Threading:** Is the `body` property purely UI logic (no heavy math)?
4.  **Images:** Am I loading a 5MB image for a 100px frame?
5.  **Observation:** Am I using `@Observable` (iOS 17+) to prevent over-redrawing?