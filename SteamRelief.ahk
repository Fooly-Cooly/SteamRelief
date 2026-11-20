;@Ahk2Exe-SetName SteamRelief
;@Ahk2Exe-SetDescription Steam WebHelper background working set monitor
;@Ahk2Exe-SetVersion 2026.11.19.0
#Requires AutoHotkey v1.1.33+
#NoEnv
#NoTrayIcon
#Persistent
#SingleInstance Ignore
SetBatchLines, -1
SetWorkingDir %A_ScriptDir%
SplitPath, A_ScriptName, , , , ScriptBase
IniFile := A_ScriptDir "\" ScriptBase ".ini"
IniRead, NoTray, %IniFile%, Settings, NoTray, 0
IniRead, StartSteam, %IniFile%, Settings, StartSteam, 1
IniRead, LaunchParams, %IniFile%, Settings, LaunchParams, open/minigameslist
IdleMs := 1000 * ReadPositiveSetting("IdleSeconds", 60)
CooldownMs := 1000 * ReadPositiveSetting("CooldownSeconds", 300)
MinWebHelperMiB := ReadPositiveSetting("MinWebHelperMiB", 256)

RegRead, SteamPath, HKCU\Software\Valve\Steam, SteamExe
if (!SteamPath) {
    RegRead, SteamDir, HKLM\SOFTWARE\WOW6432Node\Valve\Steam, InstallPath
    SteamPath := SteamDir "\steam.exe"
}
GroupAdd, SteamUI, ahk_exe steam.exe
GroupAdd, SteamUI, ahk_exe steamwebhelper.exe
GroupAdd, SteamUI, ahk_exe GameOverlayUI.exe

if (!NoTray) {
    if (!A_IsCompiled && FileExist(A_ScriptDir "\icon.ico"))
        Menu, Tray, Icon, %A_ScriptDir%\icon.ico
    Menu, Tray, Icon
    Menu, Tray, NoStandard
    Menu, Tray, Add, Open Steam, Tray_OpenSteam
    Menu, Tray, Default, Open Steam
    Menu, Tray, Add, Autostart, Tray_AutoStart
    Menu, Tray, Add, Config, Tray_Config
    Menu, Tray, Add
    Menu, Tray, Add, Exit, Tray_Exit
    Menu, Tray, Click, 1
    ; Keep an existing all-users install manageable from the tray.
    CommonLink := A_StartupCommon "\" ScriptBase ".lnk"
    UserLink := A_Startup "\" ScriptBase ".lnk"
    if (FileExist(CommonLink) || FileExist(UserLink))
        Menu, Tray, Check, Autostart
}

Process, Exist, steam.exe
if (StartSteam && !ErrorLevel)
    Run, "%SteamPath%" "steam://%LaunchParams%",, UseErrorLevel

SetTimer, Steam_Tick, 10000
Steam_Tick()
return

ReadPositiveSetting(key, fallback) {
    global IniFile
    IniRead, value, %IniFile%, Settings, %key%, %fallback%
    if value is not integer
        return fallback
    return value >= 1 && value <= 2147483 ? value : fallback
}

Steam_Tick() {
    global IdleMs, CooldownMs, MinWebHelperMiB, NoTray
    static backgroundSince := 0, lastAttempt := -1, lastPass := ""
    now := DllCall("GetTickCount64", "Int64")
    foreground := WinActive("ahk_group SteamUI")
    sample := Steam_Sample()
    count := sample.helpers.Length()
    if (!sample.ok || !count || foreground)
        backgroundSince := 0
    else if (!backgroundSince)
        backgroundSince := now

    if (!sample.ok)
        state := "Process list unavailable"
    else if (!count && !sample.missed) {
        state := "Waiting for Steam WebHelper"
        lastAttempt := -1
        lastPass := ""
    } else if (foreground)
        state := "Paused: Steam in foreground"
    else if (!count)
        state := "No readable WebHelpers"
    else if (now - backgroundSince < IdleMs)
        state := "Waiting for background delay"
    else if (sample.helperMiB >= MinWebHelperMiB
          && (lastAttempt < 0 || now - lastAttempt >= CooldownMs)) {
        trimmed := 0
        attempted := 0
        for _, pid in sample.helpers {
            if (WinActive("ahk_group SteamUI")) {
                backgroundSince := 0
                break
            }
            attempted++
            trimmed += Steam_Trim(pid)
        }
        if (attempted) {
            lastAttempt := now
            lastPass := "Last trim: " trimmed "/" attempted
            ; Display the new footprint right after a pass.
            sample := Steam_Sample()
            count := sample.helpers.Length()
        }
        state := attempted ? lastPass : "Paused: Steam in foreground"
    } else
        state := lastPass ? lastPass : "Below threshold"

    if (!NoTray) {
        tip := "Steam: " Round(sample.steamMiB) " MiB " sample.metric
            . "`nWebHelper: " Round(sample.helperMiB) " MiB (" count ")"
            . "`n" state
        if (sample.missed)
            tip .= "`nUnreadable: " sample.missed
        if (!sample.ok)
            tip := "SteamRelief: process list unavailable"
        Menu, Tray, Tip, %tip%
    }
}

Tray_OpenSteam() {
    global SteamPath
    Run, "%SteamPath%",, UseErrorLevel
}

Tray_AutoStart() {
    global CommonLink, UserLink
    existing := FileExist(CommonLink) ? CommonLink : UserLink
    if (FileExist(existing))
        FileDelete, %existing%
    else
        FileCreateShortcut, %A_ScriptFullPath%, %UserLink%, %A_ScriptDir%
    if (ErrorLevel) {
        MsgBox, 48, SteamRelief, Could not change the startup shortcut.
        return
    }
    if (FileExist(CommonLink) || FileExist(UserLink))
        Menu, Tray, Check, Autostart
    else
        Menu, Tray, Uncheck, Autostart
}

Tray_Config() {
    global IniFile
    Run, notepad.exe "%IniFile%"
}

Tray_Exit() {
    ExitApp
}

#Include %A_ScriptDir%\SteamProcesses.ahk
