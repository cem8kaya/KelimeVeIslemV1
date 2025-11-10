//
//  DailyChallengeView.swift
//  KelimeVeIslemV1
//

import SwiftUI

struct DailyChallengeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0EA5E9"), Color(hex: "#0369A1")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 50))
                        .foregroundColor(.white)

                    Text("Günlük Meydan Okuma")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Her gün yeni bir zorlukla puan toplayın. Bugünün meydan okumasını şimdi deneyin!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    PrimaryGameButton(
                        title: "Başla",
                        icon: "play.fill",
                        color: .green
                    ) {
                        // TODO: Navigate to actual daily challenge flow
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Günlük")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            })
        }
    }
}

#Preview {
    DailyChallengeView()
}
