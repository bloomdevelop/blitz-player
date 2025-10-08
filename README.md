<br />
<div align="center">
  <a href="https://github.com/bloomdevelop/blitz-player">
    <img src=".github/assets/Icon.svg" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">Blitz Player</h3>

  <p align="center">
    iOS 18+ Music Player built with Swift and SwiftUI
    <br />
    <a href="https://github.com/bloomdevelop/blitz-player/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/bloomdevelop/blitz-player/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<div align="center">
    <img alt="Static Badge" src="https://img.shields.io/badge/made_with_swift-f05138?style=for-the-badge&logo=swift&logoColor=white">
    <img alt="GitHub License" src="https://img.shields.io/github/license/bloomdevelop/blitz-player?style=for-the-badge">
    <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/w/bloomdevelop/blitz-player?style=for-the-badge">
    <img alt="GitHub Issues or Pull Requests" src="https://img.shields.io/github/issues-pr/bloomdevelop/blitz-player?style=for-the-badge">
</div>

> [!WARNING]
> `xtool` is required to build and install development app into iDevice. (Only for Linux and Windows, expect MacOS since they already have Xcode)

## Roadmap

### Frontend

- [ ] Full Player Sheet
    - [ ] Crossfade/AutoMix Indicator
    - [ ] Queue UI
    - [X] Cover Art Background
    - [X] Custom Slider with Current/Remaining Time
- [X] Mini Player
- [ ] Library View
    - [X] Playlists
    - [ ] Albums
        - [ ] Swipe Actions
            - [ ] Favorite
            - [X] Quick Play
            - [ ] Append to Queue
    - [X] Artists
    - [ ] All Songs
- [ ] Home
    - [ ] Show recommended and suggestions
- [ ] Widgets

### Audio Backend
- [X] Playback Functionality
    - [X] Background Audio
    - [X] Play/Pause
    - [X] Next/Previous
    - [X] AudioKit
    - [X] "Now Playing" support
- [ ] Queue Functionality
- [ ] Crossfade
- [ ] AutoMix
    - [ ] Investigate how does AutoMix works
    - [ ] Implement engine for AutoMix

### Library Backend
- [ ] Search Functionality
- [ ] Playlists
    - [ ] User created playlist
    - [ ] Smart playlist
- [X] Song scanning/indexing
- [X] Song Metadata

---

## Changelogs

### 10-07-2025
- Fixed app crash when attempting to load from database
- Fixed missing cover art after indexing
- Added small animation and haptic on MiniPlayer when doing some actions
- Fixed some part of the FullPlayer UI being unreadable when there's no cover art
- Fixed Quick Play action not working properly
- New Feature: Crossfade
