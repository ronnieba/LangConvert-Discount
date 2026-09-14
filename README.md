# LangConvert - Discount Bank Edition 🛠️

כלי עזר לתיקון טקסט שהוקלד בשפה הלא נכונה (ג'יבריש), פותח והותאם במיוחד עבור סביבת העבודה של בנק דיסקונט.

**זמין עבור Windows ו-macOS**

---

## 📱 macOS Edition (גרסת macOS)

אפליקציית macOS מקורית הכתובה ב-Swift/SwiftUI, עם ממשק יפה ומודרני.

### ✨ פיצ'רים
*   **תיקון מהיר:** המרת טקסט מעברית לאנגלית ולהפך בלחיצה על `⌃⌥1` (Control+Option+1)
*   **Menu Bar App:** אפליקציה קלילה שחיה בשורת התפריטים
*   **תמיכה ב-Dark/Light Mode:** עיצוב מותאם אוטומטית לערכת הנושא של המערכת
*   **ממשק בעברית ואנגלית:** אפשרות להחלפת שפת הממשק
*   **קיצור מקלדת מותאם:** אפשרות לשנות את קיצור המקלדת לפי העדפה
*   **הפעלה אוטומטית:** אפשרות להפעלה עם עליית המחשב (Open at Login)
*   **שמירה על הלוח:** הטקסט המקורי בלוח נשמר ומשוחזר לאחר ההמרה
*   **מצב Caps Lock חכם:** המרת אותיות רישיות לעברית
*   **מצב תחיליות חכם:** שמירה על ראשי תיבות באנגלית (כמו NATO)

### 🔐 הרשאת נגישות (Accessibility Permission)

האפליקציה דורשת הרשאת נגישות כדי:
- לרשום קיצורי מקשים גלובליים
- לבצע פעולות העתקה והדבקה אוטומטיות

**כיצד להפעיל:**
1. פתח **System Settings** (הגדרות מערכת)
2. עבור ל-**Privacy & Security** → **Accessibility**
3. לחץ על הכפתור **+** והוסף את LangConvert
4. הפעל את הסימון ליד LangConvert

### ⚠️ מצב מוגבל (Fallback Mode)

אם הרשאת נגישות לא פעילה (או `AXIsProcessTrusted()` מחזיר false למרות שההרשאה מופעלת), האפליקציה עוברת למצב מוגבל:

**זרימת עבודה במצב מוגבל:**
1. סמן טקסט ולחץ `⌘C` (העתק) ידנית
2. לחץ על קיצור המקלדת (⌃⌥1)
3. לחץ `⌘V` (הדבק) ידנית

במצב זה הלוח **לא** משוחזר אוטומטית - הטקסט המומר נשאר בלוח.

### 🏢 מחשבים ארגוניים / Managed Macs

במחשבים עם MDM או הגדרות אבטחה ארגוניות, יתכן מצב בו:
- הסימון ב-System Settings מופעל
- אבל `AXIsProcessTrusted()` עדיין מחזיר `false`

**פתרונות מומלצים:**

1. **התקנה קבועה ב-/Applications:**
   ```bash
   # בנה את האפליקציה ב-Xcode
   # העתק את LangConvert.app ל:
   /Applications/LangConvert.app
   ```

2. **הסר והוסף מחדש ב-Accessibility:**
   - פתח System Settings → Privacy & Security → Accessibility
   - הסר את LangConvert מהרשימה (לחץ -)
   - הוסף את `/Applications/LangConvert.app` (לחץ +)
   - ודא שהסימון מופעל

3. **חתימה עם Apple Development Team (מומלץ):**
   - ב-Xcode: Signing & Capabilities → Team → בחר צוות פיתוח
   - זה מבטיח ש-TCC יזהה את האפליקציה נכון

4. **Debug builds:**
   - Ad-hoc signed builds (`CODE_SIGN_IDENTITY=-`) עלולים לאבד הרשאות אחרי rebuild
   - לפיתוח מקומי זה תקין, אבל לשימוש יומיומי מומלץ להתקין copy קבוע

### 🚀 התקנה והרצה

**דרישות:**
- macOS 13.0 (Ventura) ומעלה
- Xcode 15.0 ומעלה

**בנייה והתקנה (מומלץ):**

```bash
cd LangConvertMac
open LangConvert.xcodeproj
```

ב-Xcode:
1. בחר את ה-target "LangConvert"
2. בחר "My Mac" כמכשיר היעד
3. לחץ על **Product → Archive** (⌘⇧B) - לבנייה Release
4. ב-Organizer: **Distribute App → Copy App**
5. העתק `LangConvert.app` ל-`/Applications/`

**⚠️ חשוב:** הרץ את האפליקציה **מ-/Applications** ולא מ-DerivedData או Debug build:
```bash
# העתקה ל-Applications
cp -R ~/Library/Developer/Xcode/DerivedData/LangConvert-*/Build/Products/Release/LangConvert.app /Applications/

# או ידנית מ-Finder אחרי Archive
```

**לפיתוח מקומי בלבד:**
```bash
# Debug build (לא מומלץ לשימוש יומי)
# ב-Xcode: Product → Run (⌘R)
```

**הרצת טסטים:**
```bash
# ב-Xcode: Product → Test (⌘U)
```

### 📁 מבנה הפרויקט

```
LangConvertMac/
├── LangConvert.xcodeproj     # Xcode project
├── LangConvert/
│   ├── App/                  # Main app entry point
│   ├── Views/                # SwiftUI views
│   ├── Services/             # Core services
│   │   ├── ConversionService.swift   # Character mapping & conversion
│   │   ├── ClipboardManager.swift    # Clipboard operations
│   │   └── HotkeyManager.swift       # Global hotkey handling
│   ├── Models/               # Data models & settings
│   └── Resources/            # Assets & resources
└── LangConvertTests/         # Unit tests
```

---

## 🖥️ Windows Edition (גרסת Windows)

גרסה: 1.16 (ינואר 2026)

## ✨ פיצ'רים חדשים (New Features)
*   **תיקון Caps Lock חכם:** המרת אותיות רישיות (Uppercase) לעברית בלחיצת כפתור (`Convert Uppercase`).
*   **תיקון תחיליות (Smart Prefix):** זיהוי ותיקון אוטומטי של תחיליות אנגלית במילים עבריות (כמו `Hשלום` -> `ישלום`), תוך שמירה על ראשי תיבות באנגלית (כמו `NATO`).
*   **שמירה על הלוח (Clipboard Safety):** פעולת ההמרה לא דורסת את מה שהעתקת קודם לכן (Ctrl+C). הטקסט המקורי בלוח נשמר.

## ✨ פיצ'רים בסיסיים
*   **תיקון מהיר:** המרת טקסט מעברית לאנגלית ולהפך בלחיצת כפתור (`Ctrl` + `=`).
*   **עיצוב מותאם:** תמיכה מלאה ב-Dark Mode / Light Mode עם לוגו הבנק.
*   **אוטומציה:** אפשרות להפעלה אוטומטית עם עליית המחשב.
*   **אינדיקציה:** אייקון חכם במגש המערכת (ירוק = פעיל, אדום = מושבת).

## 🚀 הורדה (Download)
[לחץ כאן להורדת הגרסה האחרונה](https://github.com/ronnieba/LangConvert-Discount/releases/latest)

## 📦 הוראות התקנה והפצה
הפרויקט כולל כעת קובץ התקנה אוטומטי (`Setup.ahk`) שנועד להקל על הפצת הכלי למשתמשים.

### למשתמש קצה (התקנה פשוטה)
1.  הורד את קובץ ההתקנה (`Setup.exe` או התיקייה כולה).
2.  הפעל את `Setup`.
3.  לחץ על "התקן כעת".
4.  התוכנה תותקן, תיצור קיצורי דרך בשולחן העבודה, ותוגדר לפעול אוטומטית עם המחשב.

### למפתח (יצירת קובץ התקנה EXE)
כדי ליצור קובץ התקנה יחיד ונוח:
1.  וודא ש-AutoHotkey מותקן אצלך.
2.  קמפל את `langover.ahk` ל-`langover.exe` (קליק ימני -> Compile).
3.  קמפל את `Setup.ahk` ל-`Setup.exe`.
4.  הפץ את **כל** הקבצים בתיקייה אחת (כולל `langover.exe`, `DiscountLogo.png`, `Setup.exe`).

---

## 🔄 השוואה בין הגרסאות

| תכונה | Windows | macOS |
|--------|---------|-------|
| קיצור ברירת מחדל | `Ctrl+Alt+1` | `⌃⌥1` (Control+Option+1) |
| שפת פיתוח | AutoHotkey v2 | Swift / SwiftUI |
| תמיכה ב-Dark Mode | ✅ | ✅ |
| ממשק בעברית | ✅ | ✅ |
| הפעלה אוטומטית | ✅ | ✅ |
| שמירת לוח | ✅ | ✅ |
| מצב Caps Lock | ✅ | ✅ |
| מצב תחיליות חכם | ✅ | ✅ |
| אייקון מגש | ✅ (ירוק/אדום) | ✅ (SF Symbol) |
| גרסת מינימום | Windows 10+ | macOS 13+ |

---

## 👨‍💻 פיתוח
פותח על ידי: רוני בן-אבי

**טכנולוגיות:**
- Windows: AutoHotkey v2
- macOS: Swift 5 / SwiftUI / AppKit
