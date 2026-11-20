Steam_Sample() {
    static supportsPrivate := Steam_HasPrivateCounters()
    result := {helpers: [], helperMiB: 0, steamMiB: 0, missed: 0, ok: false
             , metric: (supportsPrivate ? "private WS" : "working set")}
    snapshot := DllCall("CreateToolhelp32Snapshot", "UInt", 2, "UInt", 0, "Ptr") ; TH32CS_SNAPPROCESS
    if (snapshot = -1)
        return result

    helperWorking := 0, helperPrivate := 0, totalWorking := 0, totalPrivate := 0
    entrySize := A_PtrSize = 8 ? 568 : 556
    nameOffset := A_PtrSize = 8 ? 44 : 36
    VarSetCapacity(entry, entrySize, 0)
    NumPut(entrySize, entry, 0, "UInt")
    try {
        hasEntry := DllCall("Process32FirstW", "Ptr", snapshot, "Ptr", &entry)
        while (hasEntry) {
            name := StrGet(&entry + nameOffset, "UTF-16")
            if (name = "steamwebhelper.exe" || name = "steam.exe") {
                pid := NumGet(entry, 8, "UInt")
                handle := Steam_OpenNamedProcess(pid, name, 0x1000, otherSession)
                readable := false
                if (handle) {
                    try readable := Steam_ReadCounters(handle, supportsPrivate, working, privateBytes)
                    finally DllCall("CloseHandle", "Ptr", handle)
                }
                if (readable) {
                    if (privateBytes < 0)
                        result.metric := "working set"
                    totalWorking += working, totalPrivate += privateBytes
                    if (name = "steamwebhelper.exe") {
                        result.helpers.Push(pid)
                        helperWorking += working, helperPrivate += privateBytes
                    }
                } else if (!otherSession)
                    result.missed++
            }
            hasEntry := DllCall("Process32NextW", "Ptr", snapshot, "Ptr", &entry)
        }
        result.ok := (A_LastError = 18) ; ERROR_NO_MORE_FILES
    } finally {
        DllCall("CloseHandle", "Ptr", snapshot)
    }

    ; If any readable process only has basic counters, use the same metric for all PIDs.
    usePrivate := result.metric = "private WS"
    result.helperMiB := (usePrivate ? helperPrivate : helperWorking) / 1048576
    result.steamMiB := (usePrivate ? totalPrivate : totalWorking) / 1048576
    return result
}

Steam_Trim(pid) {
    ; PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_SET_QUOTA
    handle := Steam_OpenNamedProcess(pid, "steamwebhelper.exe", 0x1100, otherSession)
    if (!handle)
        return false
    try return DllCall("K32EmptyWorkingSet", "Ptr", handle) != 0
    finally DllCall("CloseHandle", "Ptr", handle)
}

Steam_OpenNamedProcess(pid, expectedName, access, ByRef otherSession) {
    static ownSession := Steam_SessionId(DllCall("GetCurrentProcessId", "UInt"))
    handle := DllCall("OpenProcess", "UInt", access, "Int", false, "UInt", pid, "Ptr")
    session := Steam_SessionId(pid)
    otherSession := session >= 0 && ownSession >= 0 && session != ownSession
    if (!handle)
        return 0
    if (session >= 0 && session = ownSession) {
        ; Check the process bound to this handle, even if the sampled PID has since been reused.
        chars := 32768
        VarSetCapacity(path, chars * 2)
        if DllCall("QueryFullProcessImageNameW", "Ptr", handle, "UInt", 0, "Ptr", &path, "UInt*", chars) {
            fullPath := StrGet(&path, chars, "UTF-16")
            SplitPath, fullPath, name
            if (name = expectedName)
                return handle
        }
    }
    DllCall("CloseHandle", "Ptr", handle)
    return 0
}

Steam_SessionId(pid) {
    if DllCall("ProcessIdToSessionId", "UInt", pid, "UInt*", session)
        return session
    return -1
}

Steam_HasPrivateCounters() {
    ; Older Windows builds can accept a larger buffer while only filling the older fields.
    handle := DllCall("GetCurrentProcess", "Ptr")
    return Steam_ReadCounters(handle, true, working, privateBytes) && privateBytes > 0
}

Steam_ReadCounters(handle, preferPrivate, ByRef working, ByRef privateBytes) {
    privateBytes := -1
    if (preferPrivate) {
        ; PROCESS_MEMORY_COUNTERS_EX2 adds PrivateWorkingSetSize and SharedCommitUsage.
        extendedSize := 16 + 10 * A_PtrSize
        privateOffset := 8 + 9 * A_PtrSize
        VarSetCapacity(counters, extendedSize, 0)
        NumPut(extendedSize, counters, 0, "UInt")
        NumPut(-1, counters, privateOffset, "Ptr")
        if DllCall("K32GetProcessMemoryInfo", "Ptr", handle, "Ptr", &counters, "UInt", extendedSize) {
            working := NumGet(counters, 8 + A_PtrSize, "UPtr")
            if (NumGet(counters, privateOffset, "Ptr") != -1)
                privateBytes := NumGet(counters, privateOffset, "UPtr")
            return true
        }
    }
    basicSize := 8 + 8 * A_PtrSize ; PROCESS_MEMORY_COUNTERS
    VarSetCapacity(counters, basicSize, 0)
    NumPut(basicSize, counters, 0, "UInt")
    if !DllCall("K32GetProcessMemoryInfo", "Ptr", handle, "Ptr", &counters, "UInt", basicSize)
        return false
    working := NumGet(counters, 8 + A_PtrSize, "UPtr")
    return true
}
