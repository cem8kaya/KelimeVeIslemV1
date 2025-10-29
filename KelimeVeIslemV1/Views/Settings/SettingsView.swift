//
//  SettingsView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  SettingsView.swift
//  KelimeVeIslem
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioService = AudioService.shared
    @State private var settings: GameSettings
    @State private var showResetAlert = false
    
    init() {
        _settings = State(initialValue: PersistenceService.shared.loadSettings())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Form {
                    // Language Section
                    Section {
                        Picker("Language", selection: $settings.language) {
                            ForEach(GameLanguage.allCases, id: \.self) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Game Language")
                    } footer: {
                        Text("Select dictionary language for word validation")
                    }
                    
                    // Letters Game Settings
                    Section {
                        Stepper("Letter Count: \(settings.letterCount)", value: $settings.letterCount, in: 6...12)
                        
                        Stepper("Timer: \(settings.letterTimerDuration)s", value: $settings.letterTimerDuration, in: 30...120, step: 10)
                    } header: {
                        Text("Letters Game")
                    }
                    
                    // Numbers Game Settings
                    Section {
                        Picker("Difficulty", selection: $settings.difficultyLevel) {
                            ForEach(GameSettings.DifficultyLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Stepper("Timer: \(settings.numberTimerDuration)s", value: $settings.numberTimerDuration, in: 60...180, step: 10)
                    } header: {
                        Text("Numbers Game")
                    } footer: {
                        // FIX: Use localized description from GameSettings
                        Text(GameSettings.DifficultyLevel.allCases.map { $0.description }.joined(separator: " • "))
                    }
                    
                    // Audio Settings
                    Section {
                        Toggle("Sound Effects", isOn: $audioService.isSoundEnabled)
                    } header: {
                        Text("Audio")
                    }
                    
                    // Dictionary Settings
                    Section {
                        Toggle("Use Online Dictionary", isOn: $settings.useOnlineDictionary)
                    } header: {
                        Text("Dictionary")
                    } footer: {
                        Text("Enable to validate words using online dictionary API (requires internet connection)")
                    }
                    
                    // App Info
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("About")
                    }
                    
                    // Troubleshooting
                    Section {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text("Reset All Data")
                            }
                        }
                    } header: {
                        Text("Troubleshooting")
                    } footer: {
                        Text("Use this if you're experiencing crashes or freezing. This will delete all game history, statistics, and settings.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all game history, statistics, and reset settings to defaults. This cannot be undone.")
            }
        }
    }
    
    private func saveSettings() {
        do {
            try PersistenceService.shared.saveSettings(settings)
        } catch {
            print("âš ï¸ Failed to save settings: \(error)")
        }
    }
    
    private func resetAllData() {
        PersistenceService.shared.forceResetAllData()
        settings = .default
        print("✅ All data has been reset")
    }
}

#Preview {
    SettingsView()
}
