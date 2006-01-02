DFreq=0.0
Freq=0.0
PingTime=0.0
PingFile="current"
report="26"
rms=1.0
mode_change=0
showspecjt=0

#------------------------------------------------------ ftnstr
def ftnstr(x):
    y=""
    for i in range(len(x)):
        y=y+x[i]
    return y

#------------------------------------------------------ filetime
def filetime(t):
#    i=t.rfind(".")
    i=6
    t=t[:i][-6:]
    t=t[0:2]+":"+t[2:4]+":"+t[4:6]
    return t

