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
                .frame(width: 256)
                .padding(20)
            
            Text("OpenImmersive \(version)")
                .font(.largeTitle)
                .accessibilityHint("A free, open source immersive video player")
                .help("A free, open source immersive video player")
                        
            Spacer()
            
            SourcesList()
                .padding(.vertical)
            
            Spacer()
            
            Text("Maintained by [Anthony Maës](https://www.linkedin.com/in/portemantho/) & [Acute Immersive 🐶](https://www.acuteimmersive.com/)")
                .padding(.horizontal, 40)
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
        }
        .padding()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            SourcesPickerControls()
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
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
