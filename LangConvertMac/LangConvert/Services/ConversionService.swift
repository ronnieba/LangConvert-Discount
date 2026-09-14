import Foundation

/// Core service for Hebrew ↔ English keyboard layout conversion
/// Matches the Windows AutoHotkey implementation logic exactly
public final class ConversionService {
    
    public static let shared = ConversionService()
    
    /// Map English keyboard characters to Hebrew equivalents
    public let englishToHebrew: [Character: Character] = [
        "q": "/", "w": "'", "e": "ק", "r": "ר", "t": "א", "y": "ט", "u": "ו",
        "i": "ן", "o": "ם", "p": "פ", "a": "ש", "s": "ד", "d": "ג", "f": "כ",
        "g": "ע", "h": "י", "j": "ח", "k": "ל", "l": "ך", "z": "ז", "x": "ס",
        "c": "ב", "v": "ה", "b": "נ", "n": "מ", "m": "צ", ",": "ת", ".": "ץ",
        "/": ".", ";": "ף", "'": ","
    ]
    
    /// Map Hebrew keyboard characters to English equivalents
    public let hebrewToEnglish: [Character: Character] = [
        "/": "q", "'": "w", "ק": "e", "ר": "r", "א": "t", "ט": "y", "ו": "u",
        "ן": "i", "ם": "o", "פ": "p", "ש": "a", "ד": "s", "ג": "d", "כ": "f",
        "ע": "g", "י": "h", "ח": "j", "ל": "k", "ך": "l", "ז": "z", "ס": "x",
        "ב": "c", "ה": "v", "נ": "b", "מ": "n", "צ": "m", "ת": ",", "ץ": ".",
        ".": "/", "ף": ";", ",": "'"
    ]
    
    /// Set of all mapped characters (for word boundary detection)
    private let mappedCharacters: Set<Character>
    
    private init() {
        var chars = Set<Character>()
        for key in ConversionService.staticEnglishToHebrew.keys {
            chars.insert(key)
        }
        for key in ConversionService.staticHebrewToEnglish.keys {
            chars.insert(key)
        }
        self.mappedCharacters = chars
    }
    
    /// Static maps for use in init
    private static let staticEnglishToHebrew: [Character: Character] = [
        "q": "/", "w": "'", "e": "ק", "r": "ר", "t": "א", "y": "ט", "u": "ו",
        "i": "ן", "o": "ם", "p": "פ", "a": "ש", "s": "ד", "d": "ג", "f": "כ",
        "g": "ע", "h": "י", "j": "ח", "k": "ל", "l": "ך", "z": "ז", "x": "ס",
        "c": "ב", "v": "ה", "b": "נ", "n": "מ", "m": "צ", ",": "ת", ".": "ץ",
        "/": ".", ";": "ף", "'": ","
    ]
    
    private static let staticHebrewToEnglish: [Character: Character] = [
        "/": "q", "'": "w", "ק": "e", "ר": "r", "א": "t", "ט": "y", "ו": "u",
        "ן": "i", "ם": "o", "פ": "p", "ש": "a", "ד": "s", "ג": "d", "כ": "f",
        "ע": "g", "י": "h", "ח": "j", "ל": "k", "ך": "l", "ז": "z", "ס": "x",
        "ב": "c", "ה": "v", "נ": "b", "מ": "n", "צ": "m", "ת": ",", "ץ": ".",
        ".": "/", "ף": ";", ",": "'"
    ]
    
    // MARK: - Public API
    
    /// Convert text using word-by-word processing
    /// - Parameters:
    ///   - text: The input text to convert
    ///   - convertUppercase: Whether to convert uppercase English letters to Hebrew (Caps Lock fix)
    ///   - smartTitleCase: Whether to use smart title/prefix mode (preserves all-caps acronyms like NATO)
    /// - Returns: The converted text
    public func convert(
        _ text: String,
        convertUppercase: Bool = false,
        smartTitleCase: Bool = false
    ) -> String {
        var result = ""
        var currentWord = ""
        
        for char in text {
            if isWordCharacter(char) {
                currentWord.append(char)
            } else {
                if !currentWord.isEmpty {
                    result += processWord(
                        currentWord,
                        convertUppercase: convertUppercase,
                        smartTitleCase: smartTitleCase
                    )
                    currentWord = ""
                }
                result.append(char)
            }
        }
        
        if !currentWord.isEmpty {
            result += processWord(
                currentWord,
                convertUppercase: convertUppercase,
                smartTitleCase: smartTitleCase
            )
        }
        
        return result
    }
    
    // MARK: - Word Processing
    
    /// Process a single word according to the conversion rules
    /// Matches Windows ProcessWord() logic exactly
    public func processWord(
        _ word: String,
        convertUppercase: Bool,
        smartTitleCase: Bool
    ) -> String {
        let hasHeb = containsHebrew(word)
        let hasEng = containsEnglish(word)
        
        // Case 1: Pure Hebrew → Convert to English
        if hasHeb && !hasEng {
            return transformString(word, using: hebrewToEnglish)
        }
        
        // Case 2: Pure English → Convert to Hebrew
        if !hasHeb && hasEng {
            let isAllCaps = word == word.uppercased() && word.contains(where: { $0.isUppercase })
            
            var convertUpperToHebrew = false
            if convertUppercase {
                convertUpperToHebrew = true
            } else if smartTitleCase {
                if !isAllCaps {
                    convertUpperToHebrew = true
                }
            }
            
            return transformToHebrew(word, convertUpper: convertUpperToHebrew)
        }
        
        // Case 3: Mixed Hebrew + English
        if hasHeb && hasEng {
            if smartTitleCase || convertUppercase {
                return transformToHebrew(word, convertUpper: true)
            }
            return transformString(word, using: hebrewToEnglish)
        }
        
        return word
    }
    
    // MARK: - Character Classification
    
    /// Check if a character is part of a word
    /// Includes: A-Z, a-z, Hebrew letters, AND any character that appears in the maps
    /// (e.g., apostrophe, slash, semicolon, comma, period which are mapped keys)
    public func isWordCharacter(_ char: Character) -> Bool {
        if mappedCharacters.contains(char) {
            return true
        }
        
        guard let scalar = char.unicodeScalars.first else { return false }
        let code = scalar.value
        
        return (code >= 65 && code <= 90) ||      // A-Z
               (code >= 97 && code <= 122) ||     // a-z
               (code >= 0x0590 && code <= 0x05FF) // Hebrew range
    }
    
    /// Check if string contains Hebrew characters
    public func containsHebrew(_ str: String) -> Bool {
        for char in str {
            guard let scalar = char.unicodeScalars.first else { continue }
            let code = scalar.value
            if code >= 0x0590 && code <= 0x05FF {
                return true
            }
        }
        return false
    }
    
    /// Check if string contains English letters
    public func containsEnglish(_ str: String) -> Bool {
        for char in str {
            if char.isLetter && char.isASCII {
                return true
            }
        }
        return false
    }
    
    // MARK: - Transformation
    
    /// Transform string using a character map
    private func transformString(_ str: String, using map: [Character: Character]) -> String {
        var result = ""
        for char in str {
            let lower = Character(char.lowercased())
            if let mapped = map[lower] {
                result.append(mapped)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    /// Transform string to Hebrew with optional uppercase handling
    private func transformToHebrew(_ str: String, convertUpper: Bool) -> String {
        var result = ""
        for char in str {
            let isUpper = char.isUppercase
            
            if isUpper && !convertUpper {
                result.append(char)
            } else {
                let lower = Character(char.lowercased())
                if let mapped = englishToHebrew[lower] {
                    result.append(mapped)
                } else {
                    result.append(char)
                }
            }
        }
        return result
    }
}
