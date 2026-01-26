#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; LangConvert - Professional Installer
; ==============================================================================

appName := "LangConvert - Discount Bank Edition"
appDirName := "LangConvert"
mainExe := "langover.exe"

; ==============================================================================
; GUI Setup
; ==============================================================================
MyGui := Gui(, "Setup - " appName)
MyGui.BackColor := "FFFFFF"
MyGui.SetFont("s10", "Segoe UI")

; Header Image (Logo) - extracting temporarly for the setup display
logoTemp := A_Temp "\DiscountLogo_Setup.png"
greenIconTemp := A_Temp "\FinalGreen_Setup.ico"

; Attempt to extract assets for the installer UI itself
try {
    FileInstall "DiscountLogo.png", logoTemp, 1
    FileInstall "FinalGreen.ico", greenIconTemp, 1
    if FileExist(greenIconTemp)
        TraySetIcon(greenIconTemp)
}

if FileExist(logoTemp) {
    try {
        MyGui.Add("Picture", "w300 h-1 Center", logoTemp)
    }
}

MyGui.SetFont("s12 bold c005643") ; Discount Green-ish color
MyGui.Add("Text", "w300 Center vTitleText", "ברוכים הבאים להתקנה")
MyGui.SetFont("s10 norm cBlack")
MyGui.Add("Text", "w300 Center", "התוכנה תותקן במחשבך ותופעל אוטומטית.")

; Install Button
btnInstall := MyGui.Add("Button", "w200 h40 x50 y+20 Default", "התקן כעת")
btnInstall.OnEvent("Click", RunInstall)

; Progress Bar (Hidden initially)
MyGui.Add("Progress", "w280 x10 y+20 h20 Hidden vInstallProgress c005643")

; Status Text
MyGui.Add("Text", "w300 Center vStatusText Hidden", "")

MyGui.Show()

; ==============================================================================
; Installation Logic
; ==============================================================================
RunInstall(*) {
    btnInstall.Enabled := false
    MyGui["TitleText"].Text := "מתקין את המערכת..."
    MyGui["InstallProgress"].Visible := true
    MyGui["StatusText"].Visible := true
    MyGui["InstallProgress"].Value := 10
    
    ; 1. Create Destination Directory in AppData
    destDir := A_AppData "\" appDirName
    MyGui["StatusText"].Text := "יוצר תיקיות..."
    
    if !DirExist(destDir)
        DirCreate(destDir)
    
    MyGui["InstallProgress"].Value := 30
    
    ; 2. Install Files
    ; IMPORTANT: This script uses FileInstall to embed the executable.
    ; Ideally, 'langover.exe' should exist in the source folder before compiling this Setup script.
    
    MyGui["StatusText"].Text := "מעתיק קבצים..."
    try {
        ; Main Executable
        ; Note: If running this script uncompiled, it will look for 'langover.exe' in the script directory.
        ; If it doesn't exist, FileInstall in interpreted mode acts like FileCopy and might fail if missing.
        if (A_IsCompiled || FileExist("langover.exe")) {
             FileInstall "langover.exe", destDir "\langover.exe", 1
        } else {
             ; Fallback for development/testing if exe missing: try copying script
             if FileExist("langover.ahk")
                 FileCopy "langover.ahk", destDir "\langover.ahk", 1
        }
        
        ; Assets
        FileInstall "DiscountLogo.png", destDir "\DiscountLogo.png", 1
        FileInstall "DiscountLogo_Dark.png", destDir "\DiscountLogo_Dark.png", 1
        FileInstall "FinalGreen.ico", destDir "\FinalGreen.ico", 1
        FileInstall "FinalRed.ico", destDir "\FinalRed.ico", 1
        
        ; Settings (Create default if not exists)
        if !FileExist(destDir "\settings.ini") {
             FileAppend "[Settings]`nTheme=Light`nLanguage=English`nHotkey=^!1`n", destDir "\settings.ini"
        }
    } catch as err {
        MsgBox("שגיאה בהעתקת הקבצים: " err.Message, "Error", "Iconx")
        btnInstall.Enabled := true
        return
    }
    
    MyGui["InstallProgress"].Value := 70
    
    ; 3. Create Shortcuts
    MyGui["StatusText"].Text := "יוצר קיצורי דרך..."
    
    ; Determine what we installed (Exe or Ahk)
    installedApp := FileExist(destDir "\langover.exe") ? "langover.exe" : "langover.ahk"
    destPath := destDir "\" installedApp
    iconPath := destDir "\FinalGreen.ico"
    
    ; Desktop Shortcut
    try {
        FileCreateShortcut(destPath, A_Desktop "\" appName ".lnk", destDir, , "תיקון ג'יבריש אוטומטי", iconPath)
    }
    
    ; Startup Shortcut
    try {
        FileCreateShortcut(destPath, A_Startup "\" appName ".lnk", destDir, , "תיקון ג'יבריש אוטומטי", iconPath)
    }
    
    MyGui["InstallProgress"].Value := 100
    Sleep(500)
    
    Result := MsgBox("ההתקנה הסתיימה בהצלחה!`n`nהאם ברצונך להפעיל את התוכנה כעת?", "הצלחה", "YesNo Iconi")
    
    if (Result == "Yes") {
        try {
            Run destPath, destDir
        } catch as err {
            MsgBox("לא ניתן להפעיל את התוכנה אוטומטית: " err.Message)
        }
    }
    
    ExitApp
}
