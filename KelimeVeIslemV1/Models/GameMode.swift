//
//  GameMode.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//


import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case letters = "letters"
    case numbers = "numbers"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .letters:
            return "Harfler"
        case .numbers:
            return "Sayılar"
        }
    }
    
    var icon: String {
        switch self {
        case .letters:
            return "textformat.abc"
        case .numbers:
            return "number"
        }
    }
    
    var description: String {
        switch self {
        case .letters:
            return "Harflerden kelime oluştur"
        case .numbers:
            return "Hedef sayıya ulaş"
        }
    }
}
