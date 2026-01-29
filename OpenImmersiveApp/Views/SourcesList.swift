//
//  SourcesList.swift
//  OpenImmersiveApp
//
//  Created by Anthony Maës (Acute Immersive) on 9/20/24.
//

import SwiftUI
import OpenImmersive

/// A list of available video item sources.
struct SourcesList: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(OpenImmersiveAppState.self) private var appState
    @State private var areOptionsShowing: Bool = false
    
    var body: some View {
        @Bindable var appState = appState
        VStack(spacing: 10) {
            let selectedItem = {
                let item = appState.selectedItem ?? VideoItem.sampleHLSStream
                return appState.applyFormatOptions(to: item)
            }()
            
            ZStack(alignment: .bottomTrailing) {
                PlayButton() {
                    playVideo(selectedItem)
                }
                
                SettingsButton(isPresented: $areOptionsShowing)
                    .padding(.trailing, 20)
                    .padding(.bottom, 12)
            }
            
            let videoTitle = selectedItem.metadata[.commonIdentifierTitle] ?? "<NONE>"
            let fieldOfView = appState.projection == .equirectangular ? " \(appState.fieldOfView)°" : ""
            let framePacking = appState.projection == .appleImmersive || appState.framePacking == .none ? "" : "(\(appState.framePacking.description))"
            
            Text("Selected video: **\(videoTitle)**")
            Text("Format: **\(appState.projection.rawValue)\(fieldOfView)** \(framePacking)")
            
            Divider()
                .padding(.vertical)
            
            Text("\(Image(systemName: "info.circle")) This player supports Spatial Video, AIV Immersive Videos, MV-HEVC, side-by-side and over-under.\nUse the gear button to select the correct format and projection.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding()
        }
        .popover(isPresented: $areOptionsShowing) {
            SettingsPopoverContent(appState: appState)
        }
    }
    
    /// Open the immersive player and play the video for the provided item.
    /// - Parameters:
    ///   - item: the object describing the video.
    ///
    /// Opening the immersive player will close the current window containing the SourcesList view.
    func playVideo(_ item: VideoItem) {
        Task {
            let result = await openImmersiveSpace(value: item)
            if result == .opened {
                dismissWindow()
            }
        }
    }
    
}

/// Shared picker controls for selecting sources and format options.
struct SourcesPickerControls: View {
    @Environment(OpenImmersiveAppState.self) private var appState
    /// The visibility of a panel with advanced format options
    @State private var areOptionsShowing: Bool = false
    
    var body: some View {
        @Bindable var appState = appState
        HStack {
            SourcePickerButton {
                SourcesPickerLabel(
                    title: "Open from Gallery",
                    systemImage: "photo.on.rectangle"
                )
            } picker: {
                GalleryVideoPicker(spatialVideosOnly: false) { item in
                    appState.applyFormatOptions(from: item)
                    appState.selectedItem = item
                }
            }
            
            SourcePickerButton {
                SourcesPickerLabel(
                    title: "Open from Files",
                    systemImage: "folder"
                )
            } picker: {
                FilePicker() { item in
                    appState.applyFormatOptions(from: item)
                    appState.selectedItem = item
                }
            }
            
            SourcePickerButton {
                SourcesPickerLabel(
                    title: "Enter Stream URL",
                    systemImage: "link"
                )
            } picker: {
                StreamUrlInput() { item in
                    appState.applyFormatOptions(from: item)
                    appState.selectedItem = item
                }
            }
            
            // Toggle(isOn: $areOptionsShowing.animation(.interactiveSpring)) {
            //     Image(systemName: "gearshape.fill")
            // }
            // .toggleStyle(.button)
            // .buttonBorderShape(.circle)
        }
        .popover(isPresented: $areOptionsShowing) {
            SettingsPopoverContent(appState: appState)
        }
    }
}

/// A styled button label that can be customized for source pickers.
struct SourcesPickerLabel: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        Label(title, systemImage: systemImage)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

/// A wrapper that lets a custom-designed label drive an existing picker control.
struct SourcePickerButton<Label: View, Picker: View>: View {
    let label: () -> Label
    let picker: () -> Picker
    
    var body: some View {
        label()
            .overlay {
                picker()
                    .opacity(0.01)
            }
    }
}

struct SettingsButton: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Toggle(isOn: $isPresented.animation(.interactiveSpring)) {
            Image(systemName: "gearshape.fill")
        }
        .toggleStyle(.button)
        .buttonBorderShape(.circle)
    }
}

struct SettingsPopoverContent: View {
    @Bindable var appState: OpenImmersiveAppState
    
    var body: some View {
        VStack {
            Text("Projection")
                .font(.headline.lowercaseSmallCaps())
            ProjectionPicker(projection: $appState.projection, options: [.equirectangular, .rectilinear, .appleImmersive])
            
            let projectionDescription = switch appState.projection {
            case .equirectangular: "The video will be projected onto a spherical screen.\nUse this setting for VR180 and VR360."
            case .rectilinear: "The video will be played on a rectangular plane.\nUse this setting for Spatial Video and other rectilinear videos."
            case .appleImmersive: "Use this setting for Apple Immersive Video only."
            }
            Text(projectionDescription)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
            
            if appState.projection == .equirectangular {
                Divider()
                    .padding(.vertical, 10)
                
                Text("Horizontal Field of View")
                    .font(.headline.lowercaseSmallCaps())
                FormatPicker(fieldOfView: $appState.fieldOfView, options: [65, 144, 180, 360])
                    .padding(.top, 5)
                
                Toggle(isOn: $appState.forceFov.animation(.easeInOut)) {
                    Text("Override encoded values")
                }
                .fixedSize()
            }
            
            if appState.projection != .appleImmersive {
                Divider()
                    .padding(.vertical, 10)
                
                Text("Frame Packing")
                    .font(.headline.lowercaseSmallCaps())
                FramePackingPicker(framePacking: $appState.framePacking, options: [.none, .sideBySide, .overUnder])
                let packingDescription = switch appState.framePacking {
                case .none: "Use this setting for Spatial, MV-HEVC, APMP and Mono videos."
                case .sideBySide: "Use this setting for side-by-side videos (e.g. legacy 3D VR180)."
                case .overUnder: "Use this setting for over-under videos (e.g. legacy 3D VR360)."
                }
                Text(packingDescription)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
                .padding(.vertical, 10)
            
            Text("Widgets")
                .font(.headline.lowercaseSmallCaps())
            Toggle(isOn: $appState.showTimecodeReadout.animation(.easeInOut)) {
                Text("Show timecode readout")
            }
            .fixedSize()
        }
        .padding(.vertical, 20)
        .padding()
    }
}

/// A projection type picker
struct ProjectionPicker: View {
    @Binding public var projection: ProjectionOption
    public let options: [ProjectionOption]
    
    var body: some View {
        Picker(selection: $projection.animation()) {
            ForEach(options, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        } label: {
            Text("Projection:")
        }
        .pickerStyle(.palette)
        .controlSize(.large)
        .frame(maxWidth: CGFloat(300 * options.count))
        .fixedSize()
    }
}

/// A field of view picker
struct FormatPicker: View {
    @Binding public var fieldOfView: Int
    public let options: [Int]
    
    var body: some View {
        Picker(selection: $fieldOfView) {
            ForEach(options, id: \.self) { option in
                Text("\(option)°").tag(option)
            }
        } label: {
            Text("Open as...")
        }
        .pickerStyle(.palette)
        .controlSize(.large)
        .frame(maxWidth: CGFloat(64 * options.count))
    }
}

extension VideoItem.FramePacking {
    var description: String {
        switch self {
        case .none: "Default"
        case .sideBySide: "Side-by-Side"
        case .overUnder: "Over-Under"
        }
    }
}

/// A frame packing type picker
struct FramePackingPicker: View {
    @Binding public var framePacking: VideoItem.FramePacking
    public let options: [VideoItem.FramePacking]
    
    var body: some View {
        Picker(selection: $framePacking.animation()) {
            ForEach(options, id: \.self) { option in
                Text(option.description).tag(option)
            }
        } label: {
            Text("Frame Packing:")
        }
        .pickerStyle(.palette)
        .controlSize(.large)
        .frame(maxWidth: CGFloat(300 * options.count))
        .fixedSize()
    }
}

extension VideoItem {
    /// An example VideoItem to illustrate how to load HLS stream videos from the web.
    public static let sampleHLSStream = VideoItem(
        metadata: [
            .commonIdentifierTitle: "Example Stream",
            .commonIdentifierDescription: "Local basketball player takes a shot at sunset",
        ],
        url: URL(string: "https://stream.spatialgen.com/stream/JNVc-sA-_QxdOQNnzlZTc/index.m3u8")!,
        projection: .equirectangular(fieldOfView: 180.0),
        framePacking: .none
    )
}

#Preview(windowStyle: .automatic) {
    SourcesList()
        .environment(OpenImmersiveAppState())
}
