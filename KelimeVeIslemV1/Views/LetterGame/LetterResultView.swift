//
//  LetterResultView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  LetterResultView.swift
//  KelimeVeIslem
//

import SwiftUI

struct LetterResultView: View {

    let game: LetterGame
    let message: String
    let suggestedWords: [String]
    var comboMultiplier: Int = 1
    var finalScore: Int? = nil
    let onPlayAgain: () -> Void
    let onExit: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var displayedScore: Int { finalScore ?? game.score }
    
    var body: some View {
        ZStack {
            // Semi-transparent background to allow seeing game view behind
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissing by tapping background
                }

            // Compact result card
            VStack(spacing: 0) {
                // Compact card with all result info
                VStack(spacing: 16) {
                    // Close button at top right
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                            onExit()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                    }

                    // Result icon
                    Image(systemName: game.isValid == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .scaleEffect(game.isValid == true ? 1.0 : 0.9)
                        .animation(.spring, value: game.isValid)

                    // Message - Already localized from ViewModel
                    Text(message)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Word and Score in compact horizontal layout
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Kelime")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            Text(game.playerWord.isEmpty ? "—" : game.playerWord)
                                .font(.title3.bold())
                                .foregroundColor(game.isValid == true ? Color(hex: "#FACC15") : .white)
                        }

                        Divider()
                            .background(Color.white.opacity(0.5))
                            .frame(height: 30)

                        VStack(spacing: 4) {
                            Text("Skor")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(displayedScore)")
                                .font(.title3.bold())
                                .foregroundColor(Color(hex: "#FACC15"))
                        }
                    }
                    .padding(.vertical, 8)

                    // Combo bonus line (only when a multiplier applied)
                    if comboMultiplier > 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("Kombo Bonusu: \(game.score) × \(comboMultiplier)")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                        )
                    }

                    // Compact suggestions (only show first 3)
                    if game.isValid == false && !suggestedWords.isEmpty {
                        VStack(spacing: 6) {
                            Text("Öneriler:")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.9))

                            HStack(spacing: 6) {
                                ForEach(suggestedWords.prefix(3), id: \.self) { word in
                                    Text(word)
                                        .font(.caption.monospaced())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Action buttons - more compact
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            onPlayAgain()
                        }) {
                            Text("Tekrar Oyna")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#10B981"))
                                .cornerRadius(12)
                        }

                        Button(action: {
                            dismiss()
                            onExit()
                        }) {
                            Text("Ana Menü")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [
                            game.isValid == true ? Color(hex: "#10B981").opacity(0.95) : Color(hex: "#EF4444").opacity(0.95),
                            Color(hex: "#4F46E5").opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 30)
            }
        }
        .interactiveDismissDisabled()
    }
}

// Helper View for Details
struct ResultDetailCard: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(valueColor)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
}
