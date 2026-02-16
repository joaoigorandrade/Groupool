import SwiftUI
import Combine

final class ContentViewModel: ObservableObject {
    @Published private(set) var title: String = "Groupo"
}
