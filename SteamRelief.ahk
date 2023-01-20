#NoEnv
#NoTrayIcon
#Persistent
#SingleInstance
SendMode Input
SetWorkingDir %A_ScriptDir%
SplitPath, A_Scriptname, , , , A_ScriptNameNoExt
RegRead, SteamPath, HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam, InstallPath
SteamPath = %SteamPath%\steam.exe
IniFile=%A_ScriptNameNoExt%.ini
if FileExist( IniFile ) {
	IniRead, NoTray, %IniFile%, Settings, NoTray
	IniRead, StartSteam, %IniFile%, Settings, StartSteam
	IniRead, LaunchParams, %IniFile%, Settings, LaunchParams
} else {
	NoTray := 0
	StartSteam := 1
	LaunchParams := open/minigameslist
}

if ( !NoTray ) {

	Menu, Tray, Icon
	if ( !A_IsCompiled )
		Menu, Tray, Icon, icon.ico
	Menu, Tray, NoStandard
	Menu, Tray, Add, Autostart, Tray_AutoStart
	Menu, Tray, Add, Config, Tray_Config
	Menu, Tray, Add
	Menu, Tray, Add, Exit, Exit

	LinkFile=%A_StartupCommon%\%A_ScriptNameNoExt%.lnk
	if FileExist( LinkFile )
		Menu, Tray, Check, Autostart
}

Process, Exist, steam.exe
if ( StartSteam && !ErrorLevel ) {
	Run, "%SteamPath%" "steam://%LaunchParams%"
} else if ( !StartSteam && !ErrorLevel ) {

	MsgBox, 260,, Steam isn't running, Start Steam?
	IfMsgBox Yes
		Run, "%SteamPath%" "steam://%LaunchParams%"
	else
		ExitApp
}

VarSetCapacity(NoTray, 0)
VarSetCapacity(StartSteam, 0)

Process, Wait, steamwebhelper.exe, 45
if ( ErrorLevel )
	SetTimer, Steam_CleanMemory, 10000
return

Steam_CleanMemory() {

	A_ScriptPID := DllCall("GetCurrentProcessId")
	Process, Exist, steamwebhelper.exe
	if ( ErrorLevel ) {
		For process in ComObjGet( "winmgmts:" ).ExecQuery( "Select * from Win32_Process" )
			if	( process.name = "steamwebhelper.exe" || process.name = "steam.exe" || process.ProcessID = A_ScriptPID ) {

				I := DllCall( "OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", process.ProcessID )
				DllCall( "SetProcessWorkingSetSize", "UInt", I, "Int", -1, "Int", -1 )
				DllCall( "CloseHandle", "Int", I )
			}
	}
	else
		ExitApp
}

Tray_NotifyClick(P*) { ;  v0.41 by SKAN on D39E/D39N @ tiny.cc/notifytrayclick
	Static Msg, Fun:="Tray_NotifyClick", NM:=OnMessage(0x404,Func(Fun),-1),  Chk,T:=-250,Clk:=1
		If ( (NM := Format(Fun . "_{:03X}", Msg := P[2])) && P.Count()<4 )
			Return ( T := Max(-5000, 0-(P[1] ? Abs(P[1]) : 250)) )
		Critical
		If ( ( Msg<0x200 || Msg>0x209 ) || ( IsFunc(NM) || Islabel(NM) )=0 )
			Return
		Chk := (Fun . "_" . (Msg<=0x203 ? "203" : Msg<=0x206 ? "206" : Msg<=0x209 ? "209" : ""))
		SetTimer, %NM%,  %  (Msg==0x203        || Msg==0x206        || Msg==0x209)
			? (-1, Clk:=2) : ( Clk=2 ? ("Off", Clk:=1) : ( IsFunc(Chk) || IsLabel(Chk) ? T : -1) )
	Return True
}

Tray_NotifyClick_200() {

	Process, Exist, steamwebhelper.exe
	if ( ErrorLevel ) {
		For process in ComObjGet( "winmgmts:" ).ExecQuery( "Select * from Win32_PerfFormattedData_PerfProc_Process" )
			if InStr( process.name, "steam" )
				RAMUsage += process.WorkingSetPrivate
				
		WorkingSetPrivate := RAMUsage//1024//1024
		Menu, Tray, Tip , Steam RAM: %WorkingSetPrivate%MB
	}
}

Tray_NotifyClick_202() {

	global SteamPath
	Run, "%SteamPath%"
	WinWait, ahk_exe steam.exe,, 3
	if !ErrorLevel
		WinActivate, ahk_exe steam.exe
}

Tray_AutoStart() {

	global A_ScriptNameNoExt
	LinkFile := A_StartupCommon "`\" A_ScriptNameNoExt ".lnk"

	if FileExist( LinkFile ) {

		Menu, tray, UnCheck, Autostart
		FileDelete, %LinkFile%
	} else {

		Menu, tray, Check, Autostart
		FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%
	}
}

Tray_Config() {

	global A_ScriptNameNoExt
	Run, notepad.exe  "%A_ScriptDir%\%A_ScriptNameNoExt%.ini"
}

Exit:
ExitApp