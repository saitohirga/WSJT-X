[Setup]
AppName=MAP65
AppVerName=MAP65 Version 2.3.0 r631
AppCopyright=Copyright (C) 2001-2012 by Joe Taylor, K1JT
DefaultDirName=c:\MAP65
DefaultGroupName=MAP65

[Files]
Source: "c:\Users\joe\map65\install\m65.exe";           DestDir: "{app}"
Source: "c:\Users\joe\map65\install\map65.exe";         DestDir: "{app}"
Source: "c:\Users\joe\map65\install\wsjt.ico";          DestDir: "{app}"
Source: "c:\Users\joe\map65\install\kvasd.exe";         DestDir: "{app}"
Source: "c:\Users\joe\map65\install\CALL3.TXT";         DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\Users\joe\map65\install\fftwf-wisdom.exe";  DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\Users\joe\map65\install\wisdom1.bat";       DestDir: "{app}";
Source: "c:\Users\joe\map65\install\wisdom2.bat";       DestDir: "{app}";
Source: "c:\Users\joe\map65\install\afmhot.dat";        DestDir: "{app}";
Source: "c:\Users\joe\map65\install\blue.dat";          DestDir: "{app}";
Source: "c:\Users\joe\map65\install\qthid.exe";         DestDir: "{app}";

Source: "c:\Users\joe\map65\QtSupport\*.dll";           DestDir: "{sys}";  Flags: onlyifdoesntexist

Source: "c:\Users\joe\map65\install\save\dummy";        DestDir: "{app}\save";

[Icons]
Name: "{group}\MAP65";        Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\MAP65";  Filename: "{app}\map65.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico

[Run]
Filename: "{app}\wisdom1.bat"; Description: "Optimize plans for FFTs (takes a few minutes)"; Flags: postinstall
Filename: "{app}\wisdom2.bat"; Description: "Patiently optimize plans for FFTs (up to one hour)"; Flags: postinstall unchecked
