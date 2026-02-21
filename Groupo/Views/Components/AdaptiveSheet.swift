import SwiftUI

extension View {
    func adaptiveSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder sheetContent: () -> Content) -> some View {
        modifier(AdaptiveSheetModifier(isPresented: isPresented, sheetContent: sheetContent))
    }
}

struct AdaptiveSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @State private var sheetHeight: CGFloat = 0
    private let sheetContent: SheetContent
    
    init(isPresented: Binding<Bool>, @ViewBuilder sheetContent: () -> SheetContent) {
        self._isPresented = isPresented
        self.sheetContent = sheetContent()
    }
    
    func body(content: Content) -> some View {
        content
            .background(measurementView)
            .sheet(isPresented: $isPresented) {
                sheetContent
                    .presentationDetents([.height(sheetHeight)])
            }
    }
    
    @ViewBuilder
    private var measurementView: some View {
        sheetContent
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .task(id: proxy.size.height) {
                            sheetHeight = proxy.size.height
                        }
                }
            )
            .hidden()
    }
}
