import SwiftUI

struct SkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<5) { _ in
                SkeletonRow()
            }
        }
        .shimmering()
    }
}

// MARK: - Subviews

private struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.appTextSecondary.opacity(0.15))
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 8) {
                contentPlaceholder(height: 16, width: .infinity)
                contentPlaceholder(height: 12, width: 120)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func contentPlaceholder(height: CGFloat, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.appTextSecondary.opacity(0.15))
            .frame(height: height)
            .frame(maxWidth: width)
    }
}

extension View {
    @ViewBuilder
    func shimmering(active: Bool = true, duration: Double = 1.5, bounce: Bool = false) -> some View {
        if active {
            self.modifier(Shimmer(duration: duration, bounce: bounce))
        } else {
            self
        }
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    var bounce: Bool = false

    func body(content: Content) -> some View {
        content
            .modifier(AnimatedMask(phase: phase).animation(
                Animation.linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
            ))
            .onAppear { phase = 0.8 }
    }

    struct AnimatedMask: AnimatableModifier {
        var phase: CGFloat = 0

        var animatableData: CGFloat {
            get { phase }
            set { phase = newValue }
        }

        func body(content: Content) -> some View {
            content
                .mask(GradientMask(phase: phase).scaleEffect(3))
        }
    }

    struct GradientMask: View {
        let phase: CGFloat

        var body: some View {
            LinearGradient(gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0.3), location: phase),
                .init(color: Color.black, location: phase + 0.1),
                .init(color: Color.black.opacity(0.3), location: phase + 0.2)
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

#Preview {
    SkeletonView()
        .padding()
}
