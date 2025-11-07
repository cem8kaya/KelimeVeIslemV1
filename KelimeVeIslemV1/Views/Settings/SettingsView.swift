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
    @ObservedObject private var themeManager = ThemeManager.shared
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
                        Picker("Dil", selection: $settings.language) {
                            ForEach(GameLanguage.allCases, id: \.self) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Oyun Dili")
                    } footer: {
                        Text("Kelime doğrulama için sözlük dilini seçin")
                    }

                    // Letters Game Settings
                    Section {
                        Stepper("Harf Sayısı: \(settings.letterCount)", value: $settings.letterCount, in: 6...12)

                        Stepper("Süre: \(settings.letterTimerDuration)s", value: $settings.letterTimerDuration, in: 30...120, step: 10)
                    } header: {
                        Text("Harfler Oyunu")
                    }

                    // Numbers Game Settings
                    Section {
                        Picker("Zorluk", selection: $settings.difficultyLevel) {
                            ForEach(GameSettings.DifficultyLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        Stepper("Süre: \(settings.numberTimerDuration)s", value: $settings.numberTimerDuration, in: 60...180, step: 10)
                    } header: {
                        Text("Sayılar Oyunu")
                    } footer: {
                        // FIX: Use localized description from GameSettings
                        Text(GameSettings.DifficultyLevel.allCases.map { $0.description }.joined(separator: " • "))
                    }

                    // Theme Settings
                    Section {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    themeManager.currentTheme = theme
                                    settings.selectedTheme = theme.rawValue
                                }
                            } label: {
                                HStack {
                                    Image(systemName: theme.icon)
                                        .font(.title3)
                                        .foregroundColor(themePreviewColor(for: theme))
                                        .frame(width: 30)

                                    Text(theme.displayName)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if themeManager.currentTheme == theme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Tema")
                    } footer: {
                        Text("Oyun ara yüzü için renk temasını seçin")
                    }

                    // Audio Settings
                    Section {
                        Toggle("Ses Efektleri", isOn: $audioService.isSoundEnabled)
                    } header: {
                        Text("Ses")
                    }

                    // Dictionary Settings
                    Section {
                        Toggle("Çevrimiçi Sözlük Kullan", isOn: $settings.useOnlineDictionary)
                    } header: {
                        Text("Sözlük")
                    } footer: {
                        Text("Kelimeleri çevrimiçi sözlük API'si ile doğrulamak için etkinleştirin (internet bağlantısı gerektirir)")
                    }

                    // App Info
                    Section {
                        HStack {
                            Text("Sürüm")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Hakkında")
                    }

                    // Troubleshooting
                    Section {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text("Tüm Verileri Sıfırla")
                            }
                        }
                    } header: {
                        Text("Sorun Giderme")
                    } footer: {
                        Text("Çökme veya donma yaşıyorsanız bunu kullanın. Bu işlem tüm oyun geçmişini, istatistikleri ve ayarları silecektir.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .alert("Tüm Veriler Sıfırlansın mı?", isPresented: $showResetAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sıfırla", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Bu işlem tüm oyun geçmişinizi, istatistiklerinizi kalıcı olarak silecek ve ayarları varsayılana döndürecektir. Bu işlem geri alınamaz.")
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
        themeManager.currentTheme = .classic
        print("✅ All data has been reset")
    }

    private func themePreviewColor(for theme: AppTheme) -> Color {
        switch theme {
        case .classic:
            return Color(hex: "#8B5CF6")
        case .dark:
            return Color(hex: "#818CF8")
        case .ocean:
            return Color(hex: "#22D3EE")
        case .sunset:
            return Color(hex: "#FB923C")
        }
    }
}

#Preview {
    SettingsView()
}
