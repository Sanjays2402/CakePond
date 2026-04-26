import SwiftUI
import AppKit

@main
struct CakePondApp: App {
    @StateObject private var state = PondState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 980, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Pond") {
                Button("Feed Sparkles") { state.feed() }
                    .keyboardShortcut("f")
                Button("Random Mood") { state.randomMood() }
                    .keyboardShortcut("r")
                Divider()
                Button("Reset Pond") { state.reset() }
                    .keyboardShortcut("0")
            }
        }
    }
}

final class PondState: ObservableObject {
    @Published var moodIndex = 0
    @Published var taps = 0
    @Published var sparkles: [Sparkle] = []
    @Published var showOrbitGrid = true

    let koi = PondBrain.koi(count: 9)
    let bubbles = PondBrain.bubbles(count: 34)

    var mood: PondMood { PondMood.moods[moodIndex] }
    var compliment: String { PondBrain.compliment(for: taps) }

    func feed(at point: CGPoint? = nil) {
        taps += 1
        let base = point ?? CGPoint(x: Double.random(in: 180...780), y: Double.random(in: 160...520))
        let batch = (0..<12).map { i in
            Sparkle(
                id: UUID(),
                x: base.x + Double.random(in: -54...54),
                y: base.y + Double.random(in: -42...42),
                size: Double.random(in: 4...11),
                hue: (mood.hueShift + Double(i) * 0.045).truncatingRemainder(dividingBy: 1),
                spin: Double.random(in: -18...18)
            )
        }
        sparkles.append(contentsOf: batch)
        if sparkles.count > 110 { sparkles.removeFirst(sparkles.count - 110) }
    }

    func randomMood() {
        moodIndex = Int.random(in: 0..<PondMood.moods.count)
        feed()
    }

    func reset() {
        taps = 0
        sparkles.removeAll()
        moodIndex = 0
    }
}

struct Sparkle: Identifiable, Equatable {
    let id: UUID
    let x: Double
    let y: Double
    let size: Double
    let hue: Double
    let spin: Double
}

struct ContentView: View {
    @EnvironmentObject private var state: PondState
    @State private var time: Double = 0
    @State private var pulse = false

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RaycastBackground(mood: state.mood, time: time)
                PondCanvas(time: time, size: geo.size)
                    .environmentObject(state)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in state.feed(at: value.location) }
                    )

                VStack(spacing: 0) {
                    HeaderBar()
                    Spacer()
                    BottomDeck(pulse: pulse)
                        .environmentObject(state)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 26)
                }
            }
            .onReceive(timer) { _ in
                time += 1.0 / 30.0
                pulse.toggle()
            }
        }
    }
}

struct RaycastBackground: View {
    let mood: PondMood
    let time: Double

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.027, green: 0.031, blue: 0.039), Color(red: 0.006, green: 0.007, blue: 0.010)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(hue: mood.hueShift, saturation: 0.70, brightness: 0.82).opacity(0.28), .clear],
                center: UnitPoint(x: 0.28 + 0.05 * sin(time / 4), y: 0.18 + 0.05 * cos(time / 5)),
                startRadius: 0,
                endRadius: 520
            )
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.39, blue: 0.39).opacity(0.16), .clear],
                center: UnitPoint(x: 0.86, y: 0.78),
                startRadius: 0,
                endRadius: 420
            )
            StripeField()
                .opacity(0.24)
        }
        .ignoresSafeArea()
    }
}

struct StripeField: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 42
            for i in stride(from: -size.height, through: size.width + size.height, by: spacing) {
                path.move(to: CGPoint(x: i, y: size.height))
                path.addLine(to: CGPoint(x: i + size.height, y: 0))
            }
            context.stroke(path, with: .color(Color(red: 1.0, green: 0.39, blue: 0.39).opacity(0.22)), lineWidth: 1)
        }
        .blendMode(.screen)
    }
}

struct HeaderBar: View {
    @EnvironmentObject private var state: PondState

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Circle().fill(.red.opacity(0.9)).frame(width: 12, height: 12)
                Circle().fill(.yellow.opacity(0.9)).frame(width: 12, height: 12)
                Circle().fill(.green.opacity(0.9)).frame(width: 12, height: 12)
            }
            .padding(.trailing, 8)

            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.39, blue: 0.39))

            Text("Cake Pond")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("⌘F feed · ⌘R random mood")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.38))

            Spacer()

            Toggle(isOn: $state.showOrbitGrid) {
                Text("Orbit grid")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.horizontal, 18)
        .frame(height: 54)
        .background(.black.opacity(0.18))
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.06)).frame(height: 1) }
    }
}

struct PondCanvas: View {
    @EnvironmentObject private var state: PondState
    let time: Double
    let size: CGSize

    var body: some View {
        ZStack {
            if state.showOrbitGrid {
                OrbitGrid(time: time, mood: state.mood)
                    .transition(.opacity)
            }

            ForEach(state.bubbles) { bubble in
                BubbleView(bubble: bubble, time: time, size: size)
            }

            ForEach(state.koi) { koi in
                KoiView(koi: koi, mood: state.mood, time: time, bounds: size)
            }

            ForEach(state.sparkles) { sparkle in
                SparkleView(sparkle: sparkle, time: time)
                    .position(x: sparkle.x, y: sparkle.y)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: state.moodIndex)
        .animation(.easeInOut(duration: 0.28), value: state.showOrbitGrid)
    }
}

struct OrbitGrid: View {
    let time: Double
    let mood: PondMood

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.52, y: size.height * 0.48)
            for ring in 0..<7 {
                let r = CGFloat(70 + ring * 48) + CGFloat(sin(time + Double(ring)) * 3)
                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.035 + Double(ring) * 0.004)), lineWidth: 1)
            }
            var rays = Path()
            for ray in 0..<24 {
                let angle = (Double(ray) / 24.0) * .pi * 2 + time * 0.045
                let start = CGPoint(x: center.x + CGFloat(cos(angle) * 40), y: center.y + CGFloat(sin(angle) * 40))
                let end = CGPoint(x: center.x + CGFloat(cos(angle) * 420), y: center.y + CGFloat(sin(angle) * 420))
                rays.move(to: start)
                rays.addLine(to: end)
            }
            context.stroke(rays, with: .color(Color(hue: mood.hueShift, saturation: 0.7, brightness: 0.95).opacity(0.045)), lineWidth: 1)
        }
    }
}

struct BubbleView: View {
    let bubble: Bubble
    let time: Double
    let size: CGSize

    var body: some View {
        let progress = (time * 0.06 + bubble.delay).truncatingRemainder(dividingBy: 1)
        let x = size.width * bubble.x + sin(time * 1.8 + bubble.delay * 10) * bubble.wobble
        let y = size.height * (1.05 - progress * 1.16)
        Circle()
            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            .background(Circle().fill(.white.opacity(0.025)))
            .frame(width: bubble.size, height: bubble.size)
            .position(x: x, y: y)
            .blur(radius: 0.2)
    }
}

struct KoiView: View {
    let koi: Koi
    let mood: PondMood
    let time: Double
    let bounds: CGSize

    var body: some View {
        let center = CGPoint(x: bounds.width * 0.52, y: bounds.height * 0.49)
        let angle = time * koi.speed + koi.phase
        let rx = koi.radius * 1.55
        let ry = koi.radius * 0.92
        let x = center.x + cos(angle) * rx
        let y = center.y + sin(angle) * ry
        let rotation = Angle(radians: angle + .pi / 2)

        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: (koi.hue + mood.hueShift).truncatingRemainder(dividingBy: 1), saturation: 0.62, brightness: 1.0),
                            Color(red: 1.0, green: 0.39, blue: 0.39),
                            .white.opacity(0.88)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 52, height: 18)
                .shadow(color: Color(hue: mood.hueShift, saturation: 0.8, brightness: 0.8).opacity(0.38), radius: 18)
            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 7, height: 7)
                .offset(x: 15, y: -3)
            Triangle()
                .fill(Color(hue: (koi.hue + mood.hueShift + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.74, brightness: 0.92).opacity(0.88))
                .frame(width: 16, height: 18)
                .offset(x: -30)
                .rotationEffect(.degrees(sin(time * 5 + koi.phase) * 14))
        }
        .rotationEffect(rotation)
        .position(x: x, y: y)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SparkleView: View {
    let sparkle: Sparkle
    let time: Double

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: sparkle.size + 8, weight: .semibold))
            .foregroundStyle(Color(hue: sparkle.hue, saturation: 0.70, brightness: 1.0))
            .shadow(color: Color(hue: sparkle.hue, saturation: 0.8, brightness: 1.0).opacity(0.9), radius: 12)
            .rotationEffect(.degrees(time * sparkle.spin * 3))
            .scaleEffect(0.82 + 0.28 * sin(time * 4 + sparkle.spin))
            .opacity(0.78)
            .allowsHitTesting(false)
    }
}

struct BottomDeck: View {
    @EnvironmentObject private var state: PondState
    let pulse: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 8) {
                    Text("LIVE TOY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundStyle(Color(red: 1.0, green: 0.39, blue: 0.39))
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                        .shadow(color: .green.opacity(0.75), radius: pulse ? 9 : 4)
                }

                Text("A tiny ambient koi pond for your Mac.")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(state.compliment)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .contentTransition(.numericText())

                HStack(spacing: 10) {
                    Button(action: { state.feed() }) {
                        Label("Feed Sparkles", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(PondButtonStyle(primary: true))

                    Button(action: { state.randomMood() }) {
                        Label("Random Mood", systemImage: "shuffle")
                    }
                    .buttonStyle(PondButtonStyle(primary: false))
                }
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
            .background(GlassPanel(radius: 24))

            VStack(spacing: 12) {
                ForEach(Array(PondMood.moods.enumerated()), id: \.offset) { index, mood in
                    Button(action: { state.moodIndex = index; state.feed() }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hue: mood.hueShift, saturation: 0.72, brightness: 0.95))
                                .frame(width: 12, height: 12)
                                .shadow(color: Color(hue: mood.hueShift, saturation: 0.8, brightness: 0.95).opacity(0.8), radius: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mood.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(mood.subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.42))
                            }
                            Spacer()
                            if state.moodIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(red: 1.0, green: 0.39, blue: 0.39))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(state.moodIndex == index ? .white.opacity(0.08) : .white.opacity(0.025))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(state.moodIndex == index ? 0.14 : 0.06), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .frame(width: 330)
            .background(GlassPanel(radius: 24))
        }
    }
}

struct PondButtonStyle: ButtonStyle {
    let primary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(primary ? Color(red: 0.09, green: 0.10, blue: 0.10) : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(primary ? .white.opacity(configuration.isPressed ? 0.88 : 0.98) : .white.opacity(configuration.isPressed ? 0.10 : 0.055))
                    .overlay(Capsule().stroke(.white.opacity(primary ? 0.16 : 0.10), lineWidth: 1))
                    .shadow(color: .black.opacity(0.32), radius: 14, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct GlassPanel: View {
    let radius: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color(red: 0.063, green: 0.067, blue: 0.071).opacity(0.80))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.42), radius: 34, y: 20)
            .shadow(color: .white.opacity(0.035), radius: 1, y: -1)
    }
}
