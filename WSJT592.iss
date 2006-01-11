[Setup]
AppName=WSJT
AppVerName=WSJT Version 5.9.2 r77
AppCopyright=Copyright (C) 2001-2005 by Joe Taylor, K1JT
DefaultDirName={pf}\WSJT6
DefaultGroupName=WSJT6

[Files]
Source: "c:\k1jt\svn\wsjt\release-5.9.2\WSJT6.EXE";         DestDir: "{app}"
Source: "c:\k1jt\svn\wsjt\release-5.9.2\README_592.TXT";    DestDir: "{app}"
Source: "c:\k1jt\svn\wsjt\release-5.9.2\CALL3.TXT";         DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\release-5.9.2\wsjt.ico";          DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\release-5.9.2\TSKY.DAT";          DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\release-5.9.2\libsamplerate.dll"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "c:\k1jt\svn\wsjt\release-5.9.2\kvasd.exe";         DestDir: "{app}";
Source: "c:\k1jt\svn\wsjt\release-5.9.2\wsjtrc.win";        DestDir: "{app}";
Source: "c:\k1jt\svn\wsjt\release-5.9.2\Tutorial_592.txt";  DestDir: "{app}";
Source: "c:\k1jt\python\wsjt\rxwav\samples\W8WN_010809_110400.WAV";  DestDir: "{app}\RxWav\Samples\"; Flags: onlyifdoesntexist

[Icons]
Name: "{group}\WSJT6";        Filename: "{app}\WSJT6.EXE"; WorkingDir: {app}
Name: "{userdesktop}\WSJT6";  Filename: "{app}\WSJT6.EXE"; WorkingDir: {app}


