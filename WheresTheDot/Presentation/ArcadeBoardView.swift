import SwiftUI

struct ArcadeBoardView: View {
    @EnvironmentObject private var appState: AppState
    let world: Int

    // Simple layout constants
    private let levelCount = 10

    var body: some View {
        ZStack {
            NeonGridBackground()

            VStack(spacing: 0) {
                header
                ScrollView(.vertical, showsIndicators: false) {
                    boardPath
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("World \(world)")
        .safeAreaInset(edge: .bottom) {
            footer
                .background(.ultraThinMaterial)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("World \(world)")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
            Text("Choose a level")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    private var boardPath: some View {
        ZStack {
            // Curvy path
            Path { path in
                let width: CGFloat = 300
                let height: CGFloat = 900
                let start = CGPoint(x: 40, y: 40)
                path.move(to: start)
                // Draw a simple snaking path
                path.addCurve(to: CGPoint(x: width-40, y: 180), control1: CGPoint(x: 120, y: 60), control2: CGPoint(x: width-120, y: 120))
                path.addCurve(to: CGPoint(x: 40, y: 360), control1: CGPoint(x: width-60, y: 240), control2: CGPoint(x: 80, y: 300))
                path.addCurve(to: CGPoint(x: width-40, y: 540), control1: CGPoint(x: 120, y: 420), control2: CGPoint(x: width-120, y: 480))
                path.addCurve(to: CGPoint(x: 40, y: 720), control1: CGPoint(x: width-60, y: 600), control2: CGPoint(x: 80, y: 660))
                path.addLine(to: CGPoint(x: width/2, y: height-40))
            }
            .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [8, 10]))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Levels as nodes along the path
            VStack(spacing: 40) {
                ForEach(1...levelCount, id: \.self) { level in
                    Button {
                        appState.startArcadeLevel(world: world, level: level)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(levelColor(level))
                                    .frame(width: 52, height: 52)
                                    .shadow(color: levelColor(level).opacity(0.7), radius: 10, x: 0, y: 0)
                                Text("\(level)")
                                    .font(.headline).bold()
                                    .foregroundStyle(.black)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Level \(level)")
                                    .font(.headline)
                                Text("Goal: \(goalForLevel(level)) points")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 24)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button {
                appState.openArcadeBoard(world: max(1, world - 1))
            } label: {
                Label("Prev", systemImage: "arrow.left")
            }
            .buttonStyle(.bordered)
            Spacer()
            Button {
                appState.openArcadeBoard(world: world + 1)
            } label: {
                Label("Next", systemImage: "arrow.right")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func levelColor(_ level: Int) -> Color {
        switch (level - 1) % 5 {
        case 0: return .neonCyan
        case 1: return .neonMagenta
        case 2: return .neonLime
        case 3: return .neonYellow
        default: return .neonOrange
        }
    }

    private func goalForLevel(_ level: Int) -> Int {
        // Level 1: 5, Level 2: 7, Level 3: 9, ...
        return 5 + (level - 1) * 2
    }
}

#Preview {
    ArcadeBoardView(world: 1)
        .environmentObject(AppState())
}
