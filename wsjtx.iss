[Setup]
AppName=wsjtx
AppVerName=wsjtx Version 0.2 r2708
AppCopyright=Copyright (C) 2001-2012 by Joe Taylor, K1JT
DefaultDirName=c:\wsjtx
DefaultGroupName=wsjtx

[Files]
Source: "c:\Users\joe\wsjt\wsjtx_install\wsjtx.exe";         DestDir: "{app}"
Source: "c:\Users\joe\wsjt\wsjtx_install\wsjt.ico";          DestDir: "{app}"
Source: "c:\Users\joe\wsjt\wsjtx_install\afmhot.dat";        DestDir: "{app}";
Source: "c:\Users\joe\wsjt\wsjtx_install\blue.dat";          DestDir: "{app}";
Source: "c:\Users\joe\wsjt\wsjtx_install\CALL3.TXT";         DestDir: "{app}";
Source: "c:\Users\joe\wsjt\wsjtx\WSJT-X_Quick_Start_Guide.pdf";  DestDir: "{app}";
Source: "c:\Users\joe\wsjt\QtSupport\*.dll";                 DestDir: "{sys}";  Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\wsjtx_install\000000_0000.wav";   DestDir: "{app}\save";

[Icons]
Name: "{group}\wsjtx";        Filename: "{app}\wsjtx.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\wsjtx";  Filename: "{app}\wsjtx.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico

