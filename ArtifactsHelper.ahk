#SingleInstance, Force
#NoEnv
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetDefaultMouseSpeed, 0.2
SendMode Event

if not A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
   ExitApp
}

Dock_HostID := 0

; BGR colors
selectedColorGreen := 0x40FFC0
selectedColorRed := 0x405FFF
selectedColorRedHighlighted := 0x3D5AF5

cardHeight := 0 ; This will at some time be set to be 1/6 of genshin window height
cardWidth := 0  
gridWidth := 0  
leftPanelPadding := 0 
gridPadding := 0  
searchHeight := 0       ; Height from bottom of card to the bottom of the red button. This is for a hovered card
result := null
Toggle=0


win1:
;msgbox,,, you clicked window 1
return


; Subroutine called when the Host window is closed.
!q::
OnHostDeath:
    Gui Win1: Destroy					;Destroys the client
    gosub, OnExit

OnExit:
	Dock_shutdown()
    WinClose, ahk_pid %nPID%		;close notepad
 	ExitApp


^p::
    Toggle := !Toggle
    if (Toggle) {
        Dock_HostID := WinExist("Genshin Impact") ;Define host. This must be defined globally, for dock.ahk to use this as the main window
        WinGetPos,,, winWidth,, ahk_id %Dock_HostID%
        viewportWidth := winWidth - 4                   ; Remove some little border (only for windowed mode. Make sure you edit this)
        leftPanelWidth := viewportWidth * 3/5           ; Left panel covers 60% of screen
        gridMargin := leftPanelWidth/68.657             ; Space between each card
        leftPanelPadding := leftPanelWidth/64.08       ; Space at edge of the left panel
        gridPadding := leftPanelPadding/1.4
        
        cardWidth := (leftPanelWidth - 7*gridMargin - 2* leftPanelPadding)/8
        cardHeight := cardWidth*1.2115                  ; the cards are 104:126 ratio

        searchHeight := cardHeight*0.865
        

        gridWidth := cardWidth + gridMargin             ; card width + the gap

        

        Gui Win1: +AlwaysOnTop +LastFound -Caption +ToolWindow +Border +E0x08000000  ;+0x08000000
        Gui Win1: Font, s9, Verdana
        Gui Win1: add, Text, gwin1, Artifacts helper ON
        Gui Win1: Margin, 0, -5
        Gui Win1: add, Text, gwin1, RClick%A_Tab%Remove
        Gui Win1: Margin, 0, -6
        Gui Win1: add, Text, gwin1, Ctrl+P%A_Tab%Turn off
        WinSet, Transparent, 150
        Gui Win1: Show, NoActivate
        hwnd1 := WinExist()

        result := dock(hwnd1, "x(,-0,13)  y(1,-1,-13) w(,175) h(,80)")			;the x(,-1) puts the right edge of client to left edge of host(remember the numbers are scaling not pixcels)
        ;Gui Win1: Show
        If (result != "OK") 
            msgbox % result
    } else {
        if (result){
            Dock_Shutdown()
            Gui Win1: destroy
        }
    }
    return
return


ClickPosAndMoveBack(x, y) { 
    BlockInput, MouseMove
    MouseGetPos, _MouseX, _MouseY
    OrigMouseX := _MouseX
    OrigMouseY := _MouseY
    MouseMove, x, y
    sleep 3
    Click
    sleep 3
    MouseMove, OrigMouseX, OrigMouseY
    BlockInput, MouseMoveOff
    return
}

; When right button is released
; Click on the red button if it exists
~RButton Up::
if (Toggle){
    ClickRedButtonSeemless()
}
return


CheckColorAboveAndBelow(x, y, numPixels, colorToCheck){
    Loop, 2 {
        ; index is {1,2}, and we want to make it {-1, 1}
        offsetNorm := ((A_Index - 1) * 2) - 1
        offset := offsetNorm * numPixels
        PixelGetColor, color2, x, y + offset
        if (color2 = colorToCheck)
            return true
    }
    return false    
}



ClickRedButtonSeemless(){
    global Dock_HostID, gridPadding, gridWidth, searchHeight, selectedColorRed, selectedColorRedHighlighted

    ; Find grid xm; -- in other words, move the cursor along x-axis to the left-most pixel of the card
    MouseGetPos, MouseX, MouseY
    WinGetPos hX, hY, hW, hH, ahk_id %Dock_HostID% 
    gridX := MouseX - Mod((MouseX - gridPadding), gridWidth)
    gridXAdjusted := gridX+4

    NewX := gridXAdjusted
    NewY := MouseY

    ; Find Y of red button
    found := false
    foundY := -1
    range := Ceil(searchHeight/8)
    Loop , %range% {
        i := (A_Index-1) * 8
        yOffset := NewY - i
        PixelGetColor, col1, NewX, yOffset
        if (col1 = selectedColorRed) {
            found := CheckColorAboveAndBelow(NewX, yOffset, 2, selectedColorRed)
        } else if (col1 = selectedColorRedHighlighted) {
            found := CheckColorAboveAndBelow(NewX, yOffset, 2, selectedColorRedHighlighted)
        }

        if (found) {
            foundY := NewY - i
            Break
        }
    }
    if (found) {
        shouldMoveToX := NewX
        shouldMoveToY := foundY - 0  ; adjust a little bit up
        ClickPosAndMoveBack(shouldMoveToX,shouldMoveToY)
        ;msgBox, done
    } else {
        ;msgBox, not found
    }
    return
}







#Include Dock.ahk
