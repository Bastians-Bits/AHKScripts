;--------------------------------------------------------------------------------------------------------------------------------------------------------------
;
; G13.ahk - AutoHotKey Script to communicate with the Logitech G13 and process
; the key input
;
; Currently Supported:
;    - G1 to G22
; JoyStick Button 1 and 2
;
;--------------------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
; Programm start. Sets all options and global variables
;
;------------------------------------------------------------------------------
#NoEnv                          ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn                         ; Enable warnings to assist with detecting common errors.
SendMode Input                  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%     ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\AHKHID.ahk ; Must be in auto-execute section if I want to use the constants

; Array of all buttons. Key = Position of the bit in the button bytes
buttons := {}
buttons.8 := "G1"
buttons.7 := "G2"
buttons.6 := "G3"
buttons.5 := "G4"
buttons.4 := "G5"
buttons.3 := "G6"
buttons.2 := "G7"
buttons.1 := "G8"
buttons.16 := "G9"
buttons.15:= "G10"
buttons.14 := "G11"
buttons.13 := "G12"
buttons.12 := "G13"
buttons.11 := "G14"
buttons.10 := "G15"
buttons.9 := "G16"
buttons.24 := "G17"
buttons.23 := "G18"
buttons.22 := "G19"
buttons.21 := "G20"
buttons.20 := "G21"
buttons.19 := "G22"
buttons.39 := "B1"
buttons.38 := "B2"

; A List of all bits which should not be processed
exceptions := [17, 18, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36 37, 40]

; Create GUI to receive messages
Gui, +LastFound
hGui := WinExist()

; Create the gui for the key label on the screen
; From: https://autohotkey.com/board/topic/77403-show-text-during-program/
OSDColour2 = EAAA99                                                     ; Can be any RGB color (it will be made transparent below).
Gui, 2: +LastFound +AlwaysOnTop -Caption +ToolWindow                    ; +ToolWindow avoids a taskbar button and an alt-tab menu item.
Gui, 2:Font, s64, Times New Roman                                       ; Set a large font size (32-point).
Gui, 2:Add, Text, vOSDControl cBlue x60 y200, XXXXXXYYYYYYXXXXXXYYYYYY  ; XX & YY serve to auto-size the window; add some random letters to enable a longer string of text (but it might not fit on the screen).
Gui, 2:Color, %OSDColour2%
WinSet, TransColor, %OSDColour2% 110                                    ; Make all pixels of this color transparent and make the text itself translucent (150)
Gui, 2:Show, NoActivate, OSDGui
Gui, 2:Show, Hide


; Intercept WM_INPUT messages
WM_INPUT := 0xFF
OnMessage(WM_INPUT, "InputMsg")

; Register Remote Control with RIDEV_INPUTSINK and RIDEV_PAGEONLY (inputsink for background support and pageonly 'cause it works)
; EDIT HERE your device id
r := AHKHID_Register(65280, 0, hGui, 288)

; The actual script ends here, everything else are functions
Return

;------------------------------------------------------------------------------
;
; InputMsg - Gets called by a key event and processes the information
;    This method determines which sub-function should be called
;
;------------------------------------------------------------------------------
InputMsg(wParam, lParam) {
    local devh
    Critical

    ; Reading of the current active window for usage
    WinGet, ACTIVE_PID, PID, A          ; Stores the ahk_pid of the active window
    WinGet, ACTIVE_EXE, ProcessName, A  ; Stores the ahk_exe of the active window
    WinGetClass, ACTIVE_CLASS, A        ; Stores the ahk_class of the active window
    WinGetTitle, ACTIVE_TITLE, A        ; Stores the title of the active window    

    ; Get handle of device
    devh := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)

    ; Check for error
    ; EDIT HERE your device info (the example2 for more help)
    If (devh <> -1) ;Device check
        And (AHKHID_GetDevInfo(devh, DI_DEVTYPE, True) = RIM_TYPEHID)
        And (AHKHID_GetDevInfo(devh, DI_HID_VENDORID, True) = 1133)
        And (AHKHID_GetDevInfo(devh, DI_HID_PRODUCTID, True) = 49692)
        And (AHKHID_GetDevInfo(devh, DI_HID_VERSIONNUMBER, True) = 515) {
        local bitsPressed := []

        ; Get the data
        length := AHKHID_GetInputData(lParam, uData)

        ; Check for answer
        If (length <> -1) {
            local dataReveived = Bin2Hex(&uData, length)    ; Parse the data to hex (better to handle)
            local pos = 7                                   ; for buttons, start from the seventh byte
            while (pos <= 16) {
                Local val = SubStr(dataReveived, pos, 1)    ; Get a single byte ...
                local binVal = ConvertBase(16, 2, val)      ; ... and convert it to binary
                VarSetCapacity(paddedVal, 20)               ; Pad the result to 4 digits
                DllCall("wsprintf", "Str", paddedVal, "Str", "%04d", "Int", binVal, "Cdecl")
                local relPos = 1
                Loop, Parse, paddedVal
                {
                    if (A_loopField = 1) {                          ; If the bit is set
                        local totalPos = relPos + ((pos - 7) * 4)   ; calc its positon
                        if (HasVal(exceptions, totalPos) = 0) {     ; Make sure it is no exception ...
                            local button = buttons[totalPos]        ; and get the button name
                            bitsPressed.Push(button)
                            ; Debug line:;MsgBox % "Pushing RelPos " . relPos . " Pos " . pos . " Byte (Rev) " paddedValReverse . " Byte " .  paddedVal . " Total " totalPos
                        }
                    }
                    relPos += 1
                }
                pos += 1
            }
            if (bitsPressed.Length() > 0) {
                SortArray(bitsPressed)                                  ; To get the buttons in the right order (alphabetical)
                if IsLabel("Button_" . join(bitsPressed)) {
                    local targetLabel = "Button_" . join(bitsPressed)   ; Build the sub-function name ...
                    Gosub, %targetLabel%                                ; ... and call it
                    return
                }
            }
        }
    }
}

;------------------------------------------------------------------------------
;
; Sub-Functions for Buttons
;
;------------------------------------------------------------------------------
Button_G1:
    if (ACTIVE_CLASS = "SWT_Window0") AND (ACTIVE_EXE = "javaw.exe") { ; Eclipse
        OSD("New Class")
        SendInput ^n
        Sleep 500
        SendInput Class
        Sleep 500
        SendInput {Enter}
        return
    }
    SendInput ^n
return

Button_G1_G20:
    if (ACTIVE_CLASS = "SWT_Window0") AND (ACTIVE_EXE = "javaw.exe") { ; Eclipse
        OSD("New File")
        SendInput ^n
        Sleep 500
        SendInput {Enter} ; Eclipse set the focus automatically to 'File'
        return
    }
    
return

Button_G2:
    if (ACTIVE_CLASS = "SWT_Window0") AND (ACTIVE_EXE = "javaw.exe") { ; Eclipse
        OSD("New Package")
        SendInput ^n
        Sleep 500
        SendInput Package
        Sleep 500
        SendInput {Enter}
        return
    }
return

;------------------------------------------------------------------------------
;
; Helper functions
;
;-----------------------------------------------------------------------------
; Sort an Array 
; From: https://sites.google.com/site/ahkref/custom-functions/sortarray
SortArray(Array, Order="A") {
    ;Order A: Ascending, D: Descending, R: Reverse
    MaxIndex := ObjMaxIndex(Array)
    If (Order = "R") {
        count := 0
        Loop, % MaxIndex
            ObjInsert(Array, ObjRemove(Array, MaxIndex - count++))
        Return
    }
    Partitions := "|" ObjMinIndex(Array) "," MaxIndex
    Loop {
        comma := InStr(this_partition := SubStr(Partitions, InStr(Partitions, "|", False, 0)+1), ",")
        spos := pivot := SubStr(this_partition, 1, comma-1) , epos := SubStr(this_partition, comma+1)    
        if (Order = "A") {    
            Loop, % epos - spos {
                if (Array[pivot] > Array[A_Index+spos])
                    ObjInsert(Array, pivot++, ObjRemove(Array, A_Index+spos))    
            }
        } else {
            Loop, % epos - spos {
                if (Array[pivot] < Array[A_Index+spos])
                    ObjInsert(Array, pivot++, ObjRemove(Array, A_Index+spos))    
            }
        }
        Partitions := SubStr(Partitions, 1, InStr(Partitions, "|", False, 0)-1)
        if (pivot - spos) > 1    ;if more than one elements
            Partitions .= "|" spos "," pivot-1        ;the left partition
        if (epos - pivot) > 1    ;if more than one elements
            Partitions .= "|" pivot+1 "," epos        ;the right partition
    } Until !Partitions
}

; Check whether a value exists in an array or not
; From: Forgot to copy the link
HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

; Join an array for printing
; From: Forgot to copy the link
join(strArray) {
  s := ""
  for i,v in strArray
    s .= "_" . v
  return substr(s, 2)
}

; Read from the address and convert to hex
; From: example2
Bin2Hex(addr,len) {
    Static fun, ptr 
    If (fun = "") {
        If A_IsUnicode
            If (A_PtrSize = 8)
                h=4533c94c8bd14585c07e63458bd86690440fb60248ffc2418bc9410fb6c0c0e8043c090fb6c00f97c14180e00f66f7d96683e1076603c8410fb6c06683c1304180f8096641890a418bc90f97c166f7d94983c2046683e1076603c86683c13049ffcb6641894afe75a76645890ac366448909c3
            Else h=558B6C241085ED7E5F568B74240C578B7C24148A078AC8C0E90447BA090000003AD11BD2F7DA66F7DA0FB6C96683E2076603D16683C230668916240FB2093AD01BC9F7D966F7D96683E1070FB6D06603CA6683C13066894E0283C6044D75B433C05F6689065E5DC38B54240833C966890A5DC3
        Else h=558B6C241085ED7E45568B74240C578B7C24148A078AC8C0E9044780F9090F97C2F6DA80E20702D1240F80C2303C090F97C1F6D980E10702C880C1308816884E0183C6024D75CC5FC606005E5DC38B542408C602005DC3
        VarSetCapacity(fun, StrLen(h) // 2)
        Loop % StrLen(h) // 2
            NumPut("0x" . SubStr(h, 2 * A_Index - 1, 2), fun, A_Index - 1, "Char")
        ptr := A_PtrSize ? "Ptr" : "UInt"
        DllCall("VirtualProtect", ptr, &fun, ptr, VarSetCapacity(fun), "UInt", 0x40, "UInt*", 0)
    }
    VarSetCapacity(hex, A_IsUnicode ? 4 * len + 2 : 2 * len + 1)
    DllCall(&fun, ptr, &hex, ptr, addr, "UInt", len, "CDecl")
    VarSetCapacity(hex, -1) ; update StrLen
    Return hex
}

; Convert between number system
; From: Forgot to copy the link
ConvertBase(InputBase, OutputBase, nptr) {   ; Base 2 - 36
    static u := A_IsUnicode ? "_wcstoui64" : "_strtoui64"
    static v := A_IsUnicode ? "_i64tow"    : "_i64toa"
    VarSetCapacity(s, 66, 0)
    value := DllCall("msvcrt.dll\" u, "Str", nptr, "UInt", 0, "UInt", InputBase, "CDECL Int64")
    DllCall("msvcrt.dll\" v, "Int64", value, "Str", s, "UInt", OutputBase, "CDECL")
    return s
}

; Put the below anywhere in your script that is not part of a subroutine. Not at the point where you want the actual text to appear on screen: just at the bottom of your script is fine.
; https://autohotkey.com/board/topic/77403-show-text-during-program/
OSD(Text="OSD",Colour="Black",Duration="2000",Font="Times New Roman",Size="64")
{   
    local x := 0
    local y := A_ScreenHeight - 350
    ; Displays an On-Screen Display, a text in the middle of the screen.
    Gui, 2:Font, c%Colour% s%Size%, %Font%  ; If desired, use a line like this to set a new default font for the window.
    GuiControl, 2:Font, OSDControl          ; Put the above font into effect for a control.
    GuiControl, 2:, OSDControl, %Text%
    Gui, 2:Show, x%x% y%y% NoActivate, OSDGui      ; NoActivate avoids deactivating the currently active window; add "X600 Y800" to put the text at some specific place on the screen instead of centred.
    SetTimer, OSDTimer, -%Duration%
    Return 
}

OSDTimer:
Gui, 2:Show, Hide
Return
;------------------------------------------------------------------------------
; END
;------------------------------------------------------------------------------
