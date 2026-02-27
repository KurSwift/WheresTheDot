//
//  AudioManager.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 15/02/26.
//

import Foundation
import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer? = nil
    
    func startBackgroundMusic(filename: String,
                              ext: String,
                              volume: Float = 0.3,
                              fadeIn: TimeInterval = 0.4) {
        if let player = player, player.isPlaying {
            return
        }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("Audio file \(filename) was not found.")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = volume
            p.play()
            p.prepareToPlay()
            p.play()
            
            self.player = p
            setVolume(volume, fade: fadeIn)
        } catch {
            print("Audio error: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundMusic(fadeOut: TimeInterval = 0.25) {
        guard player != nil else { return }
        setVolume(0, fade: fadeOut) { [weak self] in
            self?.player?.stop()
            self?.player = nil
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    func setVolume(_ volume: Float, fade: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player else { completion?(); return }
        
        if fade <= 0 {
            player.volume = volume
            completion?()
            return
        }
        
        player.setVolume(volume, fadeDuration: fade)
        // call completion after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + fade) {
            completion?()
        }
    }
}
