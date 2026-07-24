#Requires AutoHotkey v2.0-a

; Run every line
Critical

#SingleInstance force

; Switch windows instantaeously
SetWinDelay -1

; Avoid warning dialogue about over-hits
A_MaxHotkeysPerInterval := 50000
A_HotkeyInterval := 1
#WinActivateForce

ButtonLayout := IniRead("config.ini", "ButtonMap", "ButtonLayout")
ConfirmButton := IniRead("config.ini", "ButtonMap", "ConfirmButton")
CancelButton := IniRead("config.ini", "ButtonMap", "CancelButton")
MainMenuButton := IniRead("config.ini", "ButtonMap", "MainMenuButton")
ActiveWindowButton := IniRead("config.ini", "ButtonMap", "ActiveWindowButton")
ButtonLayout := StrUpper(ButtonLayout)
ConfirmButton := StrUpper(ConfirmButton)
CancelButton := StrUpper(CancelButton)
MainMenuButton := StrUpper(MainMenuButton)
ActiveWindowButton := StrUpper(ActiveWindowButton)


lastKeyPressed := ""
isLeftTriggerDown := false
isRightTriggerDown := false
isEnvironmentDialogOpen := false

Persistent  ; Keep this script running until the user explicitly exits it.
SetTimer CheckPOVState, 10 ; Poll for POV hat every 10ms

CheckPOVState() {
If WinActive("ahk_class FFXiClass") {
  global lastKeyPressed
  joyp := GetKeyState("JoyPOV")

  If (isLeftTriggerDown or isRightTriggerDown or isEnvironmentDialogOpen) {
    If (joyp = 0) {
      If (lastKeyPressed != "dpad_up") {
        SendInput "{f1}"

        lastKeyPressed := "dpad_up"
      }
    } else If (joyp = 9000) {
      If (lastKeyPressed != "dpad_right") {
        SendInput "{f2}"

        lastKeyPressed:= "dpad_right"
      }
    } else If (joyp = 18000) {
      If (lastKeyPressed != "dpad_down") {
        SendInput "{f3}"

        lastKeyPressed:= "dpad_down"
      }
    } else If (joyp = 27000) {
      If (lastKeyPressed != "dpad_left") {
        SendInput "{f4}"

        lastKeyPressed := "dpad_left"
      }
    }
  }

  If (joyp = -1 and lastKeyPressed != "") {
      lastKeyPressed:= ""
  }
}
}

; Helper subroutines. *DON'T* modify these to remap, instead just change which buttons call them
SendConfirmKey() {
  WinActivate "Cindervale"
  SendInput "{Enter}"
}
SendCancelKey() {
  WinActivate "Cindervale"
  SendInput "{Esc}"
}
SendMainMenuKey() {
  WinActivate "Cindervale"
  SendInput "{NumpadSub}"

}
SendActiveWindowKey() {
  WinActivate "Cindervale"
  SendInput "{NumpadAdd}"
}

; Gamecube Y Button (Playstation Triangle, Xbox Y Button, Nintendo X Button, TOP face button)
;#HotIf WinActive("ahk_class FFXiClass")
Joy4:: {
  If (isLeftTriggerDown or isRightTriggerDown)
  {
    SendInput "{f8}"
  }
  else 
  {
    If (ButtonLayout = "GAMECUBE" or ButtonLayout = "XBOX") {
      If (ConfirmButton = "Y") {
        SendConfirmKey()
      } else If (CancelButton = "Y") {
        SendCancelKey()
      } else If (MainMenuButton = "Y") {
        SendMainMenuKey()
      } else If (ActiveWindowButton = "Y") {
        SendActiveWindowKey()
      }
    } else If (ButtonLayout = "PLAYSTATION") {
      If (ConfirmButton = "TRIANGLE") {
        SendConfirmKey()
      } else If (CancelButton = "TRIANGLE") {
        SendCancelKey()
      } else If (MainMenuButton = "TRIANGLE") {
        SendMainMenuKey()
      } else If (ActiveWindowButton = "TRIANGLE") {
        SendActiveWindowKey()
      }
    } else If (ButtonLayout = "NINTENDO") {
      If (ConfirmButton = "X") {
        SendConfirmKey()
      } else If (CancelButton = "X") {
        SendCancelKey()
      } else If (MainMenuButton = "X") {
        SendMainMenuKey()
      } else If (ActiveWindowButton = "X") {
        SendActiveWindowKey()
      }
    }
  }
}
;#HotIf

; Gamecube B Button (Playstation Square, Xbox X Button, Nintendo Y Button, LEFT face button)
Joy1:: {
  If WinActive("ahk_class FFXiClass") {
    If (isLeftTriggerDown or isRightTriggerDown) {
      SendInput "{f6}"
    } else {
      If (ButtonLayout = "GAMECUBE") {
        If (ConfirmButton = "B") {
          SendConfirmKey()
        } else If (CancelButton = "B") {
          SendCancelKey()
        } else If (MainMenuButton = "B") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "B") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "XBOX") {
        If (ConfirmButton = "X") {
          SendConfirmKey()
        } else If (CancelButton = "X") {
          SendCancelKey()
        } else If (MainMenuButton = "X") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "X") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "PLAYSTATION") {
        If (ConfirmButton = "SQUARE") {
          SendConfirmKey()
        } else If (CancelButton = "SQUARE") {
          SendCancelKey()
        } else If (MainMenuButton = "SQUARE") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "SQUARE") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "NINTENDO") {
        If (ConfirmButton = "Y") {
          SendConfirmKey()
        } else If (CancelButton = "Y") {
          SendCancelKey()
        } else If (MainMenuButton = "Y") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "Y") {
          SendActiveWindowKey()
        }
      }
    }
  }
}

; Gamecube A Button (Playstation Cross, Xbox A Button, Nintendo B Button, BOTTOM face button)
Joy2:: {
  If WinActive("ahk_class FFXiClass") {
    If (isLeftTriggerDown or isRightTriggerDown) {
      SendInput "{f5}"
    } else {
      If (ButtonLayout = "GAMECUBE" or ButtonLayout = "XBOX") {
        If (ConfirmButton = "A") {
          SendConfirmKey()
        } else If (CancelButton = "A") {
          SendCancelKey()
        } else If (MainMenuButton = "A") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "A") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "PLAYSTATION") {
        If (ConfirmButton = "CROSS") {
          SendConfirmKey()
        } else If (CancelButton = "CROSS") {
          SendCancelKey()
        } else If (MainMenuButton = "CROSS") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "CROSS") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "NINTENDO") {
        If (ConfirmButton = "B") {
          SendConfirmKey()
        } else If (CancelButton = "B") {
          SendCancelKey()
        } else If (MainMenuButton = "B") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "B") {
          SendActiveWindowKey()
        }
      }
    }
  }
}

; Gamecube X Button (Playstation Circle, Xbox B Button, Nintendo A Button, RIGHT face button)
Joy3:: {
  If WinActive("ahk_class FFXiClass") {
    If (isLeftTriggerDown or isRightTriggerDown) {
      SendInput "{f7}"
    } else {
      If (ButtonLayout = "GAMECUBE") {
        If (ConfirmButton = "X") {
          SendConfirmKey()
        } else If (CancelButton = "X") {
          SendCancelKey()
        } else If (MainMenuButton = "X") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "X") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "XBOX") {
        If (ConfirmButton = "B") {
          SendConfirmKey()
        } else If (CancelButton = "B") {
          SendCancelKey()
        } else If (MainMenuButton = "B") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "B") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "PLAYSTATION") {
        If (ConfirmButton = "CIRCLE") {
          SendConfirmKey()
        } else If (CancelButton = "CIRCLE") {
          SendCancelKey()
        } else If (MainMenuButton = "CIRCLE") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "CIRCLE") {
          SendActiveWindowKey()
        }
      } else If (ButtonLayout = "NINTENDO") {
        If (ConfirmButton = "A") {
          SendConfirmKey()
        } else If (CancelButton = "A") {
          SendCancelKey()
        } else If (MainMenuButton = "A") {
          SendMainMenuKey()
        } else If (ActiveWindowButton = "A") {
          SendActiveWindowKey()
        }
      }
    }
  }
}

; Left Trigger
Joy7:: {
  If WinActive("ahk_class FFXiClass") {
    SendInput "{Ctrl down}"
    SendInput "{f11 down}"
    isLeftTriggerDown := true
    SetTimer WaitForButtonUp7, 10 ; Poll for button setting every 10ms
  }
}

WaitForButtonUp7() {
  If WinActive("ahk_class FFXiClass") {
    if GetKeyState("Joy7")  ; The button is still, down, so keep waiting.
        return
    ; Otherwise, the button has been released.
    SendInput "{f11 up}"
    if !isRightTriggerDown {
      SendInput "{Ctrl up}"
    }
    isLeftTriggerDown := false
    SetTimer WaitForButtonUp7, 0 ; Turn off polling
  }
}

; Right Trigger
Joy8:: {
If WinActive("ahk_class FFXiClass") {
  SendInput "{Ctrl down}"
  SendInput "{f12 down}"
  isRightTriggerDown := true
  SetTimer WaitForButtonUp8, 10 ; Poll for button setting every 10ms
}
}

WaitForButtonUp8() {
  If WinActive("ahk_class FFXiClass") {
    if GetKeyState("Joy8")  ; The button is still, down, so keep waiting.
        return
    ; Otherwise, the button has been released.
    SendInput "{f12 up}"
    if !isLeftTriggerDown {
      SendInput "{Ctrl up}"
    }
    isRightTriggerDown := false
    SetTimer WaitForButtonUp8, 0 ; Turn off polling
  }
}

; Opens/closes gamepad binding dialog
Joy9:: {
  If WinActive("ahk_class FFXiClass") {
    SendInput "{Ctrl down}"
    SendInput "{f9 down}"
    SetTimer WaitForButtonUp9, 10 ; Poll for button setting every 10ms
  }
}

WaitForButtonUp9() {
  If WinActive("ahk_class FFXiClass") {
    if GetKeyState("Joy9")  ; The button is still, down, so keep waiting.
        return
    ; Otherwise, the button has been released.
    SendInput "{f9 up}"
    SendInput "{Ctrl up}"
    SetTimer WaitForButtonUp9, 0 ; Turn off polling
  }
}

; Shows the environment list
Joy10:: {
  If WinActive("ahk_class FFXiClass") {
    SendInput "{Ctrl down}"
    SendInput "{f10 down}"
    isEnvironmentDialogOpen := true
    SetTimer WaitForButtonUp10, 10 ; Poll for button setting every 10ms
  }
}

WaitForButtonUp10() {
  If WinActive("ahk_class FFXiClass") {
    if GetKeyState("Joy10")  ; The button is still, down, so keep waiting.
        return
    ; Otherwise, the button has been released.
    SendInput "{f10 up}"
    SendInput "{Ctrl up}"
    isEnvironmentDialogOpen := false
    SetTimer WaitForButtonUp10, 0 ; Turn off polling
  }
}
