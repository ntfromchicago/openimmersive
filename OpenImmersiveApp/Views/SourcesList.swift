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
    @State private var isInfoPresented: Bool = false
    private let infoMessage = "This player supports Spatial, AIV Immersive, MV-HEVC, Side-By-Side and Over-Under videos."
    
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
            }
            
            let videoTitle = selectedItem.metadata[.commonIdentifierTitle] ?? "<NONE>"
            let fieldOfView = appState.projection == .equirectangular ? " \(appState.fieldOfView)°" : ""
            let framePacking = appState.projection == .appleImmersive || appState.framePacking == .none ? "" : "(\(appState.framePacking.description))"
            
            Spacer()
            
            HStack(alignment: .center) {
                InfoButton {
                    isInfoPresented = true
                }
                
                Spacer()
                VStack() {
                    Text("**\(videoTitle)**")
                    Text("Play as **\(appState.projection.rawValue)\(fieldOfView)** \(framePacking)")
                }
                Spacer()
                SettingsButton(isPresented: $areOptionsShowing)
                    .help("Video format and projection options")
                    .popover(isPresented: $areOptionsShowing) {
                        SettingsPopoverContent(appState: appState)
                            .frame(width: 640, height: 640)
                    }
            }
            
            Divider()
                .padding(.vertical)
            
            Text("Maintained by [Anthony Maës](https://www.linkedin.com/in/portemantho/) & [Acute Immersive 🐶](https://www.acuteimmersive.com/)")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // Text("\(Image(systemName: "info.circle")) This player supports Spatial Video, AIV Immersive Videos, MV-HEVC, side-by-side and over-under.\nUse the gear button to select the correct format and projection.")
            //     .font(.callout)
            //     .fixedSize(horizontal: false, vertical: true)
            //     .multilineTextAlignment(.center)
            //     .padding()
        }
        .alert("Supported Formats", isPresented: $isInfoPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(infoMessage)
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
        HStack(spacing: 16) {
            SourcePickerButton {
                SourcesPickerLabel(
                    title: "Open Gallery",
                    systemImage: "photo.on.rectangle"
                )
            } picker: {
                GalleryVideoPicker(spatialVideosOnly: false) { item in
                    appState.applyFormatOptions(from: item)
                    appState.selectedItem = item
                }
            }
            .help("Open Gallery")
            
            SourcePickerButton {
                SourcesPickerLabel(
                    title: "Open File",
                    systemImage: "folder"
                )
            } picker: {
                FilePicker() { item in
                    appState.applyFormatOptions(from: item)
                    appState.selectedItem = item
                }
            }
            .help("Open File")
            
            SourcePickerButton {
                SourcesPickerLabel(
                    title: "Open Stream URL",
                    systemImage: "link"
                )
            } picker: {
                StreamUrlInput() { item in
                    appState.applyFormatOptions(from: item)
                    appState.selectedItem = item
                }
            }
            .help("Open Stream URL")

            
            // Toggle(isOn: $areOptionsShowing.animation(.interactiveSpring)) {
            //     Image(systemName: "gearshape.fill")
            // }
            // .toggleStyle(.button)
            // .buttonBorderShape(.circle)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// A styled button label that can be customized for source pickers.
struct SourcesPickerLabel: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 28, weight: .regular))
            .foregroundStyle(.primary)
            .frame(width: 64, height: 64)
            .background(.thinMaterial, in: Circle())
            .accessibilityLabel(Text(title))
    }
}

/// A wrapper that lets a custom-designed label drive an existing picker control.
struct SourcePickerButton<Label: View, Picker: View>: View {
    let label: () -> Label
    let picker: () -> Picker
    @State private var isHovered: Bool = false
    @State private var isFocused: Bool = false
    @GestureState private var isPressed: Bool = false
    
    var body: some View {
        let isHighlighted = isPressed || isFocused || isHovered
        let highlightOpacity: Double = isPressed ? 0.18 : isHighlighted ? 0.1 : 0.0

        ZStack {
            label()
                .scaleEffect(isHighlighted ? 1.06 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: isHighlighted)
        }
        .contentShape(Circle())
        .overlay {
            Circle()
                .fill(.white.opacity(highlightOpacity))
        }
        .overlay {
            picker()
                .opacity(0.01)
                .contentShape(Circle())
                .onHover { isHovered = $0 }
                .focusable()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isPressed) { _, state, _ in
                            state = true
                        }
                )
        }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .animation(.easeInOut(duration: 0.12), value: isFocused)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
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

struct InfoButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle.fill")
        }
        .buttonBorderShape(.circle)
    }
}

struct SettingsPopoverContent: View {
    @Bindable var appState: OpenImmersiveAppState
    
    var body: some View {
        VStack {
            HStack {
                Text("Projection").bold()
                Spacer()
            }
            ProjectionPicker(projection: $appState.projection, options: [.equirectangular, .rectilinear, .appleImmersive])
            let projectionDescription = switch appState.projection {
            case .equirectangular: "Project video onto a spherical screen.\nFor VR180 and VR360."
            case .rectilinear: "Project video onto a rectangular plane.\nFor Spatial Video and 2D videos."
            case .appleImmersive: "For Apple Immersive Video only."
            }
                
            Text(projectionDescription)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(8)
            
            if appState.projection == .equirectangular {
                Spacer()
                Divider()
                    .padding(.vertical, 8)
                HStack {
                    Text("Horizontal Field of View").bold()
                    Spacer()
                }
                HStack {
                    FormatPicker(fieldOfView: $appState.fieldOfView, options: [65, 144, 180, 360])
                        .padding(.top, 4)
                    Spacer()
                    Toggle(isOn: $appState.forceFov.animation(.easeInOut)) {
                        Text("Override encoded values")
                    }
                    .fixedSize()
                }
            } else {
                Spacer()
            }
            
            if appState.projection != .appleImmersive {
                Divider()
                    .padding(.vertical, 8)
                HStack {
                Text("Frame Packing").bold()
                    Spacer()
            }
                FramePackingPicker(framePacking: $appState.framePacking, options: [.none, .sideBySide, .overUnder])
                let packingDescription = switch appState.framePacking {
                case .none: "e.g. Spatial, MV-HEVC, APMP and Mono videos"
                case .sideBySide: "e.g. legacy 3D VR180 videos"
                case .overUnder: "e.g. legacy 3D VR360 videos"
                }
                Text(packingDescription)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(8)
            }
            
            Divider()
                .padding(.vertical)
            HStack {
                Text("Widgets").bold()
                Spacer()
                Toggle(isOn: $appState.showTimecodeReadout.animation(.easeInOut)) {
                    Text("Show timecode readout")
                }
                .fixedSize()
            }
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
        // .frame(maxWidth: CGFloat(300 * options.count))
        // .fixedSize()
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
        // .controlSize(.large)
        // .frame(maxWidth: CGFloat(64 * options.count))
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
        // .controlSize(.large)
        // .frame(maxWidth: CGFloat(300 * options.count))
        // .fixedSize()
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

