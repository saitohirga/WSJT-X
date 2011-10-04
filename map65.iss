[Setup]
AppName=MAP65
AppVerName=MAP65 Version 1.1 r24254
AppCopyright=Copyright (C) 2001-2011 by Joe Taylor, K1JT
DefaultDirName={pf}\MAP65
DefaultGroupName=MAP65

[Files]
Source: "c:\Users\joe\wsjt\map65\map65.exe";         DestDir: "{app}"
Source: "c:\Users\joe\wsjt\map65\CALL3.TXT";         DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\map65\wsjt.ico";          DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\map65\TSKY.DAT";          DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\Users\joe\wsjt\map65\KVASD_G95.EXE";     DestDir: "{app}";
Source: "c:\Users\joe\wsjt\map65\map65rc.win";       DestDir: "{app}";
Source: "c:\Users\joe\wsjt\map65\WSJT.LOG";          DestDir: "{app}";

[Icons]
Name: "{group}\MAP65";        Filename: "{app}\map65.exe"; WorkingDir: {app}
Name: "{userdesktop}\MAP65";  Filename: "{app}\map65.exe"; WorkingDir: {app}


