import SwiftUI

public extension View {
    func rippleEffect(at origin: CGPoint, isRunning: Bool, interval: TimeInterval) -> some View {
        self.modifier(RippleEffect(at: origin, isRunning: isRunning, interval: interval))
    }
}

@MainActor
struct RippleEffect: ViewModifier {
    var origin: CGPoint
    
    var isRunning: Bool
    var interval: TimeInterval
    
    @State private var tick: Int = 0
    
    init(at origin: CGPoint, isRunning: Bool, interval: TimeInterval) {
        self.origin = origin
        self.isRunning = isRunning
        self.interval = interval
    }
    
    func body(content: Content) -> some View {
        let origin = origin
        let animationDuration = animationDuration
        
        return content
            .keyframeAnimator(
                initialValue: 0,
                trigger: tick
            ) { view, elapsedTime in
                view.modifier(RippleModifier(
                    origin: origin,
                    elapsedTime: elapsedTime,
                    duration: animationDuration
                ))
            } keyframes: { _ in
                MoveKeyframe(0)
                CubicKeyframe(animationDuration, duration: animationDuration)
            }
            .task(id: isRunning ? interval : -1.0) {
                guard isRunning else { return }
                while !Task.isCancelled && isRunning {
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    if isRunning {
                        tick &+= 1
                    }
                }
            }
    }
    
    var animationDuration: TimeInterval { 3 }
}

struct RippleModifier: ViewModifier {
    var origin: CGPoint
    
    var elapsedTime: TimeInterval
    
    var duration: TimeInterval
    
    var amplitude: Double = 12
    var frequency: Double = 15
    var decay: Double = 8
    var speed: Double = 1200
    
    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )
        
        let maxSampleOffset = maxSampleOffset
        let elapsedTime = elapsedTime
        let duration = duration
        
        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }
    
    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

struct NoiseEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}