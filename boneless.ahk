; BONELESS HAM v0.99
; Copyright Kikyujin / MULTiTApps Inc.
; Released under the MIT license
; 2025-06-07

Gui, Font, s12, Meiryo  ; 文字サイズ12pt、フォントMeiryo（日本語推奨）

; マルチ
Gui, Add, Text, x10, Stack
Gui, Add, Button, xp+70 yp gCopySelection, ▼
Gui, Add, Edit, x120 yp w300 h150 Multi WantReturn VScroll Wrap vCallsignM hwndhEdit1
Gui, Add, Text, xm w400 h1 0x10

; コールサイン
Gui, Add, Text, x10, Callsign
; AC ボタン
Gui, Add, Button, gClearHamlog xp+70, CL
Gui, Add, Edit, vCallsign hwndCallsignHwnd x120 yp w160

; Get/Set ボタン
Gui, Add, Button, gSendToHamlog xp+220 yp, Set
Gui, Add, Button, gUpdateFromHamlog xp+40, Get

; 日付
Gui, Add, Text, x10, yy/mm/dd
Gui, Add, Button, gGetTodayDate xp+110, Today
Gui, Add, Edit, vDate xp+70 w100
Gui, Add, CheckBox, vLockDate xp+110, Lock
; Save ボタン ： 不安定なので一旦実装中止
; Gui, Add, Button, gSaveHamlog xp+60, Save
; Gui, Add, CheckBox, vSaveClear xp+40 Checked, Clear

; 時間
Gui, Add, Text, x10, hh:mm[JU]
Gui, Add, Button, gSetNowTime xp+110, Now
Gui, Add, Edit, vTime xp+70 w100
; Gui, Add, CheckBox, vLockTime xp+110, Lock


; HIS MY FREQ MODE
Gui, Add, Text, x10, His
Gui, Add, Edit, vHis xp+30 w40 hwndhHis

Gui, Add, Text, xp+50, My
Gui, Add, Edit, vMy xp+30 w40

Gui, Add, Text, xp+50, Freq
Gui, Add, Edit, vFreq xp+50 w50
; Gui, Add, ComboBox, vFreq xp+30 w50, 430|144|1200|50|28|21|7

Gui, Add, Text, xp+60 yp+2, Mode
Gui, Add, Edit, vMode xp+50 w50
; Gui, Add, ComboBox, vMode xp+30 yp-2 w50, FM|SSB|CW|DV|AM

; Code GL QSL
Gui, Add, Text, x10, Code
Gui, Add, Edit, vCode xp+50 w80

Gui, Add, Text, xp+90, G/L
Gui, Add, Edit, vGL xp+30 w80

Gui, Add, Text, xp+90, QSL
Gui, Add, Edit, vQSL xp+40 w40

; QRA
Gui, Add, Text, x10, QRA
Gui, Add, Edit, vName xp+50 w250

; QTH
Gui, Add, Text, x10, QTH
Gui, Add, Edit, vQTH xp+50 w250

; Rem1
Gui, Add, Text, x10, Rem1
Gui, Add, Edit, vRem1 xp+50 w250
Gui, Add, CheckBox, vLockRem1 xp+260, Lock

; Rem2
Gui, Add, Text, x10, Rem2
Gui, Add, Edit, vRem2 xp+50 w250
Gui, Add, CheckBox, vLockRem2 xp+260, Lock

; WM_KEYDOWN（0x100） をフック
OnMessage(0x100, "HandleKeyDown")

Gui, Show,, ボンレスHAM v0.99

Gosub, UpdateFromHamlog

SetTimer, CheckIME, 100

; クリアしておく
Gosub, UpdateFromHamlog

return

; --- ホットキー定義 ---
#IfWinActive ahk_class AutoHotkeyGUI
F5::Gosub, UpdateFromHamlog
#IfWinActive

; コピーして送る
CopySelection:
    ; 選択範囲取得
    VarSetCapacity(selStart, 4, 0)
    VarSetCapacity(selEnd, 4, 0)
    SendMessage, 0xB0, &selStart, &selEnd,, ahk_id %hEdit1%
    Start := NumGet(selStart, 0, "UInt")
    End := NumGet(selEnd, 0, "UInt")

    ; テキスト取得
    ControlGetText, fullText,, ahk_id %hEdit1%
    SelectedText := SubStr(fullText, Start + 1, End - Start)
 
    ; 改行処理 → 最初の行だけ使う（CR除去）
    lines := StrSplit(SelectedText, "`n")
    SelectedText := Trim(lines[1], "`r`n `t")

  
    if (SelectedText != "") {
    ;    MsgBox, %SelectedText%
        Gosub, ClearHamlog
        GuiControl,, Edit2, %SelectedText%
        Gosub, CheckCallsign
    }

return

; ウィンドウが閉じたらクローズ
GuiClose:
    ExitApp

; HAMLOGのLOGダイアログを見つける
GetHamlogWindow(retry := 0) {
    this_id := ""
    WinGet, idList, List, ahk_class TForm_A
    Loop, %idList%
    {
        this_id := idList%A_Index%
        WinGetTitle, title, ahk_id %this_id%
        if InStr(title, "ＬＯＧ")
            return this_id
    }

    ; 見つからなかったらダメ元でメインウィンドウにEnter送る
    WinActivate, ahk_class TThwin
    if WinExist("ahk_class TThwin") {
        ControlSend,, {Enter}, ahk_class TThwin
        Sleep, 500  ; 起動待ち（必要に応じて調整）
        WinGet, this_id, ID, ahk_class TForm_A ahk_exe hamlogw.exe
    } 

    if (!this_id) {
        ; TThwinがいなかったらメッセージ or 自動起動
        if (retry < 3) {
            Run, C:\HAMLOG\hamlogw.exe
            Sleep, 1500
            return GetHamlogWindow(retry + 1)
        } else {
            MsgBox, 48, HAMLOGが見つかりません
        }
    }
    return this_id
}

; Clearボタン
ClearHamlog:
    hwnd := GetHamlogWindow()
    if (!hwnd) {
        MsgBox, LOG - を含むHAMLOGウィンドウが見つかりませんでした
        return
    }
    WinActivate, ahk_id %hwnd%
    WinWaitActive, ahk_id %hwnd%,, 1
    Send, !a
    Sleep, 300
    Gosub, UpdateFromHamlog
    WinActivate, ahk_class AutoHotkeyGUI
return


HandleKeyDown(wParam, lParam, msg, hwnd)
{
    global CallsignHwnd
    if (hwnd == CallsignHwnd) {
        if (wParam == 13) { ; VK_RETURN（Enterキー）
            SetTimer, CheckCallsignTimer, -10
        }
    }
}

CheckCallsignTimer:
    Gosub, CheckCallsign
return

CheckCallsign:
    Gui, Submit, NoHide

    hwnd := GetHamlogWindow()
    if (!hwnd) {
        MsgBox, LOG - を含むHAMLOGウィンドウが見つかりませんでした
        return
    }
    ; ① コールサインを送る
    ControlSetText, TEdit14, %Callsign%, ahk_id %hwnd%
    Sleep, 100
    ControlSend, TEdit14, {Enter}, ahk_id %hwnd%

    ; ② 少し待って日付・時間を取得して自GUIに反映
    Sleep, 300  ; HAMLOG側で更新されるのを待つ（必要なら調整）

    Gosub, UpdateFromHamlog
    Sleep, 300

    WinActivate, ahk_class AutoHotkeyGUI

    ControlFocus,, ahk_id %hHis%
    SendMessage, 0xB1, 0, -1,, ahk_id %hHis%


return

; 今日
GetTodayDate:
Today := SubStr(A_YYYY,3) . "/" . A_MM . "/" . A_DD
GuiControl,, Date, %Today%
return

; いま
SetNowTime:
    NowTime := A_Hour . ":" . A_Min . "J"
    GuiControl,, Time, %NowTime%
return

; HAMLOGに送信
SendToHamlog:
    Gui, Submit, NoHide

    hwnd := GetHamlogWindow()
    if (!hwnd) {
        MsgBox, LOG - を含むHAMLOGウィンドウが見つかりませんでした
        return
    }
    WinActivate, ahk_id %hwnd%
    WinWaitActive, ahk_id %hwnd%,, 1

    ControlSetText, TEdit14, %Callsign%, ahk_id %hwnd%
    ; コールサインを入れたあとにEnterしないとセーブできないクソ仕様回避
    Sleep, 100
    ControlSend, TEdit14, {Enter}, ahk_id %hwnd%
    Sleep, 300  ; HAMLOG側で更新されるのを待つ（必要なら調整）

    ControlSetText, TEdit11, %His%, ahk_id %hwnd%
    ControlSetText, TEdit10, %My%, ahk_id %hwnd%
    ControlSetText, TEdit13, %Date%, ahk_id %hwnd%
    ControlSetText, TEdit12, %Time%, ahk_id %hwnd%
    ControlSetText, TEdit9, %Freq%, ahk_id %hwnd%
    ControlSetText, TEdit8, %Mode%, ahk_id %hwnd%
    ControlSetText, TEdit7, %Code%, ahk_id %hwnd%
    ControlSetText, TEdit6, %GL%, ahk_id %hwnd%
    ControlSetText, TEdit5, %QSL%, ahk_id %hwnd%
    ControlSetText, TEdit4, %Name%, ahk_id %hwnd%
    ControlSetText, TEdit3, %QTH%, ahk_id %hwnd%
    ControlSetText, TEdit2, %Rem1%, ahk_id %hwnd%
    ControlSetText, TEdit1, %Rem2%, ahk_id %hwnd%
    Sleep, 300  ; HAMLOG側で更新されるのを待つ（必要なら調整）

return

; HAMLOGからゲット
UpdateFromHamlog:
    Gui, Submit, NoHide
    ; あえて一番上にあるTForm_Aを使う
    ; 各コントロールの値をHAMLOGから取得し、GUIに反映
    ControlGetText, Callsign, TEdit14, ahk_class TForm_A
    if (LockDate == 0) {
        ControlGetText, Date, TEdit13, ahk_class TForm_A
        Date := RegExReplace(Date, "\s")
    }
    ; if (LockTime == 0) {
        ControlGetText, Time, TEdit12, ahk_class TForm_A
        Time := RegExReplace(Time, "\s")
    ; }
    ControlGetText, His,  TEdit11, ahk_class TForm_A
    ControlGetText, My,   TEdit10, ahk_class TForm_A
    ControlGetText, Freq, TEdit9, ahk_class TForm_A
    ControlGetText, Mode, TEdit8, ahk_class TForm_A
    ControlGetText, Code, TEdit7, ahk_class TForm_A
    ControlGetText, GL,   TEdit6, ahk_class TForm_A
    ControlGetText, QSL,  TEdit5, ahk_class TForm_A
    ControlGetText, Name, TEdit4, ahk_class TForm_A
    ControlGetText, QTH,  TEdit3, ahk_class TForm_A
    if (LockRem1 == 0) {
        ControlGetText, Rem1, TEdit2, ahk_class TForm_A
    }
    if (LockRem2 == 0) {
        ControlGetText, Rem2, TEdit1, ahk_class TForm_A
    }
    Gosub, SetGUI
return

; Saveボタン
; SaveHamlog:
; Gosub, SendToHamlog
; WinActivate, ahk_id %hwnd%
; WinWaitActive, ahk_id %hwnd%,, 1
; Sleep, 300
; ControlClick, TButton1, ahk_id %hwnd%
; WinActivate, ahk_class AutoHotkeyGUI
; if (SaveClear == 1) {
;     Gosub, ForceClear
; }
; return

SetGUI:
    GuiControl,, Callsign, %Callsign%
    GuiControl,, Date,     %Date%
    GuiControl,, Time,     %Time%
    GuiControl,, His,      %His%
    GuiControl,, My,       %My%
    GuiControl,, Freq,     %Freq%
    GuiControl,, Mode,     %Mode%
    GuiControl,, Code,     %Code%
    GuiControl,, GL,       %GL%
    GuiControl,, QSL,      %QSL%
    GuiControl,, Name,     %Name%
    GuiControl,, QTH,      %QTH%
    GuiControl,, Rem1,     %Rem1%
    GuiControl,, Rem2,     %Rem2%
return

ForceClear:
    Callsign := ""
    if (LockDate == 0) {
        Date = //
    }
    ; if (LockTime == 0) {
        Time = :
    ; }
    Code := ""
    GL := ""
    QSL := ""
    Name := ""
    QTH := ""
    if (LockRem1 == 0) {
        Rem1 := ""
    }
    if (LockRem2 == 0) {
        Rem2 := ""
    }
    Gosub, SetGUI
return

; IME ON/OFF

CheckIME:
    ControlGetFocus, focusCtrl, A
    if (focusCtrl ~= "^Edit(11|10|[1-9])$") {
        WinGet, hwndActive, ID, A
        ActivateIME(hwndActive, false)
    } else {
    }
return

ActivateIME(hCtl, onOff := true) {
    hIMC := DllCall("imm32\ImmGetContext", "Ptr", hCtl, "Ptr")
    DllCall("imm32\ImmSetOpenStatus", "Ptr", hIMC, "Int", onOff)
    DllCall("imm32\ImmReleaseContext", "Ptr", hCtl, "Ptr", hIMC)
}
