[Setup]
AppName=MAP65
AppVerName=MAP65 Version 0.9 r1533
AppCopyright=Copyright (C) 2001-2009 by Joe Taylor, K1JT
DefaultDirName={pf}\MAP65
DefaultGroupName=MAP65

[Files]
Source: "c:\k1jt\svn\wsjt\map65\map65.exe";         DestDir: "{app}"
Source: "c:\k1jt\svn\wsjt\map65\CALL3.TXT";         DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\map65\wsjt.ico";          DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\map65\TSKY.DAT";          DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\map65\kvasd.exe";         DestDir: "{app}";
Source: "c:\k1jt\svn\wsjt\map65\map65rc.win";       DestDir: "{app}";

[Icons]
Name: "{group}\MAP65";        Filename: "{app}\map65.exe"; WorkingDir: {app}
Name: "{userdesktop}\MAP65";  Filename: "{app}\map65.exe"; WorkingDir: {app}


