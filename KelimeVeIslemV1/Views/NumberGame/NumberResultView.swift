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
            // Background
            LinearGradient(
                colors: [
                    isPerfect ? Color.green.opacity(0.6) : Color.orange.opacity(0.6),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Result icon
                Image(systemName: isPerfect ? "star.fill" : "target")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                // Message
                Text(message)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Target and Result
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("Hedef")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Text("\(game.targetNumber)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.yellow)
                    }

                    if let result = game.playerResult {
                        VStack(spacing: 8) {
                            Text("Sonucunuz")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))

                            Text("\(result)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Difference
                if let result = game.playerResult {
                    let diff = abs(game.targetNumber - result)
                    if diff > 0 {
                        Text("Fark: \(diff)")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                // Score
                VStack(spacing: 10) {
                    Text("Skor")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(game.score)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                // Solution
                if !game.playerSolution.isEmpty {
                    VStack(spacing: 10) {
                        Text("Çözümünüz")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(game.playerSolution)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal)
                        }
                    }
                }

                // Available numbers (for reference)
                VStack(spacing: 10) {
                    Text("Mevcut Sayılar")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    Text(game.numbers.map { String($0) }.joined(separator: ", "))
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
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
                            .background(Color.green)
                            .cornerRadius(15)
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
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
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

