[Setup]
AppName=wsjtx
AppVerName=wsjtx Version 1.0.0 r3461
AppCopyright=Copyright (C) 2001-2013 by Joe Taylor, K1JT
DefaultDirName=c:\wsjtx2
DefaultGroupName=wsjtx2

[Files]
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\wsjtx.exe";         DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\jt9.exe";           DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx\lib\jt9code.exe";           DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\rigctl.exe";        DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\kvasd.exe";         DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\wsjt.ico";          DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\afmhot.dat";        DestDir: "{app}";
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\blue.dat";          DestDir: "{app}";
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\CALL3.TXT";         DestDir: "{app}";  Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\QtSupport\*.dll";                      DestDir: "{app}";
Source: "c:\Users\joe\wsjt_k1jt\wsjtx\shortcuts.txt";             DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx\mouse_commands.txt";        DestDir: "{app}"
Source: "c:\Users\joe\wsjt\wsjtx\WSJT-X_Users_Guide.pdf";         DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx\WSJT-X_1.1_Quick_Start.pdf";    DestDir: "{app}"
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\save\Samples\130418_1742.wav";   DestDir: "{app}\save\Samples";
Source: "c:\Users\joe\wsjt_k1jt\wsjtx_install\save\Samples\130610_2343.wav";   DestDir: "{app}\save\Samples";

[Icons]
Name: "{group}\wsjtx2";        Filename: "{app}\wsjtx.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico
Name: "{userdesktop}\wsjtx2";  Filename: "{app}\wsjtx.exe";   WorkingDir: {app}; IconFilename: {app}\wsjt.ico

