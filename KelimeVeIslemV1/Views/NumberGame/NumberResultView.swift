//
//  NumberResultView.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  NumberResultView.swift
//  KelimeVeIslem
//

import SwiftUI

struct NumberResultView: View {
    
    let game: NumberGame
    let message: String
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var isPerfect: Bool {
        game.playerResult == game.targetNumber
    }
    
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
                    Image(systemName: isPerfect ? "star.fill" : "target")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    // Message - Already localized from ViewModel
                    Text(message)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Target, Result, and Score in compact layout
                    HStack(spacing: 15) {
                        VStack(spacing: 4) {
                            Text("Hedef")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(game.targetNumber)")
                                .font(.title3.bold())
                                .foregroundColor(.yellow)
                        }

                        Divider()
                            .background(Color.white.opacity(0.5))
                            .frame(height: 30)

                        if let result = game.playerResult {
                            VStack(spacing: 4) {
                                Text("Sonuç")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(result)")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }

                            Divider()
                                .background(Color.white.opacity(0.5))
                                .frame(height: 30)
                        }

                        VStack(spacing: 4) {
                            Text("Skor")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(game.score)")
                                .font(.title3.bold())
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.vertical, 8)

                    // Compact solution display
                    if !game.playerSolution.isEmpty {
                        VStack(spacing: 4) {
                            Text("Çözüm:")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.9))
                            Text(game.playerSolution)
                                .font(.caption.monospaced())
                                .foregroundColor(.white)
                                .lineLimit(2)
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
                                .background(Color.green)
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
                            isPerfect ? Color.green.opacity(0.95) : Color.orange.opacity(0.95),
                            Color.purple.opacity(0.95)
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

#Preview {
    NumberResultView(
        game: NumberGame(
            numbers: [25, 50, 3, 6, 7, 8],
            targetNumber: 456
        ),
        message: "Perfect match!",
        onPlayAgain: {},
        onExit: {}
    )
}

