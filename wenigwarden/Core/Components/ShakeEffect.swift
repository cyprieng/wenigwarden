import SwiftUI

/// A custom shake effect that can be applied to a view
struct ShakeEffect: GeometryEffect {
    /// The current position of the shake effect
    var position: CGFloat

    /// The animatable data for the effect, which allows the effect to animate
    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    /// Initializes the shake effect with a given number of shakes
    /// - Parameter shakes: The number of shakes to apply
    init(shakes: Int) {
        position = CGFloat(shakes)
    }

    /// Computes the transformation for the shake effect based on the current position
    /// - Parameter size: The size of the effect
    /// - Returns: The projection transformation to apply the shake effect
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: -15 * sin(position * 2 * .pi), y: 0))
    }
}
