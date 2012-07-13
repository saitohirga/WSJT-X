[Setup]
AppName=JTMS3
AppVerName=JTMS3 Version 0.2 r2516
AppCopyright=Copyright (C) 2001-2012 by Joe Taylor, K1JT
DefaultDirName=c:\JTMS3
DefaultGroupName=JTMS3

[Files]
Source: "c:\Users\joe\wsjt\jtms3_install\jtms3.exe";         DestDir: "{app}"
Source: "c:\Users\joe\wsjt\jtms3_install\wsjt.ico";          DestDir: "{app}"
Source: "c:\Users\joe\wsjt\jtms3_install\CALL3.TXT";         DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\jtms3_install\afmhot.dat";        DestDir: "{app}";
Source: "c:\Users\joe\wsjt\jtms3_install\blue.dat";          DestDir: "{app}";
Source: "c:\Users\joe\wsjt\QtSupport\*.dll";                 DestDir: "{sys}";  Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\jtms3_install\save\dummy";        DestDir: "{app}\save";

[Icons]
Name: "{group}\JTMS3";        Filename: "{app}\jtms3.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\JTMS3";  Filename: "{app}\jtms3.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico

