#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ddnsmouse.ico
#AutoIt3Wrapper_Outfile=dynephant.Exe
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_After=build_all.bat
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; All version numbers will be overwritten by build_all.bat every time it is called!
; Set version in build_all.bat before building!
; The following compile directives work better (only) with pragma compile
#pragma compile(Comments, In-development Dynamic DNS Updater for Windows currently supporting dynv6.com service. Icon courtesy of http://www.how-to-draw-funny-cartoons.com)
#pragma compile(CompanyName, Chuck Renner)
#pragma compile(FileDescription, Dynephant Dynamic DNS Updater)
#pragma compile(FileVersion, 0.9.1.14)
#pragma compile(LegalCopyright, Copyright © 2016 Chuck Renner)
#pragma compile(ProductName, Dynephant)
#pragma compile(ProductVersion, 0.9.1.14)

; Change to y when debugging in SciTE
#AutoIt3Wrapper_Run_Debug_Mode=n

; Icon from:
;    Artist: Martin Berube (Available for custom work)
;    Iconset Homepage: http://www.how-to-draw-funny-cartoons.com/royalty-free-animals.html
;    License: Linkware (Backlink to http://www.how-to-draw-funny-cartoons.com required)
;    Commercial usage: Allowed
;    Words from the Artist:
;    Square Animal images in higher resolutions available here:
;    http://www.how-to-draw-funny-cartoons.com/royalty-free-animals.html

; Program written by and Copyright © 2016 Chuck Renner
#CS
	MIT License

	Copyright (c) 2016 Chuck Renner

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
#CE

; Below is a carefully constructed batch file that will
;    build all versions (x86 and x64, cli and gui) of the exe for this script
;    it copies this script and modifies the copy to try to prevent an infinite build loop.
;    It MUST have GnuWin32's sed utility to work!
;    It also uses the newest version of signtool.exe from the Windows 10 SDK to
;    sign and get signed timestamps for the created EXEs.
;    The locations of sed and signtool (and other files used) are set in the
;    "_build_all.bat" file
;    Building using the F7 key from SciTE will initially build just one version
;    (which will be overwritten), then call the batch file to build all versions.

$sTitle = "Dynephant"
$sVersion = "0.9.1.14"
$sCopyright = "Copyright © 2016 Chuck Renner"
$sMisc = "Icon courtesy of http://www.how-to-draw-funny-cartoons.com"
ConsoleWriteError($sTitle & " Version " & $sVersion & @LF)
ConsoleWriteError("Copyright (c) 2016 Chuck Renner" & @LF)
ConsoleWriteError($sMisc & @LF)
#include <InetConstants.au3>
#include <String.au3>
#include <Date.au3>
#include <TrayConstants.au3>
#include <WinAPIDlg.au3>
; considered GUI for missing command line parameters - NAH!
; considered checking for other instances of dynephant - NAH!
;     - actually useful to have multiple instances for multiple hosts
;     - tray icon actually present even when run from command line or in background from start.exe
; initialize defaults for command line parameters
$iconFile = "ddnsmouse.ico"
TraySetIcon($iconFile)
Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 2)
$mnuAbout = TrayCreateItem($sMisc)
$updateIpv6 = False
$updateIpv4 = False
$host = ""
$token = ""
$daemon = ""
$clearIpv4 = False
$clearIpv6 = False
; read and parse command line parameters
For $pCnt = 1 To $CmdLine[0]
	$param = $CmdLine[$pCnt]
	$pExp = _StringExplode($param, "=", 1)
	If UBound($pExp) > 1 Then
		;ConsoleWriteError("Explode happened!" & @LF)
		Switch $pExp[0]
			Case "-host"
				$host = $pExp[1]
			Case "-token"
				$token = $pExp[1]
			Case "-daemon"
				$daemon = Int($pExp[1])
				If $daemon And $daemon < 300 Then
					ConsoleWriteError("Using default update frequency of 1800 seconds (30 minutes) - minimum is 300 seconds (5 minutes)" & @LF)
					$daemon = 1800
				EndIf
				; No dynv6 support for clearing addresses via URL at this time
;~ 			Case "-4"
;~ 				$updateIpv4 = True
;~ 				If $pExp == "none" Then
;~ 					ConsoleWriteError("'" $param & "' set: will attempt to clear IPv4 address" & @LF)
;~ 					$clearIpv4 = True
;~ 				Else
;~ 					ConsoleWriteError("'" $param & "' not understood: will attempt to set IPv4 address: use -4=none to clear IPv4 address" & @LF)
;~ 					$clearIpv4 = False
;~ 				EndIf
;~ 			Case "-6"
;~ 				$updateIpv6 = True
;~ 				If $pExp == "none" Then
;~ 					ConsoleWriteError("'" $param & "' set: will attempt to clear IPv6 address" & @LF)
;~ 					$clearIpv6 = True
;~ 				Else
;~ 					ConsoleWriteError("'" $param & "' not understood: will attempt to set IPv6 address: use -6=none to clear IPv6 address" & @LF)
;~ 					$clearIpv6 = False
;~ 				EndIf
			Case Else
				ConsoleWriteError("Unknown parameter: '" & $param & "'" & @LF)
		EndSwitch
	Else
		;ConsoleWriteError("No explode happened!" & @LF)
		Switch $pExp[0]
			Case "-4"
				$updateIpv4 = True
			Case "-6"
				$updateIpv6 = True
			Case Else
				ConsoleWriteError("Unknown parameter: '" & $param & "'" & @LF)
		EndSwitch
	EndIf
Next
AutoItWinSetTitle($sTitle)
If $host == "" Then
	$errMsg = "Exiting: no host specified: use -host=<hostname> parameter (do not include '.dynv6.net' in hostname)"
	ConsoleWriteError($errMsg & @LF)
	TrayTip($sTitle, $errMsg, 10, $TIP_ICONHAND)
	Sleep(10000)
	Exit (1)
EndIf
If $token == "" Then
	$errMsg = "Exiting: no token specified: use -token=<token> parameter"
	ConsoleWriteError($errMsg & @LF)
	TrayTip($sTitle, $errMsg, 10, $TIP_ICONHAND)
	Sleep(10000)
	Exit (1)
EndIf
If (Not $updateIpv4) And (Not $updateIpv6) Then
	$errMsg = "Exiting (nothing to do): no IP version specified: use -4 and/or -6 parameter(s)"
	ConsoleWriteError($errMsg & @LF)
	TrayTip($sTitle, $errMsg, 10, $TIP_ICONHAND)
	Sleep(10000)
	Exit (1)
EndIf
If $daemon Then
	$periodically = "periodically "
Else
	$periodically = ""
EndIf
$defaultTip = "Set to " & $periodically & "update host record(s) for " & $host & ".dynv6.net"
TraySetToolTip($sTitle & " - " & $defaultTip)
TrayTip($sTitle, $defaultTip, 10, $TIP_ICONNONE)
; Set $repeat = True so update will run at least once
$repeat = True
$lastAttemptFailed = False
While $repeat
;~ 	$trayMsg = TrayGetMsg()
;~ 	Select
;~ 		Case $trayMsg = $mnuAbout
;~ 			TrayItemSetState($mnuAbout, $TRAY_UNCHECKED)
;~			_WinAPI_ShellAboutDlg($sTitle, $sTitle & " Version " & $sVersion, $sTitle & " Version " & $sVersion & " " & $sCopyright & @LF & $sMisc)
;~ 	EndSelect
	If $updateIpv4 Then
		$resultUpdateIpv4 = UpdateDynv6HostRecord($host, $token, 4)
		;ConsoleWriteError("Finished IPv4 update attempt" & @LF)
		If $resultUpdateIpv4 Then
			ConsoleWriteError("[" & NowIsoDate() & "_" & _NowTime(5) & "] Failed updating IPv4 host address" & @LF)
			ConsoleWriteError("  This could be caused by many things, including:" & @LF)
			ConsoleWriteError("  the dynv6.com service being down, irresponsive, or malfuctioning," & @LF)
			ConsoleWriteError("  no reachable Internet route (via IPv4) to the https://ipv4.dynv6.com service," & @LF)
			ConsoleWriteError("  a wrong or invalid value for <host>," & @LF)
			ConsoleWriteError("  or a wrong or invalid value for <token>." & @LF)
			TraySetIcon($iconFile)
			$lastAttemptFailed = True
			TrayTip($sTitle, "Updates records for " & $host & ".dynv6.net", 20, $TIP_ICONASTERISK)
		Else
			ConsoleWriteError("[" & NowIsoDate() & "_" & _NowTime(5) & "] Updated IPv4 host address" & @LF)
			TraySetIcon($iconFile)
			$lastAttemptFailed = False
			;TrayTip("$sTitle, "Updated host record(s) for " & $host & ".dynv6.net", 10, $TIP_ICONNONE)
		EndIf
	EndIf
	If $updateIpv6 Then
		$resultUpdateIpv6 = UpdateDynv6HostRecord($host, $token)
		;ConsoleWriteError("Finished IPv6 update attempt" & @LF)
		If $resultUpdateIpv6 Then
			ConsoleWriteError("[" & NowIsoDate() & "_" & _NowTime(5) & "] Failed updating IPv6 host address" & @LF)
			ConsoleWriteError("  This could be caused by many things, including:" & @LF)
			ConsoleWriteError("  the dynv6.com service being down,, irresponsive, or malfuctioning," & @LF)
			ConsoleWriteError("  no reachable Internet route (via IPv6) to the https://dynv6.com service," & @LF)
			ConsoleWriteError("  a wrong or invalid value for <host>," & @LF)
			ConsoleWriteError("  or a wrong or invalid value for <token>." & @LF)
			TraySetIcon($iconFile)
			$lastAttemptFailed = True
			TrayTip($sTitle, "Updated ipv6 for " & $host & ".dynv6.net", 20, $TIP_ICONASTERISK)
			$svar = Number("1000") * Number($daemon) ;
			Sleep($svar) ; Daemon=svar*1000 for milicseconds to seconds
		Else
			ConsoleWrite("[" & NowIsoDate() & "_" & _NowTime(5) & "] Updated IPv6 host address" & @LF)
			TraySetIcon($iconFile)
			$lastAttemptFailed = False
			;TrayTip($sTitle, "Updated host record(s) for " & $host & ".dynv6.net", 10, $TIP_ICONNONE)
		EndIf
	EndIf
WEnd
Func UpdateDynv6HostRecord($dynv6Host, $dynv6Token, $ipVersion = 6)
	; construct URL with payload for dynv6 update
	$dynv6Protocol = "https"
	$dynv6ServerBase = "dynv6.com/api/update"
	; hosts issued by dynv6.com are on the dynv6.net 2nd level domain!
	$dynv6HostSuffix = "dynv6.net" ; "dynv6.net" is the only valid value (for now)
	$dynv6HostFqdn = $dynv6Host & "." & $dynv6HostSuffix
	If $ipVersion = 4 Then
		$dynv6ServerPrefix = "ipv4."
		$dynv6IpString = "ipv4=auto"
	Else
		; no fancy errors for invalid $ipVersion, just assume 6
		;$dynv6ServerPrefix = "ipv6."
		$dynv6ServerPrefix = ""
		$dynv6IpString = "ipv6=auto"
	EndIf
	$dynv6Url = $dynv6Protocol & "://" & $dynv6ServerPrefix & $dynv6ServerBase
	;$dynv6Url = $dynv6Protocol & "://" & $dynv6ServerBase
	$dynv6Url &= "?" & "hostname=" & $dynv6HostFqdn ; TODO: URL Encoding
	$dynv6Url &= "&" & $dynv6IpString
	$dynv6Url &= "&" & "token=" & $dynv6Token ; TODO: URL Encoding
	;ConsoleWriteError("$dynv6Url=" & $dynv6Url & @LF)
	$dynv6UpdateResultBinary = InetRead($dynv6Url, $INET_FORCERELOAD)
	If Not @error Then
		$dynv6UpdateResultString = BinaryToString($dynv6UpdateResultBinary)
		;ConsoleWriteError("$dynv6UpdateResultBinary=" & $dynv6UpdateResultBinary & @LF)
		;ConsoleWriteError("$dynv6UpdateResultString=" & $dynv6UpdateResultString & @LF)
		If $dynv6UpdateResultString == ("host updated" & @LF) Then
			; this will actually trigger - "host updated\n" may be returned
			; with the HTTP status code 200
			;ConsoleWriteError("It Worked! - " & $dynv6UpdateResultString & @LF)
			Return 0
		ElseIf $dynv6UpdateResultString == ("invalid host" & @LF) Then
			; this will never happen - "invalid host\n" may be returned
			; but the HTTP status code returned will be 404 (Not Found)
			; resulting in an InetRead error instead
			;ConsoleWriteError("It Failed! - " & $dynv6UpdateResultString & @LF)
			Return 1
		ElseIf $dynv6UpdateResultString == ("invalid authentication_token" & @LF) Then
			; this will never happen - "invalid authentication_token\n" may be returned
			; but the HTTP status code returned will be 401 (Unauthorized)
			; resulting in an InetRead error instead
			;ConsoleWriteError("It Failed! - " & $dynv6UpdateResultString & @LF)
			Return 1
		Else
			; this might never happen - some unknown string may be returned
			; but the HTTP status code returned may be 4xx (Error)
			; resulting in an InetRead error instead
			;ConsoleWriteError("Wha??????! - " & $dynv6UpdateResultString & @LF)
			Return 1
		EndIf
	Else
		; an InetRead error may be returned for a bad URL,
		; any HTTP status code that is an error, or
		; any other reason that the client is unable to reach the server
		;ConsoleWriteError("InetRead Error! Bytes Downloaded: " & @extended & @LF)
		Return 1
	EndIf
EndFunc   ;==>UpdateDynv6HostRecord
Func NowIsoDate()
	$returnVal = @YEAR & "-" & @MON & "-" & @MDAY
	Return $returnVal
EndFunc   ;==>NowIsoDate
