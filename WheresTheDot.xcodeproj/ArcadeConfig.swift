import Foundation

/// Arcade mode configuration: levels unlocked at specific score thresholds (within a single run).
/// Level 1 starts at score >= 0, Level 2 at >= 6, etc.
/// Adjust the thresholds to tune pacing.
enum ArcadeConfig {
    /// Score thresholds that define the start of each level.
    /// Example: [0, 6, 12, 19, 27, 36] means:
    /// - Level 1 for scores 0...5
    /// - Level 2 for scores 6...11
    /// - Level 3 for scores 12...18, and so on.
    static let levelThresholds: [Int] = [0, 6, 12, 19, 27, 36, 46, 57]

    /// Returns the current level number (1-based) for a given score.
    static func level(for score: Int) -> Int {
        guard !levelThresholds.isEmpty else { return 1 }
        var current = 1
        for (idx, threshold) in levelThresholds.enumerated() {
            if score >= threshold { current = idx + 1 } else { break }
        }
        return current
    }

    /// Returns the score required to reach the next level from the given score.
    /// If already at the max level, returns nil.
    static func nextLevelScore(after score: Int) -> Int? {
        for t in levelThresholds.sorted() where t > score { return t }
        return nil
    }

    /// If the score crossed a level boundary from oldScore -> newScore, returns the new level.
    /// Otherwise returns nil.
    static func justLeveledUp(from oldScore: Int, to newScore: Int) -> Int? {
        let oldLevel = level(for: oldScore)
        let newLevel = level(for: newScore)
        return (newLevel > oldLevel) ? newLevel : nil
    }
}
