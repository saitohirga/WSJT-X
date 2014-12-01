; For Use With JTSDK v2.0.0
#define MyAppName "MAP65"
#define MyAppVersion "2.5"
#define MyAppPublisher "Greg Beam, KI7MT"
#define MyAppCopyright "Copyright (C) 2001-2014 by Joe Taylor, K1JT"
#define MyAppURL "http://physics.princeton.edu/pulsar/k1jt/map65.html"
#define WsjtGroupURL "https://groups.yahoo.com/neo/groups/wsjtgroup/info"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DisableReadyPage=yes
DefaultDirName=C:\WSJT\MAP65-{#MyAppVersion}
DisableDirPage=yes
DefaultGroupName=WSJT
DisableProgramGroupPage=yes
LicenseFile=C:\JTSDK\common-licenses\GPL-3
OutputDir=C:\JTSDK\wspr\package
OutputBaseFilename={#MyAppName}-{#MyAppVersion}-Win32
SetupIconFile=C:\JTSDK\icons\wsjt.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "c:\JTSDK\map65\install\Release\bin\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\JTSDK\src\map65\resources\*"; DestDir: "{app}"; Excludes: kvasd.exe

[Icons]
Name: "{group}\{#MyAppName}\Documentation\{cm:ProgramOnTheWeb,{#MyAppName}}"; Filename: "{#MyAppURL}"
Name: "{group}\{#MyAppName}\Resources\{cm:ProgramOnTheWeb,WSJT Group}"; Filename: "{#WsjtGroupURL}"
Name: "{group}\{#MyAppName}\Tools\Wisdom-1"; Filename: "{app}\wisdom1.bat"; WorkingDir: {app}; IconFileName: "{app}\wsjt.ico"
Name: "{group}\{#MyAppName}\Tools\Wisdom-2"; Filename: "{app}\wisdom2.bat"; WorkingDir: {app}; IconFileName: "{app}\wsjt.ico"
Name: "{group}\{#MyAppName}\Uninstall\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; Comment: "Uninstall WSPR";
Name: "{group}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\map65.exe"; WorkingDir: {app}; IconFileName: "{app}\wsjt.ico"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\map65.exe";    WorkingDir: {app}; IconFileName: "{app}\wsjt.ico"

[Run]
Filename: "{app}\wisdom1.bat"; Description: "Optimize plans for FFTs (takes a few minutes)"; Flags: postinstall
Filename: "{app}\wisdom2.bat"; Description: "Patiently optimize plans for FFTs (up to one hour)"; Flags: postinstall unchecked
Filename: "{app}\map65.exe"; Description: "Launch MAP65"; Flags: postinstall nowait unchecked
