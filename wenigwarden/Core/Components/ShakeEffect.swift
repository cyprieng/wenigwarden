import SwiftUI

/// A custom shake effect that can be applied to a view
struct ShakeEffect: GeometryEffect {
    /// The current position of the shake effect
    private var position: CGFloat

    /// The animatable data for the effect, which allows the effect to animate
    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    /// The amplitude of the shake effect
    private let amplitude: CGFloat = 15

    /// Initializes the shake effect with a given number of shakes
    /// - Parameter shakes: The number of shakes to apply
    init(shakes: Int) {
        self.position = CGFloat(shakes)
    }

    /// Computes the transformation for the shake effect based on the current position
    /// - Parameter size: The size of the effect
    /// - Returns: The projection transformation to apply the shake effect
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: -amplitude * sin(position * 2 * .pi),
            y: 0
        ))
    }
}
