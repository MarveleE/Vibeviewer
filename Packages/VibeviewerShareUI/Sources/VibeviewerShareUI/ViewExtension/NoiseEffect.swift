import SwiftUI
import Foundation

public extension View {
    func noiseEffect(seed: Float, frequency: Float, amplitude: Float) -> some View {
        self.modifier(NoiseEffectModifier(seed: seed, frequency: frequency, amplitude: amplitude))
    }
}

public struct NoiseEffectModifier: ViewModifier {
    var seed: Float
    var frequency: Float
    var amplitude: Float

    public init(seed: Float, frequency: Float, amplitude: Float) {
        self.seed = seed
        self.frequency = frequency
        self.amplitude = amplitude
    }

    public func body(content: Content) -> some View {
        content
            .colorEffect(ShaderLibrary.parameterizedNoise(.float(seed), .float(frequency), .float(amplitude)))
    }
}