//
//  OpenImmersiveApp.swift
//  OpenImmersiveApp
//
//  Created by Anthony Maës (Acute Immersive) on 9/20/24.
//

import SwiftUI
import OpenImmersive

enum ProjectionOption: String, Codable {
    /// The projection to use for VR180/VR360 videos.
    case equirectangular = "Equirectangular"
    /// The projection to use for Spatial videos and other rectangular videos.
    case rectilinear = "Rectilinear"
    /// The projection to use for Apple Immersive videos (AIVU).
    case appleImmersive = "AIVU"
}

/// Per-file persisted settings and last playback position.
final class VideoSettingsCache {
    struct Entry: Codable {
        var lastAccessed: Date
        var lastPosition: Double
        var projection: ProjectionOption
        var fieldOfView: Int
        var forceFov: Bool
        var framePacking: VideoItem.FramePacking
        var baseline: Float
        var showHands: Bool
        var showTimecodeReadout: Bool
    }

    private var entries: [String: Entry] = [:]
    private let fileURL: URL

    init() {
        let dir: URL
        if let support = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            dir = support.appendingPathComponent("OpenImmersive", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } else {
            dir = FileManager.default.temporaryDirectory
        }
        self.fileURL = dir.appendingPathComponent("video_settings_cache.json")
        loadFromDisk()
    }

    func entry(for itemId: String) -> Entry? {
        entries[itemId]
    }

    func save(_ entry: Entry, for itemId: String) {
        var updated = entry
        updated.lastAccessed = Date()
        entries[itemId] = updated
        persist()
    }

    func updatePosition(_ position: Double, for itemId: String) {
        guard var existing = entries[itemId] else { return }
        existing.lastPosition = position
        existing.lastAccessed = Date()
        entries[itemId] = existing
        persist()
    }

    func pruneOlderThan(_ interval: TimeInterval) {
        let cutoff = Date().addingTimeInterval(-interval)
        let originalCount = entries.count
        entries = entries.filter { $0.value.lastAccessed >= cutoff }
        if entries.count != originalCount {
            persist()
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([String: Entry].self, from: data) {
            entries = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

@Observable
class OpenImmersiveAppState {
    /// The user-selected item.
    var selectedItem: VideoItem?
    /// The user-selected projection for the video.
    var projection: ProjectionOption = .equirectangular {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }
    /// The user-selected field of view in case it cannot be extracted from the video asset (equirectangular projection only).
    var fieldOfView: Int = 180 {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }
    /// Whether to force the user-selected field of view even when the MV-HEVC media encodes a field of view.
    var forceFov: Bool = false {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }
    /// The user-selected frame packing type.
    var framePacking: VideoItem.FramePacking = .none {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }
    /// Whether to show the timecode readout view in the ImmersivePlayer.
    var showTimecodeReadout: Bool = false {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }
    /// Whether to show the user's hands in immersive view.
    var showHands: Bool = false {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }
    /// The stereo camera baseline (inter-lens distance) in millimeters.
    var baseline: Float = 65.0 {
        didSet { if !isLoading { updateCacheIfNeeded() } }
    }

    /// Persistent per-file settings store.
    let cache: VideoSettingsCache
    /// Time (in seconds) to seek to when the next immersive playback starts.
    var pendingResumeTime: Double?
    /// Reference to the currently active VideoPlayer, populated while immersive space is open.
    var currentVideoPlayer: VideoPlayer?

    private var isLoading = false

    init() {
        self.cache = VideoSettingsCache()
        let oneYearInSeconds: TimeInterval = 60 * 60 * 24 * 365
        cache.pruneOlderThan(oneYearInSeconds)
    }

    /// The current frame packing with the user-selected baseline applied.
    var framePackingWithBaseline: VideoItem.FramePacking {
        switch framePacking {
        case .sideBySide:
            return .sideBySide(baseline: baseline)
        case .overUnder:
            return .overUnder(baseline: baseline)
        case .none:
            return .none
        }
    }

    /// Updates the input VideoItem's `projection` value according to the corresponding user options.
    /// - Parameters:
    ///   - item: the object describing the video.
    func applyFormatOptions(to item: VideoItem) -> VideoItem {
        var item = item
        switch projection {
        case .equirectangular:
            item.projection = .equirectangular(fieldOfView: Float(self.fieldOfView), force: self.forceFov)
            item.framePacking = framePackingWithBaseline
        case .rectilinear:
            item.projection = .rectangular
            item.framePacking = framePackingWithBaseline
        case .appleImmersive:
            item.projection = .appleImmersive
            item.framePacking = .none
        }
        return item
    }

    /// Updates user options according to the input VideoItem's `projection` value, falling back to cached settings
    /// for any fields the file doesn't specify.
    /// - Parameters:
    ///   - item: the object describing the video.
    func applyFormatOptions(from item: VideoItem) {
        isLoading = true
        defer { isLoading = false }

        let cached = cache.entry(for: item.id)

        if let projection = item.projection {
            switch projection {
            case .equirectangular(fieldOfView: let fieldOfView, force: let force):
                self.projection = .equirectangular
                self.fieldOfView = Int(fieldOfView)
                self.forceFov = force
                self.framePacking = item.framePacking
            case .rectangular:
                self.projection = .rectilinear
                self.framePacking = item.framePacking
            case .appleImmersive:
                self.projection = .appleImmersive
                self.framePacking = .none
            }
        } else if let cached {
            self.projection = cached.projection
            self.fieldOfView = cached.fieldOfView
            self.forceFov = cached.forceFov
            self.framePacking = cached.framePacking
        }

        if let cached {
            self.baseline = cached.baseline
            self.showHands = cached.showHands
            self.showTimecodeReadout = cached.showTimecodeReadout
            self.pendingResumeTime = cached.lastPosition > 0 ? cached.lastPosition : nil
        } else {
            self.pendingResumeTime = nil
        }
    }

    /// Persists current settings for the selected item, preserving any previously stored playback position,
    /// and arms a resume seek for the upcoming immersive playback if a position is on file.
    func saveSettingsToCache() {
        guard let item = selectedItem else { return }
        cache.save(currentEntry(preservingPositionFor: item.id), for: item.id)
        if let entry = cache.entry(for: item.id), entry.lastPosition > 0 {
            pendingResumeTime = entry.lastPosition
        } else {
            pendingResumeTime = nil
        }
    }

    /// Persists a new playback position for the selected item.
    func saveTimecodeToCache(_ position: Double) {
        guard let item = selectedItem else { return }
        cache.updatePosition(position, for: item.id)
    }

    private func currentEntry(preservingPositionFor itemId: String) -> VideoSettingsCache.Entry {
        let preservedPosition = cache.entry(for: itemId)?.lastPosition ?? 0
        return VideoSettingsCache.Entry(
            lastAccessed: Date(),
            lastPosition: preservedPosition,
            projection: projection,
            fieldOfView: fieldOfView,
            forceFov: forceFov,
            framePacking: framePacking,
            baseline: baseline,
            showHands: showHands,
            showTimecodeReadout: showTimecodeReadout
        )
    }

    /// If the selected item has been cached previously, write the latest settings back to the cache.
    private func updateCacheIfNeeded() {
        guard let item = selectedItem,
              cache.entry(for: item.id) != nil else { return }
        cache.save(currentEntry(preservingPositionFor: item.id), for: item.id)
    }
}

/// A wrapper around `TimecodeToggle` that piggybacks on the always-rendered control panel button slot
/// to capture the active VideoPlayer reference and perform a pending resume seek.
struct PlayerCaptureToggle: View {
    let videoPlayer: VideoPlayer
    let appState: OpenImmersiveAppState

    var body: some View {
        TimecodeToggle(isOn: Binding(
            get: { appState.showTimecodeReadout },
            set: { appState.showTimecodeReadout = $0 }
        ))
        .task {
            appState.currentVideoPlayer = videoPlayer
            guard let resume = appState.pendingResumeTime else { return }
            appState.pendingResumeTime = nil
            // Wait for the asset to be ready before seeking (poll for non-zero duration).
            for _ in 0..<100 {
                if videoPlayer.duration > 0 { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
            videoPlayer.seek(to: resume)
        }
    }
}

@main
struct OpenImmersiveApp: App {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State var appState = OpenImmersiveAppState()

    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            DropTarget() {
                MainMenu()
            } loadItemAction: { item in
                appState.applyFormatOptions(from: item)
                appState.selectedItem = item
            }
            .frame(minWidth: 720, maxWidth: 720, minHeight: 720, maxHeight: 720)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 720, height: 720)
        .environment(appState)

        ImmersiveSpace(for: VideoItem.self) { $model in
            let closeAction: CustomAction = {
                if let player = appState.currentVideoPlayer {
                    appState.saveTimecodeToCache(player.currentTime)
                }
                appState.currentVideoPlayer = nil
                Task {
                    openWindow(id: "MainWindow")
                    await dismissImmersiveSpace()
                }
            }

            // The customButton lives inside the always-rendered ControlPanel, so we use it as the
            // reliable lifecycle anchor for capturing the VideoPlayer reference and applying resume seeks.
            let customButton: CustomViewBuilder = { $videoPlayer in
                PlayerCaptureToggle(videoPlayer: videoPlayer, appState: appState)
            }
            let customAttachment = CustomAttachment(
                id: "TimecodeReadout",
                body: { $videoPlayer in
                    TimecodeReadout(videoPlayer: videoPlayer, visible: $appState.showTimecodeReadout)
                },
                position: [0, -0.1, 0.1],
                orientation: simd_quatf(angle: -0.5, axis: [1, 0, 0]),
                relativeToControlPanel: true
            )

            ImmersivePlayer(
                selectedItem: model!,
                closeAction: closeAction,
                customButtons: customButton,
                customAttachments: [customAttachment]
            )
            .upperLimbVisibility(appState.showHands ? .visible : .hidden)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
