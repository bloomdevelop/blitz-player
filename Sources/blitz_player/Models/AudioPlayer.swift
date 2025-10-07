import AudioKit
import AVFoundation
import Foundation
import MediaPlayer
import os.log
import UIKit

class AudioPlayer: ObservableObject, @unchecked Sendable {
   private let engine = AudioEngine()
   private let mixer = Mixer()
   private let currentPlayer = AudioKit.AudioPlayer()
   private var nextPlayer: AudioKit.AudioPlayer?

   @Published var isPlaying = false
   @Published var currentTime: TimeInterval = 0
   @Published var duration: TimeInterval = 0
   @Published var currentSong: Song?

   weak var songManager: SongManager?
  private var timer: Timer?
  private var fadeTimer: Timer?
  private var crossfadeDuration: Double = 0.0
  private var isCrossfading = false
  private var preloadedNextPlayer: AudioKit.AudioPlayer?
  private var preloadedSong: Song?

  @MainActor private func setIdleTimerDisabled(_ disabled: Bool) {
    UIApplication.shared.isIdleTimerDisabled = disabled
  }

  init() {
    // Route mixer to output
    engine.output = mixer
    // Add current player to mixer
    mixer.addInput(currentPlayer)

    // Setup remote command center for Now Playing controls
    setupRemoteCommandCenter()

    // Temporary: Set default crossfade duration for testing
    crossfadeDuration = 2.0  // 2 seconds
  }

  func updateCrossfadeDuration(_ duration: Double) {
    crossfadeDuration = duration
  }

  // MARK: - Start Playback Function
  @MainActor func startPlayback(song: Song) {
    logAsync("Starting playback: \(song.name)", level: .info, category: "AudioPlayer")
    currentSong = song

    // Cancel any ongoing crossfade
    cancelCrossfade()

    // Stop and clear next player if exists
    nextPlayer?.stop()
    if let nextPlayer = nextPlayer {
      mixer.removeInput(nextPlayer)
    }
    nextPlayer = nil

    // Clean up preloaded song
    cleanupPreloadedSong()

    // Ensure security-scoped resource access for the song URL
    let accessed = song.url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        song.url.stopAccessingSecurityScopedResource()
      }
    }
    do {
      try currentPlayer.load(url: song.url)
      if !engine.avEngine.isRunning {
        // Configure AVAudioSession for background playback before starting engine
        setupAudioSession()
        try engine.start()
      }

      currentPlayer.volume = 1.0  // Ensure full volume
      currentPlayer.play()
      isPlaying = true
      duration = song.duration ?? TimeInterval(CGFloat(currentPlayer.duration))

      // Prevent device sleep during playback
      setIdleTimerDisabled(true)

      // Update Now Playing info
      updateNowPlayingInfo()

      // Then start the timer
      startTimer()
      logAsync("Playback started successfully", level: .info, category: "AudioPlayer")
    } catch {
      logAsync("Playback failed: \(error)", level: .error, category: "AudioPlayer")
    }
  }

  @MainActor func pausePlayback() {
    logAsync("Pausing playback", level: .info, category: "AudioPlayer")
    currentPlayer.pause()
    isPlaying = false
    // Allow device sleep when paused
    setIdleTimerDisabled(false)
    stopTimer()
  }

  // MARK: - Toggle Playback Function
  @MainActor func togglePlayback() {
    // We need to check if the player is currently playing or not.
    if currentPlayer.isPlaying {
      logAsync("Toggling playback: pause", level: .info, category: "AudioPlayer")
      currentPlayer.pause()
      isPlaying = false
      // Allow device sleep when paused
      setIdleTimerDisabled(false)
      stopTimer()
    } else {
      logAsync("Toggling playback: play", level: .info, category: "AudioPlayer")
      currentPlayer.play()
      isPlaying = true
      // Prevent device sleep during playback
      setIdleTimerDisabled(true)
      startTimer()
    }
  }

  // MARK: - Seek Function
  func seek(to time: CGFloat) {
    logAsync("Seeking to \(time)s", level: .debug, category: "AudioPlayer")
    // AudioKit's AudioPlayer.currentTime is get-only. Use play(from:) to seek.
    let clamped = max(0, min(time, CGFloat(currentPlayer.duration)))
    let wasPlaying = currentPlayer.isPlaying
    // Restart playback from the target position; pause again if we were paused.
    currentPlayer.stop()
    currentPlayer.play(from: clamped)
    if !wasPlaying {
      currentPlayer.pause()
    }
    currentTime = TimeInterval(clamped)
    updateNowPlayingInfo()
  }

  @MainActor func stopPlayback() {
    logAsync("Stopping playback", level: .info, category: "AudioPlayer")
    currentPlayer.stop()
    isPlaying = false
    // Allow device sleep when stopped
    setIdleTimerDisabled(false)
    stopTimer()
  }

  // MARK: - Next/Previous Playback
  @MainActor func playNext() {
    guard let playlist = songManager?.songs, let current = currentSong, let index = playlist.firstIndex(where: { $0.id == current.id }) else { return }
    let nextIndex = (index + 1) % playlist.count
    let nextSong = playlist[nextIndex]

    if crossfadeDuration > 0 {
      performCrossfade(to: nextSong)
    } else {
      startPlayback(song: nextSong)
    }
  }

  @MainActor func playPrevious() {
    guard let playlist = songManager?.songs, let current = currentSong, let index = playlist.firstIndex(where: { $0.id == current.id }) else { return }
    let prevIndex = (index - 1 + playlist.count) % playlist.count
    let prevSong = playlist[prevIndex]

    if crossfadeDuration > 0 {
      performCrossfade(to: prevSong)
    } else {
      startPlayback(song: prevSong)
    }
  }

  // MARK: - Crossfade Methods
  @MainActor private func performCrossfade(to nextSong: Song) {
    guard !isCrossfading else { return }

    isCrossfading = true

    // Check if we have a preloaded player for this song
    if let preloadedPlayer = preloadedNextPlayer, preloadedSong?.id == nextSong.id {
      // Use preloaded player for gapless crossfade
      nextPlayer = preloadedPlayer
      mixer.addInput(preloadedPlayer)
      preloadedPlayer.volume = 0.0  // Start silent
      preloadedPlayer.play()

      // Clear preloaded references
      preloadedNextPlayer = nil
      preloadedSong = nil

      // Start fade
      startCrossfade(to: nextSong)
    } else {
      // Create and setup next player (fallback)
      let newNextPlayer = AudioKit.AudioPlayer()
      nextPlayer = newNextPlayer
      mixer.addInput(newNextPlayer)

      // Load next song
      let accessed = nextSong.url.startAccessingSecurityScopedResource()
      defer {
        if accessed {
          nextSong.url.stopAccessingSecurityScopedResource()
        }
      }

      do {
        try newNextPlayer.load(url: nextSong.url)
        newNextPlayer.volume = 0.0  // Start silent
        newNextPlayer.play()

        // Start fade
        startCrossfade(to: nextSong)

      } catch {
        logAsync("Failed to load next song for crossfade: \(error)", level: .error, category: "AudioPlayer")
        isCrossfading = false
        // Fallback to immediate playback
        startPlayback(song: nextSong)
      }
    }
  }

  private func startCrossfade(to nextSong: Song) {
    guard let nextPlayer = nextPlayer else { return }

    let steps = 20  // Number of fade steps
    let stepDuration = crossfadeDuration / Double(steps)
    var currentStep = 0

    fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
      guard let self = self else { return }

      currentStep += 1
      let progress = Double(currentStep) / Double(steps)

      // Fade out current, fade in next
      self.currentPlayer.volume = Float(1.0 - progress)
      nextPlayer.volume = Float(progress)

      if currentStep >= steps {
        // Fade complete
        self.completeCrossfade(to: nextSong)
        timer.invalidate()
      }
    }
  }

  private func completeCrossfade(to nextSong: Song) {
    // Stop and remove old player
    currentPlayer.stop()
    mixer.removeInput(currentPlayer)

    // Move next player to current
    guard let nextPlayer = nextPlayer else { return }

    // Note: In a more robust implementation, you'd swap references
    // For simplicity, we'll restart with the next song
    // In production, consider keeping player references and just updating properties

    self.nextPlayer = nil
    isCrossfading = false

    // Update state
    currentSong = nextSong
    duration = nextSong.duration ?? TimeInterval(CGFloat(nextPlayer.duration))
    updateNowPlayingInfo()

    logAsync("Crossfade completed to: \(nextSong.name)", level: .info, category: "AudioPlayer")
  }

  private func cancelCrossfade() {
    fadeTimer?.invalidate()
    fadeTimer = nil
    isCrossfading = false

    if let nextPlayer = nextPlayer {
      nextPlayer.stop()
      mixer.removeInput(nextPlayer)
      self.nextPlayer = nil
    }

    // Reset current player volume
    currentPlayer.volume = 1.0
  }

  // MARK: - Gapless Playback Methods
  @MainActor private func preloadNextSong() {
    guard let playlist = songManager?.songs,
          let current = currentSong,
          let index = playlist.firstIndex(where: { $0.id == current.id }),
          !isCrossfading else { return }

    let nextIndex = (index + 1) % playlist.count
    let nextSong = playlist[nextIndex]

    // Don't preload if already preloaded
    if preloadedSong?.id == nextSong.id { return }

    // Clean up previous preload
    cleanupPreloadedSong()

    // Preload the next song
    let accessed = nextSong.url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        nextSong.url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let preloadPlayer = AudioKit.AudioPlayer()
      try preloadPlayer.load(url: nextSong.url)
      preloadedNextPlayer = preloadPlayer
      preloadedSong = nextSong

      logAsync("Preloaded next song: \(nextSong.name)", level: .info, category: "AudioPlayer")
    } catch {
      logAsync("Failed to preload next song: \(error)", level: .error, category: "AudioPlayer")
    }
  }

  private func cleanupPreloadedSong() {
    preloadedNextPlayer?.stop()
    preloadedNextPlayer = nil
    preloadedSong = nil
  }

  private func shouldPreloadNextSong() -> Bool {
    guard duration > 0 else { return false }

    // Preload when 10 seconds remaining or when crossfade duration + 5 seconds remaining
    let preloadThreshold = max(10.0, crossfadeDuration + 5.0)
    let remainingTime = duration - currentTime

    return remainingTime <= preloadThreshold && remainingTime > 0
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self else { return }
      self.currentTime = TimeInterval(CGFloat(self.currentPlayer.currentTime))
      // Keep duration synced after load
      if self.duration == 0 {
        self.duration = TimeInterval(CGFloat(self.currentPlayer.duration))
      }

      // Check if we should preload next song for gapless playback
      if self.shouldPreloadNextSong() {
        Task { @MainActor in
          self.preloadNextSong()
        }
      }

      // Update Now Playing info with current time
      self.updateNowPlayingInfo()
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  // MARK: - AVAudioSession Setup
  private func setupAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)
      logAsync("AVAudioSession configured for background playback", level: .info, category: "AudioPlayer")
    } catch {
      logAsync("Failed to configure AVAudioSession: \(error)", level: .error, category: "AudioPlayer")
    }
  }

  // MARK: - Remote Command Center Setup
  private func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      do {
        if !self.engine.avEngine.isRunning {
          try self.engine.start()
        }
        self.currentPlayer.play()
        self.isPlaying = true
        // Prevent device sleep during playback
        Task { await self.setIdleTimerDisabled(true) }
        self.startTimer()
        self.updateNowPlayingInfo()
        return .success
      } catch {
        return .commandFailed
      }
    }

    commandCenter.pauseCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      self.currentPlayer.pause()
      self.isPlaying = false
      // Allow device sleep when paused
      Task { await self.setIdleTimerDisabled(false) }
      self.stopTimer()
      self.updateNowPlayingInfo()
      return .success
    }

    commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      self.seek(to: CGFloat(positionEvent.positionTime))
      return .success
    }

    commandCenter.previousTrackCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      Task { await self.playPrevious() }
      return .success
    }

    commandCenter.nextTrackCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      Task { await self.playNext() }
      return .success
    }

    // Enable the commands
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.changePlaybackPositionCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
  }

  // MARK: - Now Playing Info
  private func updateNowPlayingInfo() {
    guard let song = currentSong else { return }

    var nowPlayingInfo = [String: Any]()

    if let title = song.title {
      nowPlayingInfo[MPMediaItemPropertyTitle] = title
    }
    if let artist = song.artist {
      nowPlayingInfo[MPMediaItemPropertyArtist] = artist
    }
    if let album = song.album {
      nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
    }
    if let artwork = song.artwork {
      let artworkItem = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artworkItem
    }

    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }
}
