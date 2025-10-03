import Foundation
import AudioKit

class AudioPlayer: ObservableObject, @unchecked Sendable {
    private let engine = AudioEngine()
    private let player = AudioKit.AudioPlayer()

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var timer: Timer?

    init() {
        // Route player to output
        engine.output = player
    }

    // MARK: - Start Playback Function
    func startPlayback(url: URL) {
        // Note: Security-scoped resource access should already be maintained by the folder that contains this file
        do {
            try player.load(url: url)
            if !engine.avEngine.isRunning {
                try engine.start()
            }

            player.play()
            isPlaying = true
            duration = TimeInterval(CGFloat(player.duration))

            // Then start the timer
            startTimer()
        } catch {
            print("[ERROR] Playback failed: \(error)")
        }
    }

    func pausePlayback() {
        player.pause()
        isPlaying = false
        stopTimer()
    }

    // MARK: - Toggle Playback Function
    func togglePlayback() {
        // We need to check if the player is currently playing or not.
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    // MARK: - Seek Function
    func seek(to time: CGFloat) {
        // AudioKit's AudioPlayer.currentTime is get-only. Use play(from:) to seek.
        let clamped = max(0, min(time, CGFloat(player.duration)))
        let wasPlaying = player.isPlaying
        // Restart playback from the target position; pause again if we were paused.
        player.stop()
        player.play(from: clamped)
        if !wasPlaying {
            player.pause()
        }
        currentTime = TimeInterval(clamped)
    }
    
    func stopPlayback() {
        player.stop()
        isPlaying = false
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentTime = TimeInterval(CGFloat(self.player.currentTime))
            // Keep duration synced after load
            if self.duration == 0 {
                self.duration = TimeInterval(CGFloat(self.player.duration))
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}