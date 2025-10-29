//
//  KelimeVeIslemApp.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//


import SwiftUI

@main
struct KelimeVeIslemApp: App {
    
    init() {
        // Initialize services on app launch
        _ = DictionaryService.shared
        _ = AudioService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
