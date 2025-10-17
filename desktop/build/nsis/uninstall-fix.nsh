; Work around https://github.com/electron-userland/electron-builder/issues/9181
; by tolerating non-zero exit codes from the previous version's uninstaller
; once its executable has actually been removed. The stock handler bails out,
; leaving the app uninstalled; we opt to continue with the installation instead.
!macro customHandleUninstallResultImpl
  IfErrors 0 +3
    DetailPrint `Uninstall was not successful. Not able to launch uninstaller!`
    Return

  ${if} $R0 == 0
    Return
  ${endif}

  StrCpy $0 $installationDir
  ${if} $0 == ""
    StrCpy $0 "$INSTDIR"
  ${endif}
  StrCpy $1 "$0\${APP_EXECUTABLE_FILENAME}"

  IfFileExists "$1" 0 +5
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(uninstallFailed): $R0"
    DetailPrint `Uninstall was not successful. Uninstaller error code: $R0.`
    SetErrorLevel 2
    Quit

  DetailPrint `Uninstaller returned $R0 but "${APP_EXECUTABLE_FILENAME}" was not found in "$0". Continuing installation.`
  StrCpy $R0 0
  ClearErrors
!macroend

!macro customUnInstallCheck
  !insertmacro customHandleUninstallResultImpl
!macroend

!macro customUnInstallCheckCurrentUser
  !insertmacro customHandleUninstallResultImpl
!macroend
