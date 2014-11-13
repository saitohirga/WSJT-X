[Setup]
AppName=MAP65
AppVerName=MAP65 Version 2.5 r4583
AppCopyright=Copyright (C) 2001-2014 by Joe Taylor, K1JT
DefaultDirName=C:\WSJT\MAP65
DefaultGroupName=WSJT\MAP65

[Files]
Source: "C:\JTSDK-QT\map65\install\Release\bin\*";						    DestDir: "{app}"; Excludes: kvasd.exe
Source: "C:\JTSDK-QT\map65\install\Release\bin\platforms\qwindows.dll";	DestDir: "{app}\platforms"
Source: "C:\JTSDK-QT\map65\install\Release\bin\save\Samples";			DestDir: "{app}\save\Samples"; Flags: recursesubdirs createallsubdirs
Source: "C:\JTSDK-QT\src\map65\resources\*";                      DestDir: "{app}"

[Icons]
Name: "{group}\MAP65";        Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\MAP65";  Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: {group}\MAP65 Uninstall; Filename: {uninstallexe}

[Run]
Filename: "{app}\wisdom1.bat"; Description: "Optimize plans for FFTs (takes a few minutes)"; Flags: postinstall
Filename: "{app}\wisdom2.bat"; Description: "Patiently optimize plans for FFTs (up to one hour)"; Flags: postinstall unchecked
Filename: "{app}\map65.exe"; Description: "Launch MAP65"; Flags: postinstall nowait unchecked
