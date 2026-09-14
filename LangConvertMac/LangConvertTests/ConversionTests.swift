import XCTest
@testable import LangConvert

final class ConversionTests: XCTestCase {
    
    let service = ConversionService.shared
    
    // MARK: - Character Map Tests
    
    func testEnglishToHebrewMapComplete() {
        let expectedMappings: [Character: Character] = [
            "q": "/", "w": "'", "e": "ק", "r": "ר", "t": "א", "y": "ט", "u": "ו",
            "i": "ן", "o": "ם", "p": "פ", "a": "ש", "s": "ד", "d": "ג", "f": "כ",
            "g": "ע", "h": "י", "j": "ח", "k": "ל", "l": "ך", "z": "ז", "x": "ס",
            "c": "ב", "v": "ה", "b": "נ", "n": "מ", "m": "צ", ",": "ת", ".": "ץ",
            "/": ".", ";": "ף", "'": ","
        ]
        
        XCTAssertEqual(service.englishToHebrew.count, expectedMappings.count)
        
        for (english, hebrew) in expectedMappings {
            XCTAssertEqual(service.englishToHebrew[english], hebrew,
                          "Expected '\(english)' to map to '\(hebrew)'")
        }
    }
    
    func testHebrewToEnglishMapComplete() {
        let expectedMappings: [Character: Character] = [
            "/": "q", "'": "w", "ק": "e", "ר": "r", "א": "t", "ט": "y", "ו": "u",
            "ן": "i", "ם": "o", "פ": "p", "ש": "a", "ד": "s", "ג": "d", "כ": "f",
            "ע": "g", "י": "h", "ח": "j", "ל": "k", "ך": "l", "ז": "z", "ס": "x",
            "ב": "c", "ה": "v", "נ": "b", "מ": "n", "צ": "m", "ת": ",", "ץ": ".",
            ".": "/", "ף": ";", ",": "'"
        ]
        
        XCTAssertEqual(service.hebrewToEnglish.count, expectedMappings.count)
        
        for (hebrew, english) in expectedMappings {
            XCTAssertEqual(service.hebrewToEnglish[hebrew], english,
                          "Expected '\(hebrew)' to map to '\(english)'")
        }
    }
    
    func testMapsAreInverses() {
        for (english, hebrew) in service.englishToHebrew {
            if let reverseEnglish = service.hebrewToEnglish[hebrew] {
                XCTAssertEqual(english, reverseEnglish,
                              "Maps should be inverses: \(english) -> \(hebrew) -> \(reverseEnglish)")
            }
        }
    }
    
    // MARK: - Character Classification Tests
    
    func testContainsHebrew() {
        XCTAssertTrue(service.containsHebrew("שלום"))
        XCTAssertTrue(service.containsHebrew("hello שלום"))
        XCTAssertTrue(service.containsHebrew("א"))
        XCTAssertFalse(service.containsHebrew("hello"))
        XCTAssertFalse(service.containsHebrew("123"))
        XCTAssertFalse(service.containsHebrew(""))
    }
    
    func testContainsEnglish() {
        XCTAssertTrue(service.containsEnglish("hello"))
        XCTAssertTrue(service.containsEnglish("HELLO"))
        XCTAssertTrue(service.containsEnglish("שלום hello"))
        XCTAssertFalse(service.containsEnglish("שלום"))
        XCTAssertFalse(service.containsEnglish("123"))
        XCTAssertFalse(service.containsEnglish(""))
    }
    
    func testIsWordCharacter() {
        XCTAssertTrue(service.isWordCharacter("a"))
        XCTAssertTrue(service.isWordCharacter("Z"))
        XCTAssertTrue(service.isWordCharacter("א"))
        XCTAssertTrue(service.isWordCharacter("ת"))
        XCTAssertFalse(service.isWordCharacter(" "))
        XCTAssertFalse(service.isWordCharacter("1"))
        XCTAssertFalse(service.isWordCharacter("."))
        XCTAssertFalse(service.isWordCharacter(","))
    }
    
    // MARK: - Pure Hebrew Conversion Tests
    
    func testPureHebrewToEnglish() {
        // "שלום" typed on Hebrew keyboard should become "akuo" on English
        let result = service.convert("שלום")
        XCTAssertEqual(result, "akuo")
    }
    
    func testHebrewSentence() {
        // Hebrew words with spaces preserved
        let result = service.convert("שלום עולם")
        XCTAssertEqual(result, "akuo gukn")
    }
    
    // MARK: - Pure English Conversion Tests
    
    func testPureEnglishToHebrew() {
        // "hello" typed on English keyboard should become "יךךם" on Hebrew
        let result = service.convert("hello")
        XCTAssertEqual(result, "יךךם")
    }
    
    func testEnglishSentence() {
        let result = service.convert("hello world")
        XCTAssertEqual(result, "יךךם שםרךג")
    }
    
    // MARK: - Uppercase Handling Tests
    
    func testUppercasePreservedByDefault() {
        // By default, uppercase letters should be preserved (not converted)
        let result = service.convert("Hello")
        XCTAssertEqual(result, "Hךךם")
    }
    
    func testUppercaseConvertedWithFlag() {
        // With convertUppercase=true, uppercase should be converted
        let result = service.convert("Hello", convertUppercase: true)
        XCTAssertEqual(result, "יךךם")
    }
    
    func testAllCapsPreservedWithSmartMode() {
        // ALL CAPS (like NATO) should be preserved in smart mode
        let result = service.convert("NATO", convertUppercase: false, smartTitleCase: true)
        XCTAssertEqual(result, "NATO")
    }
    
    func testMixedCaseConvertedWithSmartMode() {
        // Mixed case (like "Hello") should be converted in smart mode
        let result = service.convert("Hello", convertUppercase: false, smartTitleCase: true)
        XCTAssertEqual(result, "יךךם")
    }
    
    func testAllCapsConvertedWithForceMode() {
        // Even ALL CAPS should be converted with convertUppercase=true
        let result = service.convert("NATO", convertUppercase: true)
        XCTAssertEqual(result, "משאם")
    }
    
    // MARK: - Mixed Hebrew/English Tests
    
    func testMixedWordDefaultBehavior() {
        // Mixed word like "Hשלום" - default behavior treats as Hebrew->English
        let result = service.convert("Hשלום")
        XCTAssertEqual(result, "Hakuo")
    }
    
    func testMixedWordWithSmartMode() {
        // With smart mode, English prefix should be converted to Hebrew
        let result = service.convert("Hשלום", convertUppercase: false, smartTitleCase: true)
        XCTAssertEqual(result, "ישלום")
    }
    
    // MARK: - Separator Preservation Tests
    
    func testSeparatorsPreserved() {
        let result = service.convert("hello, world!")
        XCTAssertEqual(result, "יךךם, שםרךג!")
    }
    
    func testNumbersPreserved() {
        let result = service.convert("hello123world")
        XCTAssertEqual(result, "יךךם123שםרךג")
    }
    
    func testPunctuationPreserved() {
        let result = service.convert("hello. world!")
        XCTAssertEqual(result, "יךךם. שםרךג!")
    }
    
    // MARK: - ProcessWord Direct Tests
    
    func testProcessWordPureHebrew() {
        let result = service.processWord("שלום", convertUppercase: false, smartTitleCase: false)
        XCTAssertEqual(result, "akuo")
    }
    
    func testProcessWordPureEnglish() {
        let result = service.processWord("hello", convertUppercase: false, smartTitleCase: false)
        XCTAssertEqual(result, "יךךם")
    }
    
    func testProcessWordNumbers() {
        let result = service.processWord("123", convertUppercase: false, smartTitleCase: false)
        XCTAssertEqual(result, "123")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyString() {
        let result = service.convert("")
        XCTAssertEqual(result, "")
    }
    
    func testWhitespaceOnly() {
        let result = service.convert("   ")
        XCTAssertEqual(result, "   ")
    }
    
    func testSingleCharacter() {
        XCTAssertEqual(service.convert("a"), "ש")
        XCTAssertEqual(service.convert("א"), "t")
    }
    
    func testSpecialCharactersMapping() {
        XCTAssertEqual(service.convert(";"), "ף")
        XCTAssertEqual(service.convert(","), "ת")
    }
    
    // MARK: - Real-World Scenarios
    
    func testTypicalGibberishFix() {
        // User meant to type "שלום" in Hebrew but typed in English mode
        // Result: "akuo" - fixing this back to Hebrew
        let gibberish = "akuo"
        let fixed = service.convert(gibberish)
        XCTAssertEqual(fixed, "שלום")
    }
    
    func testReverseGibberishFix() {
        // User meant to type "hello" in English but typed in Hebrew mode
        // Result: "יךךם" - fixing this back to English
        let gibberish = "יךךם"
        let fixed = service.convert(gibberish)
        XCTAssertEqual(fixed, "hello")
    }
    
    func testEmailTypedInWrongLanguage() {
        // User typed email in Hebrew mode
        let gibberish = "אקדא@קסשצפךקץבםצ"
        let fixed = service.convert(gibberish)
        XCTAssertEqual(fixed, "test@example.com")
    }
}
