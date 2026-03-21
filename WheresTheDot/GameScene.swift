import SpriteKit

final class GameScene: SKScene {
    
    private var tapSoundAction: SKAction = .playSoundFileNamed("pulse.wav", waitForCompletion: false)
    var onSceneReady: ((CGSize) -> Void)?
    var onDotTapped: ((UUID) -> Void)?
    var onTapFeedback: (() -> Void)?

    private var inputEnabled = false
    private var didNotifyReady = false
    private let gridNodeName = "arcade-grid"
    
    enum GameLevel {
        case beginner
        case medium
        case hard
        case impossible
    }
    
    var level: GameLevel = .beginner
    var colorBlindMode: Bool = false

    // MARK: - Init

    override init(size: CGSize) {
        super.init(size: size)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .darkGray
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // If you created with .init(size:), this is already correct.
        // But keeping it safe in case the view resizes:
        self.size = view.bounds.size
        backgroundColor = .black
        let tap = SKAction.playSoundFileNamed("tap.wav", waitForCompletion: false)
        run(.sequence([tap, .wait(forDuration: 0.01)]))

        notifyReadyIfNeeded()
        rebuildGrid()
    }
    
    private func playTapSound() {
        run(tapSoundAction)
    }
    
    private func rebuildGrid() {
        // Remove previous grid (safe if called multiple times)
        childNode(withName: gridNodeName)?.removeFromParent()
        
        let grid = makeGridNode(
            size: size,
            spacing: 44,        // tweak: 32 / 40 / 48
            majorEvery: 5       // every 5th line is slightly stronger
        )
        grid.name = gridNodeName
        grid.zPosition = -10_000
        addChild(grid)
    }
    
    func recalculateLevelBasedOnScore(_ score: Int) {
        switch score {
        case 0 ..< 5:
            level = .beginner
        case 6 ..< 10:
            level = .medium
        case 10 ..< 15:
            level = .hard
        default:
            level = .impossible
        }
    }
    
    private func makeGridNode(size: CGSize, spacing: CGFloat, majorEvery: Int) -> SKNode {
            let container = SKNode()

            // Colors / glow vibe
            let minorColor = UIColor.neonCyan.withAlphaComponent(0.08)
            let majorColor = UIColor.neonCyan.withAlphaComponent(0.14)

            // Draw vertical lines
            let cols = Int(ceil(size.width / spacing))
            for i in 0...cols {
                let x = CGFloat(i) * spacing
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))

                let line = SKShapeNode(path: path)
                line.strokeColor = (i % majorEvery == 0) ? majorColor : minorColor
                line.lineWidth = (i % majorEvery == 0) ? 1.5 : 1.0
                line.isAntialiased = true
                line.blendMode = .add
                line.glowWidth = (i % majorEvery == 0) ? 2.0 : 1.0
                container.addChild(line)
            }

            // Draw horizontal lines
            let rows = Int(ceil(size.height / spacing))
            for j in 0...rows {
                let y = CGFloat(j) * spacing
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))

                let line = SKShapeNode(path: path)
                line.strokeColor = (j % majorEvery == 0) ? majorColor : minorColor
                line.lineWidth = (j % majorEvery == 0) ? 1.5 : 1.0
                line.isAntialiased = true
                line.blendMode = .add
                line.glowWidth = (j % majorEvery == 0) ? 2.0 : 1.0
                container.addChild(line)
            }

            // Optional: subtle “vignette” feel by adding a very faint overlay
            let vignette = SKSpriteNode(color: .black, size: size)
            vignette.alpha = 0.12
            vignette.position = CGPoint(x: size.width / 2, y: size.height / 2)
            vignette.blendMode = .alpha
            container.addChild(vignette)

            return container
        }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        notifyReadyIfNeeded()
    }

    private func notifyReadyIfNeeded() {
        guard !didNotifyReady, size != .zero else { return }
        didNotifyReady = true
        onSceneReady?(size)
    }

    // MARK: - Public API

    func setInputEnabled(_ enabled: Bool) {
        inputEnabled = enabled
    }
    
    func alphaForDot(index: Int, total: Int, score: Int) -> CGFloat {
        // total == score usually
        if score <= 5 {
            // training: slight gradient
            let t = CGFloat(index) / CGFloat(max(total - 1, 1))
            return 0.55 + 0.45 * t
        } else {
            // no cue
            return 0.85
        }
    }

    func render(round: Round) {
        enumerateChildNodes(withName: "dot") { node, _ in node.removeFromParent() }
        enumerateChildNodes(withName: "halo") { node, _ in node.removeFromParent() }

        let score = round.dots.count
        let baseColor = arcadeColor(for: score)
        recalculateLevelBasedOnScore(score)
        for (i, dot) in round.dots.enumerated() {
            // Older dots slightly dimmer (arcade depth)
            let t = CGFloat(i) / CGFloat(max(score - 1, 1))
            var alpha: CGFloat = 1.0
            switch level {
            case .beginner:
                alpha = 0.55 + 0.45 * t
            case .medium:
                alpha = 0.18
            case .hard:
                alpha = 0.18
            case .impossible:
                alpha = 0.18
            }

            // Halo (glow)
            let halo = SKShapeNode(circleOfRadius: dot.radius * 1.8)
            halo.name = "halo"
            halo.position = dot.position
            halo.fillColor = baseColor.withAlphaComponent(alpha)
            halo.strokeColor = .clear
            halo.blendMode = .add
            halo.zPosition = 0
            addChild(halo)

            // Dot
            let node = SKShapeNode(circleOfRadius: dot.radius)
            node.name = "dot"
            node.position = dot.position
            node.fillColor = baseColor
            node.strokeColor = .clear
            node.blendMode = .add
            node.zPosition = 1
            node.userData = ["id": dot.id.uuidString]
            addChild(node)

            // Pop-in
            node.setScale(0.0)
            halo.setScale(0.0)
            let pop = SKAction.scale(to: 1.0, duration: 0.14)
            pop.timingMode = .easeOut
            node.run(pop)
            halo.run(pop)
        }

        // Make newest dot slightly “hotter” (but not a pulse cue forever)
        //emphasizeNewDot(round.newDotID)
    }

    private func emphasizeNewDot(_ id: UUID) {
        guard let node = dotNode(id: id) else { return }
        let alpha = CGFloat.random(in: 0.75...0.95)
        node.fillColor = node.fillColor.withAlphaComponent(alpha)
    }

    func dotNode(id: UUID) -> SKShapeNode? {
        children.compactMap { $0 as? SKShapeNode }
            .first(where: { $0.name == "dot" && ($0.userData?["id"] as? String) == id.uuidString })
    }

    func showOutcome(_ outcome: RoundOutcome) {
        // Minimal feedback (optional):
        // highlight the correct dot briefly
        let correctID: UUID
        switch outcome {
        case .correct(let id): correctID = id
        case .wrong(_, let id): correctID = id
        case .noSelection(let id): correctID = id
        }

        let nodes = children.compactMap { $0 as? SKShapeNode }
        if let node = nodes.first(where: { ($0.userData?["id"] as? String) == correctID.uuidString }) {
            let pulseUp = SKAction.scale(to: 1.4, duration: 0.12)
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.12)
            node.run(.sequence([pulseUp, pulseDown]))
        }
    }
    
    func showWrongTap(chosenID: UUID, correctID: UUID) {
        // Flash red overlay quickly
        let flash = SKSpriteNode(color: .red, size: size)
        flash.position = CGPoint(x: size.width/2, y: size.height/2)
        flash.zPosition = 20_000
        flash.alpha = 0
        addChild(flash)

        let inAction = SKAction.fadeAlpha(to: 0.35, duration: 0.06)
        let outAction = SKAction.fadeOut(withDuration: 0.18)
        flash.run(.sequence([inAction, outAction, .removeFromParent()]))

        // Pulse correct dot so player learns
        pulseDot(id: correctID)
    }
    
    func spawnCorrectBurst(at point: CGPoint, color: UIColor) {
        let emitter = SKEmitterNode()// optional, else comment out
        emitter.particleBirthRate = 400
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.35
        emitter.particleLifetimeRange = 0.15
        emitter.particleSpeed = 240
        emitter.particleSpeedRange = 140
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.08
        emitter.particleScaleRange = 0.06
        emitter.particleAlpha = 0.9
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -2.4
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.position = point
        emitter.zPosition = 50

        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.55), .removeFromParent()]))
    }
    
    func showWrongFeedback() {
        showWrongFlash() // your existing red flash is fine

        // Camera shake (arcade punch)
        let shake = SKAction.sequence([
            .moveBy(x: 10, y: 0, duration: 0.05),
            .moveBy(x: -18, y: 0, duration: 0.05),
            .moveBy(x: 12, y: 0, duration: 0.05),
            .moveBy(x: -4, y: 0, duration: 0.05)
        ])
        run(shake)
    }
    
    func showWrongFlash() {
        // remove existing flash first
        childNode(withName: wrongFlashName)?.removeFromParent()
        
        let flash = SKSpriteNode(color: .red, size: size)
        flash.name = wrongFlashName
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 20_000
        flash.alpha = 0
        addChild(flash)
        
        let fadeIn = SKAction.fadeAlpha(to: 0.35, duration: 0.06)
        let fadeOut = SKAction.fadeOut(withDuration: 0.18)
        flash.run(.sequence([fadeIn, fadeOut, .removeFromParent()]))
    }

    // MARK: - Touches

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled, let touch = touches.first else { return }

        let p = touch.location(in: self)
        onTapFeedback?()
        let hitNodes = nodes(at: p)

        // Find first dot hit
        for n in hitNodes {
            guard let shape = n as? SKShapeNode,
                  shape.name == "dot",
                  let idString = shape.userData?["id"] as? String,
                  let id = UUID(uuidString: idString)
            else { continue }
            onDotTapped?(id)
            break
        }
    }
    
    private let coverNodeName = "memory-cover"
    private let wrongFlashName = "wrong-flash"
    
    func clearOverlays() {
        childNode(withName: coverNodeName)?.removeFromParent()
        childNode(withName: wrongFlashName)?.removeFromParent()
    }
    
    func showMemoryCover(duration: TimeInterval) {
        // Remove any existing cover
        childNode(withName: coverNodeName)?.removeFromParent()
  
        let cover = SKSpriteNode(color: .black, size: size)
        cover.name = coverNodeName
        cover.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cover.zPosition = 10_000
        cover.alpha = 0
        
        addChild(cover)
        
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        let wait = SKAction.wait(forDuration: duration)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.10)
        let remove = SKAction.removeFromParent()
        
        cover.run(.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    /// Optional: pulse a specific dot (newest dot) to guide player slightly
    func pulseDot(id: UUID) {
        let nodes = children.compactMap { $0 as? SKShapeNode }
        guard let node = nodes.first(where: { ($0.userData?["id"] as? String) == id.uuidString }) else { return }
        
        let up = SKAction.scale(to: 1.35, duration: 0.10)
        let down = SKAction.scale(to: 1.0, duration: 0.10)
        node.run(.sequence([up, down]))
    }
    
    private var roundTimerTask: Task<Void, Never>?
    
    func startRoundTimer(seconds: TimeInterval, onTimeout: @escaping () -> Void) {
            // cancel previous timer
            roundTimerTask?.cancel()

            roundTimerTask = Task { @MainActor in
                let ns = UInt64(seconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)

                guard !Task.isCancelled else { return }
                // only timeout if input is still enabled (round active)
                if inputEnabled { onTimeout() }
            }
        }

        func cancelRoundTimer() {
            roundTimerTask?.cancel()
            roundTimerTask = nil
        }

    // MARK: - Level-up flash

    func flashLevelUp(color: UIColor) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 19_000
        flash.alpha = 0
        addChild(flash)

        let fadeIn  = SKAction.fadeAlpha(to: 0.45, duration: 0.08)
        let hold    = SKAction.wait(forDuration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.35)
        flash.run(.sequence([fadeIn, hold, fadeOut, .removeFromParent()]))
    }

    // MARK: - Color Helpers

    private func arcadeColor(for score: Int) -> UIColor {
        let colors = colorBlindMode
            ? [UIColor.accessibleBlue, .accessibleAmber, .accessibleTeal, .accessibleYellow, .accessibleLavender]
            : [UIColor.neonCyan, .neonPink, .neonPurple, .neonLime, .neonOrange]
        return colors[(max(1, score) - 1) % colors.count]
    }

}

