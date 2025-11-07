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
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    game.isValid == true ? Color(hex: "#10B981").opacity(0.8) : Color(hex: "#EF4444").opacity(0.8), // Green or Red
                    Color(hex: "#4F46E5").opacity(0.8) // Indigo/Purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Result icon
                    Image(systemName: game.isValid == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(game.isValid == true ? 1.0 : 0.9)
                        .animation(.spring, value: game.isValid)
                    
                    // Message
                    Text(message)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Word and Score Card
                    VStack(spacing: 15) {
                        ResultDetailCard(
                            title: "Kelimeniz",
                            value: game.playerWord.isEmpty ? "—" : game.playerWord,
                            valueColor: game.isValid == true ? Color(hex: "#FACC15") : .white
                        )

                        ResultDetailCard(
                            title: "Skor",
                            value: "\(game.score)",
                            valueColor: Color(hex: "#FACC15")
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    // --- Suggestion Section (New) ---
                    if game.isValid == false && !suggestedWords.isEmpty {
                        VStack(spacing: 15) {
                            Text("Bu Kelimeleri Deneyin!")
                                .font(.title2.bold())
                                .foregroundColor(.white.opacity(0.95))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(suggestedWords, id: \.self) { word in
                                    Text(word)
                                        .font(.title3.monospaced())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                        .shadow(color: .black.opacity(0.2), radius: 2)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                    
                    // Available letters (for reference)
                    VStack(spacing: 10) {
                        Text("Mevcut Harfler")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Text(game.letters.map { String($0) }.joined(separator: " "))
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    
                    // Action buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            dismiss()
                            onPlayAgain()
                        }) {
                            Text("Tekrar Oyna")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#10B981"))
                                .cornerRadius(15)
                                .buttonStyle(GrowingButton())
                        }

                        Button(action: {
                            dismiss()
                            onExit()
                        }) {
                            Text("Ana Menüye Dön")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(15)
                                .buttonStyle(GrowingButton())
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                }
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
