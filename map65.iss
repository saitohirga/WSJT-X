[Setup]
AppName=MAP65
AppVerName=MAP65 Version 2.5 r4579
AppCopyright=Copyright (C) 2001-2014 by Joe Taylor, K1JT
DefaultDirName=c:\MAP65
DefaultGroupName=MAP65

[Files]
Source: "C:\JTSDK-QT\map65\install\Release\bin\*";             DestDir: "{app}"
Source: "C:\JTSDK-QT\map65\install\Release\bin\platforms\qwindows.dll";	DestDir: "{app}\platforms"
Source: "C:\JTSDK-QT\map65\install\Release\bin\save\Samples";	 DestDir: "{app}\save\Samples"; Flags: recursesubdirs createallsubdirs
Source: "C:\JTSDK-QT\src\map65\libm65\kvasd.exe";          DestDir: "{app}"
Source: "C:\JTSDK-QT\src\map65\resources\*";               DestDir: "{app}"; Flags: onlyifdoesntexist

[Icons]
Name: "{group}\MAP65";        Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\MAP65";  Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico

[Run]
Filename: "{app}\wisdom1.bat"; Description: "Optimize plans for FFTs (takes a few minutes)"; Flags: postinstall
Filename: "{app}\wisdom2.bat"; Description: "Patiently optimize plans for FFTs (up to one hour)"; Flags: postinstall unchecked
