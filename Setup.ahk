#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; LangConvert - Professional Installer
; ==============================================================================

appName := "LangConvert - Discount Bank Edition"
appDirName := "LangConvert"
exeName := "langover.exe"
scriptName := "langover.ahk"
logoFile := "DiscountLogo.png"

; Determine source file (prefer EXE if available, otherwise script)
if FileExist(exeName) {
    sourceFile := exeName
    isCompiled := true
} else if FileExist(scriptName) {
    sourceFile := scriptName
    isCompiled := false
} else {
    MsgBox("Error: Could not find " exeName " or " scriptName " in the current directory.`nPlease ensure the installer is in the same folder as the application files.", "Error", "IconHb")
    ExitApp
}

; ==============================================================================
; GUI Setup
; ==============================================================================
MyGui := Gui(, "Setup - " appName)
MyGui.BackColor := "FFFFFF"
MyGui.SetFont("s10", "Segoe UI")

; Logo (if exists)
if FileExist(logoFile) {
    try {
        MyGui.Add("Picture", "w300 h-1 Center", logoFile)
    }
}

MyGui.SetFont("s12 bold c005643") ; Discount Green-ish color
MyGui.Add("Text", "w300 Center vTitleText", "ברוכים הבאים להתקנה")
MyGui.SetFont("s10 norm cBlack")
MyGui.Add("Text", "w300 Center", "התוכנה תותקן במחשבך ותופעל אוטומטית.")

; install Button
MyGui.Add("Button", "w200 h40 x50 y+20 Default", "התקן כעת").OnEvent("Click", RunInstall)

; Progress Bar (Hidden initially)
MyGui.Add("Progress", "w280 x10 y+20 h20 Hidden vInstallProgress c005643")

MyGui.Show()

; ==============================================================================
; Installation Logic
; ==============================================================================
RunInstall(*) {
    MyGui["TitleText"].Text := "מתקין..."
    MyGui["InstallProgress"].Visible := true
    MyGui["InstallProgress"].Value := 10
    
    ; 1. Create Destination Directory in AppData
    destDir := A_AppData "\" appDirName
    if !DirExist(destDir)
        DirCreate(destDir)
    
    MyGui["InstallProgress"].Value := 30
    
    ; 2. Copy Files
    try {
        FileCopy(sourceFile, destDir "\" sourceFile, 1) ; Overwrite
        if FileExist("settings.ini")
            FileCopy("settings.ini", destDir "\settings.ini", 1)
        if FileExist("DiscountLogo.png")
            FileCopy("DiscountLogo.png", destDir "\DiscountLogo.png", 1)
         if FileExist("FinalGreen.ico")
            FileCopy("FinalGreen.ico", destDir "\FinalGreen.ico", 1)
         if FileExist("FinalRed.ico")
             FileCopy("FinalRed.ico", destDir "\FinalRed.ico", 1)
    } catch as err {
        MsgBox("Failed to copy files: " err.Message, "Error", "IconHand")
        return
    }
    
    MyGui["InstallProgress"].Value := 60
    
    ; 3. Create Shortcuts
    destPath := destDir "\" sourceFile
    
    ; Desktop Shortcut
    try {
        FileCreateShortcut(destPath, A_Desktop "\" appName ".lnk", destDir, , "תיקון ג'יבריש אוטומטי", destDir "\FinalGreen.ico")
    }
    
    ; Startup Shortcut
    try {
        FileCreateShortcut(destPath, A_Startup "\" appName ".lnk", destDir, , "תיקון ג'יבריש אוטומטי", destDir "\FinalGreen.ico")
    }
    
    MyGui["InstallProgress"].Value := 100
    Sleep(500)
    
    MsgBox("ההתקנה הסתיימה בהצלחה!`n`nהתוכנה תעלה אוטומטית בפעם הבאה שתפעיל את המחשב.`nתוכל להפעיל אותה כעת דרך שולחן העבודה.", "הצלחה", "IconAsterisk")
    
    ; Optional: Launch immediately
    ; Run(destPath)
    
    ExitApp
}
