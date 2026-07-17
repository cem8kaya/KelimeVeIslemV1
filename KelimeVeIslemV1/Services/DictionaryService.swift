//
//  DictionaryService.swift
//  KelimeVeIslemV1
//
//  Created by Cem Kaya on 10/29/25.
//

//
//  DictionaryService.swift
//  KelimeVeIslem
//

import Foundation
import os

actor DictionaryService {
    
    static let shared = DictionaryService()
    
    private var turkishWords: Set<String> = []
    private var englishWords: Set<String> = []
    private var isLoaded: Bool = false
    
    private init() {
        Task {
            await loadLocalDictionaries()
        }
    }
    
    // MARK: - Local Dictionary Loading
    
    private func loadLocalDictionaries() async {
        guard !isLoaded else { return }

        // Load Turkish words
        if let turkishPath = Bundle.main.path(forResource: "turkish_words", ofType: "txt") {
            turkishWords = loadDictionarySync(from: turkishPath, language: .turkish)
        }

        // Load English words
        if let englishPath = Bundle.main.path(forResource: "english_words", ofType: "txt") {
            englishWords = loadDictionarySync(from: englishPath, language: .english)
        }
        
        // Fallback: add some common words if files don't exist
        if turkishWords.isEmpty {
            turkishWords = getDefaultTurkishWords()
        }
        
        if englishWords.isEmpty {
            englishWords = getDefaultEnglishWords()
        }
        
        isLoaded = true
        // Logger interpolation is a closure; capture counts locally so the
        // actor-isolated properties aren't referenced without explicit self.
        let turkishCount = turkishWords.count
        let englishCount = englishWords.count
        AppLog.dictionary.info("Dictionary loaded: TR=\(turkishCount), EN=\(englishCount)")
    }
    
    private func loadDictionarySync(from path: String, language: GameLanguage) -> Set<String> {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).gameUppercased(for: language) }
                .filter { !$0.isEmpty && $0.count >= 2 }

            return Set(words)
        } catch {
            AppLog.dictionary.error("Error loading dictionary from \(path): \(String(describing: error))")
            return []
        }
    }
    
    // MARK: - Validation
    
    func validateWord(_ word: String, language: GameLanguage, useOnline: Bool = false) async -> Bool {
        // Ensure dictionary is loaded
        if !isLoaded {
            await loadLocalDictionaries()
        }

        let normalized = word.gameUppercased(for: language).trimmingCharacters(in: .whitespaces)

        guard normalized.count >= 2 else { return false }

        // Check local dictionary first — a local hit is final, so an online
        // failure can never override a locally valid word.
        let wordSet = language == .turkish ? turkishWords : englishWords

        if wordSet.contains(normalized) {
            return true
        }

        // If online validation is enabled, try API with timeout
        if useOnline {
            do {
                return try await withTimeout(seconds: 5) {
                    await self.validateOnline(word: normalized, language: language)
                }
            } catch {
                AppLog.dictionary.error("Online validation timeout, falling back to local")
                return false
            }
        }

        return false
    }

    func isWordInDictionary(_ word: String, language: GameLanguage) async -> Bool {
        if !isLoaded {
            await loadLocalDictionaries()
        }

        let normalized = word.gameUppercased(for: language).trimmingCharacters(in: .whitespaces)
        let wordSet = language == .turkish ? turkishWords : englishWords
        return wordSet.contains(normalized)
    }
    
    // MARK: - Word Finding (NEW)
    
    /**
     Finds all valid words that can be constructed using the provided letters.
     
     - Parameters:
        - availableLetters: An array of single-character strings representing the available letters.
        - language: The game language to determine which dictionary to use.
        - maxCount: The maximum number of words to return.
     - Returns: An array of valid words found in the dictionary, sorted by length (longest first).
     */
    func findWords(using availableLetters: [String], language: GameLanguage, maxCount: Int = 5) async -> [String] {
        if !isLoaded {
            await loadLocalDictionaries()
        }
        
        let wordSet = language == .turkish ? turkishWords : englishWords
        let availableCharacters = availableLetters.compactMap { $0.gameUppercased(for: language).first }
        
        // Create a frequency map of available letters for fast lookup
        var availableLetterCounts: [Character: Int] = [:]
        for char in availableCharacters {
            availableLetterCounts[char, default: 0] += 1
        }
        
        // Filter the dictionary words
        let validWords = wordSet.filter { word in
            guard word.count >= 2 && word.count <= availableCharacters.count else { return false }
            
            var wordLetterCounts = availableLetterCounts
            
            // Check if the word can be built from the available letters
            for char in word {
                if let count = wordLetterCounts[char], count > 0 {
                    wordLetterCounts[char]! -= 1
                } else {
                    return false
                }
            }
            return true
        }
        
        // Sort by length (longest first) and take the top N
        let sortedWords = validWords
            .sorted { $0.count > $1.count }
        
        return Array(sortedWords.prefix(maxCount))
    }
    
    // MARK: - Online Validation (Optional)
    
    private func validateOnline(word: String, language: GameLanguage) async -> Bool {
        guard let url = makeAPIURL(for: word, language: language) else {
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            return parseAPIResponse(data, language: language)
        } catch {
            AppLog.dictionary.error("Online validation error: \(String(describing: error))")
            return false
        }
    }
    
    private func makeAPIURL(for word: String, language: GameLanguage) -> URL? {
        // Both APIs expect lowercase queries. The conversion must be
        // locale-aware for Turkish ("İ" -> "i", "I" -> "ı").
        let query = word.gameLowercased(for: language)
        switch language {
        case .turkish:
            return URL(string: "https://sozluk.gov.tr/gts?ara=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)")
        case .english:
            return URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(query)")
        }
    }

    private func parseAPIResponse(_ data: Data, language: GameLanguage) -> Bool {
        do {
            let json = try JSONSerialization.jsonObject(with: data)

            // Success responses are a non-empty array of entries for both
            // sozluk.gov.tr and dictionaryapi.dev.
            if let entries = json as? [[String: Any]] {
                return !entries.isEmpty
            }

            // sozluk.gov.tr signals "not found" with a JSON object such as
            // {"error": "Sonuç bulunamadı"} — treat any object as a miss.
            if json is [String: Any] {
                return false
            }
        } catch {
            AppLog.dictionary.error("Error parsing API response: \(String(describing: error))")
        }

        return false
    }
    
    // MARK: - Default Word Sets (Fallback)
    
    private func getDefaultTurkishWords() -> Set<String> {
        return Set([
            "ARABA", "MASA", "KEDİ", "KÖPEK", "EV", "OKUL", "KİTAP", "KALEM",
            "BAHÇE", "AĞAÇ", "GÜNEŞ", "YILDIZ", "DENİZ", "GÖKYÜZÜ", "ORMAN",
            "NEHİR", "DAĞ", "ÇOCUK", "ANNE", "BABA", "KARDEŞ", "ARKADAŞ",
            "YEMEK", "SU", "EKMEK", "MEYVE", "SEBZE", "ÇİÇEK", "KUŞ", "BALIK",
            "HAYVAN", "İNSAN", "DÜNYA", "HAYAT", "AŞIK", "SEVGİ", "MUTLU",
            "GÜZEL", "İYİ", "KÖTÜ", "BÜYÜK", "KÜÇÜK", "UZUN", "KISA", "GENİŞ",
            "DAR", "YAVAŞ", "HIZLI", "SICAK", "SOĞUK", "KIRMIZI", "MAVİ",
            "YEŞİL", "SARI", "SİYAH", "BEYAZ", "GRİ", "PEMBE", "MOR", "TURUNCU",
            "ZAMAN", "GÜN", "GECE", "SABAH", "AKŞAM", "SAAT", "DAKİKA", "SANİYE",
            "YIL", "AY", "HAFTA", "BUGÜN", "YARIN", "DÜN", "ŞİMDİ", "SONRA",
            "ÖNCE", "HEP", "HİÇ", "BAZEN", "HER", "BİR", "İKİ", "ÜÇ", "DÖRT",
            "BEŞ", "ALTI", "YEDİ", "SEKİZ", "DOKUZ", "ON", "BİN", "MİLYON"
        ])
    }
    
    private func getDefaultEnglishWords() -> Set<String> {
        return Set([
            "CAR", "TABLE", "CAT", "DOG", "HOUSE", "SCHOOL", "BOOK", "PEN",
            "GARDEN", "TREE", "SUN", "STAR", "SEA", "SKY", "FOREST",
            "RIVER", "MOUNTAIN", "CHILD", "MOTHER", "FATHER", "BROTHER", "FRIEND",
            "FOOD", "WATER", "BREAD", "FRUIT", "VEGETABLE", "FLOWER", "BIRD", "FISH",
            "ANIMAL", "PERSON", "WORLD", "LIFE", "LOVE", "HAPPY",
            "BEAUTIFUL", "GOOD", "BAD", "BIG", "SMALL", "LONG", "SHORT", "WIDE",
            "NARROW", "SLOW", "FAST", "HOT", "COLD", "RED", "BLUE",
            "GREEN", "YELLOW", "BLACK", "WHITE", "GRAY", "PINK", "PURPLE", "ORANGE",
            "TIME", "DAY", "NIGHT", "MORNING", "EVENING", "HOUR", "MINUTE", "SECOND",
            "YEAR", "MONTH", "WEEK", "TODAY", "TOMORROW", "YESTERDAY", "NOW", "LATER",
            "BEFORE", "ALWAYS", "NEVER", "SOMETIMES", "EVERY", "ONE", "TWO", "THREE",
            "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "THOUSAND"
        ])
    }
}
