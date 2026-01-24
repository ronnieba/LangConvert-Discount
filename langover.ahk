#Requires AutoHotkey v2.0+

; --- PREPARE ASSETS ---
LogoLight := A_Temp . "\DiscountLogo.png"
LogoDark  := A_Temp . "\DiscountLogo_Dark.png"
IconGreen := A_Temp . "\FinalGreen.ico"
IconRed   := A_Temp . "\FinalRed.ico"

; Pack assets
FileInstall "DiscountLogo.png", LogoLight, 1
FileInstall "DiscountLogo_Dark.png", LogoDark, 1
FileInstall "FinalGreen.ico", IconGreen, 1
FileInstall "FinalRed.ico", IconRed, 1

; --- SETTINGS ---
IniFile := "settings.ini"
CurrentTheme := IniRead(IniFile, "Settings", "Theme", "Light") 

; Apply Menu Theme Immediately
if (CurrentTheme == "Dark") {
    try {
        DllCall("uxtheme\SetPreferredAppMode", "Int", 2) 
        DllCall("uxtheme\FlushMenuThemes")
    }
} else {
    try {
        DllCall("uxtheme\SetPreferredAppMode", "Int", 0) 
        DllCall("uxtheme\FlushMenuThemes")
    }
}

; --- MAPPINGS ---
englishToHebrew := Map("q", "/", "w", "'", "e", "ק", "r", "ר", "t", "א", "y", "ט", "u", "ו", "i", "ן", "o", "ם", "p", "פ", "a", "ש", "s", "ד", "d", "ג", "f", "כ", "g", "ע", "h", "י", "j", "ח", "k", "ל", "l", "ך", "z", "ז", "x", "ס", "c", "ב", "v", "ה", "b", "נ", "n", "מ", "m", "צ", ",", "ת", ".", "ץ", "/", ".", ";", "ף", "'", ",")
hebrewToEnglish := Map("/", "q", "'", "w", "ק", "e", "ר", "r", "א", "t", "ט", "y", "ו", "u", "ן", "i", "ם", "o", "פ", "p", "ש", "a", "ד", "s", "ג", "d", "כ", "f", "ע", "g", "י", "h", "ח", "j", "ל", "k", "ך", "l", "ז", "z", "ס", "x", "ב", "c", "ה", "v", "נ", "b", "מ", "n", "צ", "m", "ת", ",", "ץ", ".", ".", "/", "ף", ";", ",", "'")

; --- VARS ---
CurrentHotkey := IniRead(IniFile, "Settings", "Hotkey", "^!1")
CurrentLang := IniRead(IniFile, "Settings", "Language", "English")
ModeUpper := IniRead(IniFile, "Settings", "ModeUpper", "0")
IsActive := true 
StartupShortcut := A_Startup . "\LangConvert.lnk"
StartWithWindows := FileExist(StartupShortcut) ? 1 : 0

; --- GUI SETUP ---
MyGui := Gui()
MyGui.Title := "LangConvert"
MyGui.OnEvent("Close", HideWindow)

; --- LAYOUT ---
InitialLogo := (CurrentTheme == "Dark") ? LogoDark : LogoLight
MyPic := MyGui.Add("Picture", "x50 w200 h-1", InitialLogo)

lblHeader := MyGui.Add("Text", "x0 w300 Center BackgroundTrans", "Developed for Discount Bank")
lblVersion := MyGui.Add("Text", "x0 w300 Center BackgroundTrans", "Version 1.17 - Jan 2026")
lblCredit := MyGui.Add("Text", "x0 w300 Center BackgroundTrans", "Ben-Avi Ronnie")
MyGui.Add("Text", "x10 w280 h2 0x10") 
lblStatus := MyGui.Add("Text", "x0 w300 Center BackgroundTrans", "")
lblHint := MyGui.Add("Text", "x0 w300 Center cGray BackgroundTrans", "Tip: Select text to convert only selection")
lblHotkey := MyGui.Add("Text", "x0 w300 Center BackgroundTrans", "")
hkControl := MyGui.Add("Hotkey", "vChosenHotkey w150 x75 Center", CurrentHotkey)

; BUTTONS
btnUpdate := CreateCustomButton("Update Hotkey", UpdateHotkey)
btnLang   := CreateCustomButton("עברית / English", ToggleLanguage)
btnTheme  := CreateCustomButton("Dark / Light", ToggleTheme)
btnToggle := CreateCustomButton("Enable/Disable", ToggleActiveState)
btnHide   := CreateCustomButton("Hide Window", HideWindow)

; --- CHECKBOXES (MODE SELECTORS) ---
; 1. CONVERT UPPERCASE (CAPS LOCK FIX)
chkUpper := MyGui.Add("Checkbox", "x45 w20 h25 vModeUpper") 
chkUpper.Value := ModeUpper
chkUpper.OnEvent("Click", ClickLabelUpper)
lblUpper := MyGui.Add("Text", "x65 yp h25 0x200 BackgroundTrans w220", "Convert Uppercase (Caps Lock)") 
lblUpper.OnEvent("Click", ClickLabelUpper)

; 2. TITLE CASE MODE
chkTitle := MyGui.Add("Checkbox", "x45 w20 h25 vModeTitle") 
chkTitle.OnEvent("Click", ClickLabelTitle)
lblTitle := MyGui.Add("Text", "x65 yp h25 0x200 BackgroundTrans w220", "Turn to Title Case") 
lblTitle.OnEvent("Click", ClickLabelTitle)

; 3. START WITH WINDOWS
chkStartup := MyGui.Add("Checkbox", "x45 w20 h25 vStartWithWin") 
chkStartup.Value := StartWithWindows
chkStartup.OnEvent("Click", ToggleStartup)
lblStartup := MyGui.Add("Text", "x65 yp h25 0x200 BackgroundTrans w220", "Start with Windows") 
lblStartup.OnEvent("Click", ClickLabelStartup)

CreateCustomButton(text, callback) {
    ctl := MyGui.Add("Text", "w150 x75 h25 Border 0x201 BackgroundTrans", text)
    ctl.OnEvent("Click", callback)
    return ctl
}

; --- INITIAL TRAY ---
A_IconTip := "LangConvert"
try TraySetIcon(IconGreen)

UpdateUI()
MyGui.Show("w300")

try {
    Hotkey(CurrentHotkey, ConvertSelection)
} catch {
    MsgBox("Error registering initial hotkey: " . CurrentHotkey)
}

; --- FUNCTIONS ---

ClickLabelUpper(GuiCtrl, *) {
    ; If triggered by Label click, toggle checkbox. 
    ; If triggered by Checkbox click, value is already toggled.
    if (GuiCtrl.Type == "Text")
        chkUpper.Value := !chkUpper.Value
    
    global ModeUpper := chkUpper.Value
    IniWrite(ModeUpper, IniFile, "Settings", "ModeUpper")
}

ClickLabelTitle(GuiCtrl, *) {
    if (GuiCtrl.Type == "Text")
        chkTitle.Value := !chkTitle.Value
}

ClickLabelStartup(*) {
    chkStartup.Value := !chkStartup.Value
    ToggleStartup()
}

UpdateHotkey(*) {
    NewHotkey := hkControl.Value
    if (NewHotkey == "") 
        return
    try {
        if (CurrentHotkey != "")
            Hotkey(CurrentHotkey, "Off")
        Hotkey(NewHotkey, ConvertSelection)
        global CurrentHotkey := NewHotkey
        IniWrite(CurrentHotkey, IniFile, "Settings", "Hotkey")
        MsgBox(CurrentLang == "English" ? "Hotkey updated!" : "הקיצור עודכן!")
    } catch as err {
        MsgBox("Error: " . err.Message)
    }
}

ToggleLanguage(*) {
    global CurrentLang := (CurrentLang == "English") ? "Hebrew" : "English"
    IniWrite(CurrentLang, IniFile, "Settings", "Language")
    UpdateUI()
}

ToggleActiveState(*) {
    global IsActive := !IsActive
    UpdateUI()
}

ToggleTheme(*) {
    NewTheme := (CurrentTheme == "Light") ? "Dark" : "Light"
    IniWrite(NewTheme, IniFile, "Settings", "Theme")
    Reload()
}

ToggleStartup(*) {
    ShortcutPath := A_Startup . "\LangConvert.lnk"
    if (chkStartup.Value == 1) {
        try FileCreateShortcut(A_ScriptFullPath, ShortcutPath, A_ScriptDir)
    } else {
        try FileDelete(ShortcutPath)
    }
}



; --- TRANSFORMATION LOGIC ---
RunTransformation(Mode) {
    SavedClip := ClipboardAll()
    A_Clipboard := "" 
    Send("^c")        
    if !ClipWait(0.3) { 
        Send("^a")
        Sleep(150)
        Send("^c")
        if !ClipWait(0.5) {
            return 
        }
    }
    originalText := A_Clipboard
    if (originalText == "") 
        return
        
    if (Mode == "Upper")
        convertedText := StrUpper(originalText)
    else if (Mode == "Title")
        convertedText := StrTitle(originalText)
    
    A_Clipboard := convertedText
    Sleep(100)
    Send("^v")
    Sleep(250)
    A_Clipboard := SavedClip
    SavedClip := ""
}

UpdateUI() {
    if (CurrentLang == "English") {
        lblHeader.Text := "Developed for Discount Bank"
        lblVersion.Text := "Version 1.06 - Dec 2025"
        lblCredit.Text := "Ben-Avi Ronnie"
        lblStatus.Text := "Status: Running"
        lblHint.Text := "Tip: Select text to convert only selection"
        lblHotkey.Text := "Select Hotkey:"
        btnUpdate.Text := "Update Hotkey"
        btnHide.Text := "Hide Window"
        btnToggle.Text := IsActive ? "Disable" : "Enable"
        btnTheme.Text := (CurrentTheme == "Light") ? "Dark Mode" : "Light Mode"
        
        lblUpper.Text := "Convert Uppercase (Caps Lock)"
        lblTitle.Text := "Turn to Title Case"
        lblStartup.Text := "Start with Windows"
        
        A_IconTip := "LangConvert - Press " . CurrentHotkey . " to convert"
    } else {
        lblHeader.Text := "פותח עבור בנק דיסקונט"
        lblVersion.Text := "גרסה 1.17 - ינואר 2026"
        lblCredit.Text := "בן-אבי רוני"
        lblStatus.Text := IsActive ? "סטטוס: פעיל" : "סטטוס: לא פעיל"
        lblHint.Text := "טיפ: סמן טקסט כדי להמיר רק אותו"
        lblHotkey.Text := "בחר קיצור מקשים:"
        btnUpdate.Text := "עדכן קיצור"
        btnHide.Text := "הסתר חלון"
        btnToggle.Text := IsActive ? "השבת" : "הפעל"
        btnTheme.Text := (CurrentTheme == "Light") ? "ערכה כהה" : "ערכה בהירה"
        
        ; Corrected Hebrew Text with "Hafoc"
        lblUpper.Text := "המר אותיות רישיות (Caps Lock)"
        lblTitle.Text := "הפוך אות גדולה בתחילת מילה"
        lblStartup.Text := "הפעל עם המחשב"
        
        A_IconTip := "LangConvert - לחץ " . CurrentHotkey . " להמרה"
    }

    ApplyThemeColors()

    if (IsActive) {
        lblStatus.SetFont("cGreen")
        try TraySetIcon(IconGreen)
    } else {
        lblStatus.SetFont("cRed")
        try TraySetIcon(IconRed)
    }
    
    UpdateTrayMenu(CurrentLang)
}

ApplyThemeColors() {
    if (CurrentTheme == "Dark") {
        BgColor := "1F1F1F"
        TxtColor := "cWhite"
        BtnBg := "Background333333" 
        BtnTxt := "cWhite"
        
        MyGui.BackColor := BgColor
        try MyPic.Value := LogoDark 

        lblHeader.SetFont(TxtColor)
        lblVersion.SetFont(TxtColor)
        lblCredit.SetFont(TxtColor)
        lblHotkey.SetFont(TxtColor)
        lblHint.SetFont("cSilver")
        
        ; Apply color to ALL checkboxes labels
        lblUpper.SetFont(TxtColor)
        lblTitle.SetFont(TxtColor)
        lblStartup.SetFont(TxtColor)

        
        SetButtonStyle(btnUpdate, BtnBg, BtnTxt)
        SetButtonStyle(btnLang,   BtnBg, BtnTxt)
        SetButtonStyle(btnTheme,  BtnBg, BtnTxt)
        SetButtonStyle(btnToggle, BtnBg, BtnTxt)
        SetButtonStyle(btnHide,   BtnBg, BtnTxt)

        try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "Int", 20, "Int*", 1, "Int", 4)
    } else {
        BgColor := "Default"
        TxtColor := "cBlack"
        BtnBg := "BackgroundDefault" 
        BtnTxt := "cBlack"
        
        MyGui.BackColor := BgColor
        try MyPic.Value := LogoLight 

        lblHeader.SetFont(TxtColor)
        lblVersion.SetFont(TxtColor)
        lblCredit.SetFont(TxtColor)
        lblHotkey.SetFont(TxtColor)
        lblHint.SetFont("cGray")
        
        ; Apply color to ALL checkboxes labels
        lblUpper.SetFont(TxtColor)
        lblTitle.SetFont(TxtColor)
        lblStartup.SetFont(TxtColor)

        
        SetButtonStyle(btnUpdate, BtnBg, BtnTxt)
        SetButtonStyle(btnLang,   BtnBg, BtnTxt)
        SetButtonStyle(btnTheme,  BtnBg, BtnTxt)
        SetButtonStyle(btnToggle, BtnBg, BtnTxt)
        SetButtonStyle(btnHide,   BtnBg, BtnTxt)

        try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "Int", 20, "Int*", 0, "Int", 4)
    }
    
    lblUpper.Redraw()
    lblTitle.Redraw()
    lblStartup.Redraw()
}

SetButtonStyle(ctl, bgOption, txtOption) {
    ctl.Opt(bgOption)
    ctl.SetFont(txtOption)
    ctl.Redraw()
}

; Tray Menu Handlers (Now just set the Checkbox mode)
MenuSetUpper(*) {
    chkUpper.Value := 1
    chkTitle.Value := 0
    MsgBox("Mode set to: UPPERCASE")
}
MenuSetTitle(*) {
    chkUpper.Value := 0
    chkTitle.Value := 1
    MsgBox("Mode set to: Title Case")
}

UpdateTrayMenu(lang) {
    A_TrayMenu.Delete()
    if (lang == "English") {
        ; These now just activate the mode for the hotkey
        A_TrayMenu.Add("Set Mode: UPPERCASE", MenuSetUpper) 
        A_TrayMenu.Add("Set Mode: Title Case", MenuSetTitle) 
        A_TrayMenu.Add() 
        A_TrayMenu.Add(IsActive ? "Disable" : "Enable", ToggleActiveState)
        A_TrayMenu.Add((CurrentTheme == "Light") ? "Dark Mode" : "Light Mode", ToggleTheme)
        A_TrayMenu.Add()
        A_TrayMenu.Add("Help", ShowHelp)
        A_TrayMenu.Add("Show", ShowWindow)
        A_TrayMenu.Add("Hide", HideWindow)
        A_TrayMenu.Add("Exit", ExitAppHandler)
    } else {
        A_TrayMenu.Add("מצב: הפוך לאותיות גדולות", MenuSetUpper) 
        A_TrayMenu.Add("מצב: הפוך אות גדולה בתחילת מילה", MenuSetTitle) 
        A_TrayMenu.Add() 
        A_TrayMenu.Add(IsActive ? "השבת" : "הפעל", ToggleActiveState)
        A_TrayMenu.Add((CurrentTheme == "Light") ? "ערכה כהה" : "ערכה בהירה", ToggleTheme)
        A_TrayMenu.Add()
        A_TrayMenu.Add("עזרה", ShowHelp)
        A_TrayMenu.Add("הצג", ShowWindow)
        A_TrayMenu.Add("הסתר", HideWindow)
        A_TrayMenu.Add("יציאה", ExitAppHandler)
    }
}

ShowWindow(ItemName, ItemPos, MyMenu) { 
    MyGui.Show() 
}
HideWindow(*) { 
    MyGui.Hide() 
}
ExitAppHandler(ItemName, ItemPos, MyMenu) { 
    ExitApp 
}
ContainsHebrew(str) {
    Loop Parse str {
        if (Ord(A_LoopField) >= 0x0590 && Ord(A_LoopField) <= 0x05FF) {
            return true
        }
    }
    return false
}
ShowHelp(ItemName, ItemPos, MyMenu) {
    MsgBox(CurrentLang == "English" ? "Select text -> convert." : "סמן טקסט -> המר.")
}

; MAIN HOTKEY LOGIC
ConvertSelection(ThisHotkey) {
    if (!IsActive) {
        return 
    }
    
    ; 2. Standard Logic with Smart Features
    SavedClip := ClipboardAll()
    A_Clipboard := "" 
    Send("^c")        
    if !ClipWait(0.3) { 
        Send("^a")
        Sleep(150)
        Send("^c")
        if !ClipWait(0.5) {
            return 
        }
    }
    originalText := A_Clipboard
    if (originalText == "") {
        return
    }
    
    ; Tokenize and Process
    convertedText := ""
    currentWord := ""
    
    Loop Parse originalText {
        char := A_LoopField
        isWordChar := IsWordCharacter(char)
        
        if (isWordChar) {
            currentWord .= char
        } else {
            if (currentWord != "") {
                convertedText .= ProcessWord(currentWord)
                currentWord := ""
            }
            convertedText .= char ; Separator
        }
    }
    ; Last word
    if (currentWord != "") {
        convertedText .= ProcessWord(currentWord)
    }

    ; Post-Process: REMOVED chkUpper logic (it is now input logic)

    A_Clipboard := convertedText
    Sleep(100)
    Send("^v")
    Sleep(250)
    A_Clipboard := SavedClip
    SavedClip := ""
}

IsWordCharacter(char) {
    code := Ord(char)
    ; A-Z (65-90), a-z (97-122), Hebrew (1488-1514 / 0x05D0-0x05EA approx)
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || (code >= 0x0590 && code <= 0x05FF)
}

ProcessWord(word) {
    ; Analyze Word
    hasHebrew := ContainsHebrew(word)
    hasEnglish := RegExMatch(word, "[A-Za-z]")
    
    ; Settings
    forceUncaps := chkUpper.Value            ; "Convert Uppercase" (Caps Lock Fix)
    smartCaps   := chkTitle.Value            ; "Turn to Title Case" (Smart Prefix)
    
    ; Case 1: Pure Hebrew -> Convert to English
    if (hasHebrew && !hasEnglish) {
        return TransformString(word, hebrewToEnglish)
    }
    
    ; Case 2: Pure English
    if (!hasHebrew && hasEnglish) {
        isAllCaps := (StrUpper(word) == word) && RegExMatch(word, "[A-Z]")
        
        ; Should we convert Uppercase letters to Hebrew?
        ; Default: NO (Preserve Upper).
        ; If Force (chkConvertCaps): YES (Convert All).
        ; If Smart (chkTitle): 
        ;    If AllCaps (NATO) -> NO.
        ;    If Not AllCaps -> YES (Convert prefixes).
        
        convertUpperToHebrew := false
        if (forceUncaps) {
            convertUpperToHebrew := true
        } else if (smartCaps) {
            if (!isAllCaps)
                convertUpperToHebrew := true
        }
        
        return TransformToHebrew(word, convertUpperToHebrew)
    }
    
    ; Case 3: Mixed (e.g. Hשלום)
    if (hasHebrew && hasEnglish) {
        ; If Smart Caps is ON, assume user wants to fix the English prefix to Hebrew
        if (smartCaps || forceUncaps) {
            ; Convert English to Hebrew, Keep Hebrew
            return TransformToHebrew(word, true) ; Always convert Upper in mixed if smart/force is on
        }
        ; Otherwise... Ambiguous.
        ; Existing behavior (based on ContainsHebrew logic in older version) 
        ; would treat it as Hebrew->English.
        ; But H (English) is not in Heb map -> Stays H.
        ; שלום -> akuo.
        ; Result Hakuo.
        ; Let's preserve this default unless user enabled Smart Settings.
        return TransformString(word, hebrewToEnglish)
    }
    
    return word ; Fallback (Numbers etc)
}

TransformString(str, mapObj) {
    res := ""
    Loop Parse str {
        char := A_LoopField
        lower := Format("{:L}", char)
        res .= mapObj.Has(lower) ? mapObj[lower] : char
    }
    return res
}

TransformToHebrew(str, convertUpper) {
    global englishToHebrew
    res := ""
    Loop Parse str {
        char := A_LoopField
        charCode := Ord(char)
        isUpper := (charCode >= 65 && charCode <= 90)
        
        if (isUpper && !convertUpper) {
             res .= char ; Keep Upper
        } else {
             lower := Format("{:L}", char)
             res .= englishToHebrew.Has(lower) ? englishToHebrew[lower] : char 
        }
    }
    return res
}