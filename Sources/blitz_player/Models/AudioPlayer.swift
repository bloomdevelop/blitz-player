import AudioKit
import AVFoundation
import Foundation
import MediaPlayer
import os.log
import UIKit

class AudioPlayer: ObservableObject, @unchecked Sendable {
   private let engine = AudioEngine()
   private let player = AudioKit.AudioPlayer()

   @Published var isPlaying = false
   @Published var currentTime: TimeInterval = 0
   @Published var duration: TimeInterval = 0
   @Published var currentSong: Song?

   weak var songManager: SongManager?
  private var timer: Timer?
  @MainActor private func setIdleTimerDisabled(_ disabled: Bool) {
    UIApplication.shared.isIdleTimerDisabled = disabled
  }

  init() {
    // Route player to output
    engine.output = player

    // Setup remote command center for Now Playing controls
    setupRemoteCommandCenter()
  }

  // MARK: - Start Playback Function
  @MainActor func startPlayback(song: Song) {
    logAsync("Starting playback: \(song.name)", level: .info, category: "AudioPlayer")
    currentSong = song
    // Ensure security-scoped resource access for the song URL
    let accessed = song.url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        song.url.stopAccessingSecurityScopedResource()
      }
    }
    do {
      try player.load(url: song.url)
      if !engine.avEngine.isRunning {
        // Configure AVAudioSession for background playback before starting engine
        setupAudioSession()
        try engine.start()
      }

      player.play()
      isPlaying = true
      duration = song.duration ?? TimeInterval(CGFloat(player.duration))

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
    player.pause()
    isPlaying = false
    // Allow device sleep when paused
    setIdleTimerDisabled(false)
    stopTimer()
  }

  // MARK: - Toggle Playback Function
  @MainActor func togglePlayback() {
    // We need to check if the player is currently playing or not.
    if player.isPlaying {
      logAsync("Toggling playback: pause", level: .info, category: "AudioPlayer")
      player.pause()
      isPlaying = false
      // Allow device sleep when paused
      setIdleTimerDisabled(false)
      stopTimer()
    } else {
      logAsync("Toggling playback: play", level: .info, category: "AudioPlayer")
      player.play()
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

  @MainActor func stopPlayback() {
    logAsync("Stopping playback", level: .info, category: "AudioPlayer")
    player.stop()
    isPlaying = false
    // Allow device sleep when stopped
    setIdleTimerDisabled(false)
    stopTimer()
  }

  // MARK: - Next/Previous Playback
  @MainActor func playNext() {
    guard let playlist = songManager?.songs, let current = currentSong, let index = playlist.firstIndex(where: { $0.id == current.id }) else { return }
    let nextIndex = (index + 1) % playlist.count
    startPlayback(song: playlist[nextIndex])
  }

  @MainActor func playPrevious() {
    guard let playlist = songManager?.songs, let current = currentSong, let index = playlist.firstIndex(where: { $0.id == current.id }) else { return }
    let prevIndex = (index - 1 + playlist.count) % playlist.count
    startPlayback(song: playlist[prevIndex])
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self else { return }
      self.currentTime = TimeInterval(CGFloat(self.player.currentTime))
      // Keep duration synced after load
      if self.duration == 0 {
        self.duration = TimeInterval(CGFloat(self.player.duration))
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
        self.player.play()
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
      self.player.pause()
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
