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
lblVersion := MyGui.Add("Text", "x0 w300 Center BackgroundTrans", "Version 1.06 - Dec 2025")
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
; 1. UPPERCASE MODE
chkUpper := MyGui.Add("Checkbox", "x45 w20 h25 vModeUpper") 
chkUpper.OnEvent("Click", ClickUpper)
lblUpper := MyGui.Add("Text", "x65 yp h25 0x200 BackgroundTrans w220", "Turn to UPPERCASE") 
lblUpper.OnEvent("Click", ClickLabelUpper)

; 2. TITLE CASE MODE
chkTitle := MyGui.Add("Checkbox", "x45 w20 h25 vModeTitle") 
chkTitle.OnEvent("Click", ClickTitle)
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

; Checkbox Logic (Radio Behavior: Picking one unchecks the other)
ClickLabelUpper(*) {
    chkUpper.Value := !chkUpper.Value
    ClickUpper()
}
ClickUpper(*) {
    if (chkUpper.Value)
        chkTitle.Value := 0 ; Uncheck Title if Upper is checked
}

ClickLabelTitle(*) {
    chkTitle.Value := !chkTitle.Value
    ClickTitle()
}
ClickTitle(*) {
    if (chkTitle.Value)
        chkUpper.Value := 0 ; Uncheck Upper if Title is checked
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
    A_Clipboard := "" 
    Send("^c")        
    if !ClipWait(0.3) { 
        return 
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
    Sleep(100)
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
        
        lblUpper.Text := "Turn to UPPERCASE"
        lblTitle.Text := "Turn to Title Case"
        lblStartup.Text := "Start with Windows"
        
        A_IconTip := "LangConvert - Press " . CurrentHotkey . " to convert"
    } else {
        lblHeader.Text := "פותח עבור בנק דיסקונט"
        lblVersion.Text := "גרסה 1.06 דצמבר 2025"
        lblCredit.Text := "בן-אבי רוני"
        lblStatus.Text := IsActive ? "סטטוס: פעיל" : "סטטוס: לא פעיל"
        lblHint.Text := "טיפ: סמן טקסט כדי להמיר רק אותו"
        lblHotkey.Text := "בחר קיצור מקשים:"
        btnUpdate.Text := "עדכן קיצור"
        btnHide.Text := "הסתר חלון"
        btnToggle.Text := IsActive ? "השבת" : "הפעל"
        btnTheme.Text := (CurrentTheme == "Light") ? "ערכה כהה" : "ערכה בהירה"
        
        ; Corrected Hebrew Text with "Hafoc"
        lblUpper.Text := "הפוך לאותיות גדולות (UPPER)"
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
    
    ; 1. Check if we are in a special mode
    if (chkUpper.Value) {
        RunTransformation("Upper")
        return
    }
    if (chkTitle.Value) {
        RunTransformation("Title")
        return
    }

    ; 2. Standard Logic (Heb/Eng)
    A_Clipboard := "" 
    Send("^c")        
    if !ClipWait(0.3) { 
        Send("^a")
        Sleep(50)
        Send("^c")
        if !ClipWait(0.5) {
            return 
        }
    }
    originalText := A_Clipboard
    if (originalText == "") {
        return
    }
    convertedText := ""
    isHebrew := ContainsHebrew(originalText)
    Loop Parse originalText {
        char := A_LoopField
        lower := Format("{:L}", char)
        if (isHebrew) {
            convertedText .= hebrewToEnglish.Has(lower) ? hebrewToEnglish[lower] : char 
        } else { 
            charCode := Ord(char)
            if (charCode >= 65 && charCode <= 90) {
                convertedText .= char 
            } else { 
                convertedText .= englishToHebrew.Has(lower) ? englishToHebrew[lower] : char 
            }
        }
    }
    A_Clipboard := convertedText
    Sleep(100)
    Send("^v")
    Sleep(100)
}