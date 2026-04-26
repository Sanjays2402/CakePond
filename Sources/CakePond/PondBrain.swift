import Foundation

struct PondMood: Equatable {
    let name: String
    let subtitle: String
    let hueShift: Double
    let sparkleRate: Double

    static let moods: [PondMood] = [
        PondMood(name: "Focus", subtitle: "quiet ripples for deep work", hueShift: 0.58, sparkleRate: 0.18),
        PondMood(name: "Chaos", subtitle: "tiny comet storm, very scientific", hueShift: 0.86, sparkleRate: 0.78),
        PondMood(name: "Cozy", subtitle: "warm lights, soft pond", hueShift: 0.07, sparkleRate: 0.32),
        PondMood(name: "Party", subtitle: "confetti koi unlocked", hueShift: 0.74, sparkleRate: 0.95)
    ]
}

struct Koi: Identifiable, Equatable {
    let id: Int
    let radius: Double
    let speed: Double
    let phase: Double
    let hue: Double
}

struct Bubble: Identifiable, Equatable {
    let id: Int
    let x: Double
    let delay: Double
    let size: Double
    let wobble: Double
}

struct PondBrain {
    static func koi(count: Int) -> [Koi] {
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            Koi(
                id: index,
                radius: 72 + Double(index % 5) * 24,
                speed: 0.18 + Double(index % 4) * 0.045,
                phase: Double(index) * 0.71,
                hue: (0.04 + Double(index) * 0.11).truncatingRemainder(dividingBy: 1)
            )
        }
    }

    static func bubbles(count: Int) -> [Bubble] {
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            Bubble(
                id: index,
                x: 0.08 + (Double((index * 37) % 84) / 100.0),
                delay: Double(index % 9) / 9.0,
                size: 4 + Double((index * 11) % 18),
                wobble: Double((index * 17) % 32) - 16
            )
        }
    }

    static func compliment(for taps: Int) -> String {
        switch taps {
        case 0: return "Tap the pond to feed the sparkle koi."
        case 1...3: return "The koi approves of your keyboard aura."
        case 4...7: return "Tiny pond status: emotionally overclocked."
        case 8...13: return "You have summoned a responsible amount of chaos."
        default: return "The pond now considers you senior sparkle engineer."
        }
    }
}
