[Setup]
AppName=MAP65
AppVerName=MAP65 Version 0.8 r4231
AppCopyright=Copyright (C) 2001-2013 by Joe Taylor, K1JT
DefaultDirName=C:\WSJT\MAP65
DefaultGroupName=WSJT\MAP65

[Files]
Source: "C:\JTSDK-QT\map65\install\Release\bin\*";						DestDir: "{app}"
Source: "C:\JTSDK-QT\map65\install\Release\bin\platforms\qwindows.dll";	DestDir: "{app}\platforms"
Source: "C:\JTSDK-QT\map65\install\Release\bin\save\Samples";			DestDir: "{app}\save\Samples"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MAP65";        Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\MAP65";  Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: {group}\MAP65 Uninstall; Filename: {uninstallexe}

[Run]
Filename: "{app}\map65.exe"; Description: "Launch MAP65"; Flags: postinstall nowait unchecked
; The Following will require adding several files to the MAP65 repository and
; have been commented out for the time being.
; Filename: "{app}\wisdom1.bat"; Description: "Optimize plans for FFTs (takes a few minutes)"; Flags: postinstall
; Filename: "{app}\wisdom2.bat"; Description: "Patiently optimize plans for FFTs (up to one hour)"; Flags: postinstall unchecked
