//
//  MainMenu.swift
//  OpenImmersiveApp
//
//  Created by Anthony Maës (Acute Immersive) on 10/16/24.
//

import SwiftUI

/// A simple window menu welcoming users to the app.
struct MainMenu: View {
    var body: some View {
        VStack {
            Image("new-logo-flat")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(8)
            Text("OpenImmersive \(version)")
                .font(.largeTitle)
                .accessibilityHint("A free, open source immersive video player")
                .help("A free, open source immersive video player")
                        
            Spacer()
            
            SourcesList()
                .padding(.vertical)
        }
        .padding()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            SourcesPickerControls()
                .padding(16)
                .glassBackgroundEffect()
                .cornerRadius(120)
        }
    }
    
    var version: String {
        get {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        }
    }
}

#Preview(windowStyle: .automatic) {
    MainMenu()
        .environment(OpenImmersiveAppState())
}
