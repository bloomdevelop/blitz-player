# Blitz Player

A iOS 18+ Music Player built with Swift and SwiftUI

> [!WARNING]
> `xtool` is required to build and install development app into iDevice. (Only for Linux and Windows, expect MacOS since they already have Xcode)

## TODO

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
