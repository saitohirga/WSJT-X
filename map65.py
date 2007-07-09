#--------------------------------------------------------------------- MAP65
# $Date$ $Revision$
#
from Tkinter import *
from tkFileDialog import *
import Pmw
from tkMessageBox import showwarning
import g,os,time
import Audio
from math import log10
from Numeric import zeros
import dircache
import Image,ImageTk  #, ImageDraw
from palettes import colormapblue, colormapgray0, colormapHot, \
     colormapAFMHot, colormapgray1, colormapLinrad, Colormap2Palette
from types import *
import array

root = Tk()
Version="0.7 r" + "$Rev$"[6:-1]
print "******************************************************************"
print "MAP65 Version " + Version + ", by K1JT"
print "Revision date: " + \
      "$Date$"[7:-1]
print "Run date:   " + time.asctime(time.gmtime()) + " UTC"

#See if we are running in Windows
g.Win32=0
if sys.platform=="win32":
    g.Win32=1
    try:
        root.option_readfile('map65rc.win')
    except:
        pass
else:
    try:
        root.option_readfile('map65rc')
    except:
        pass
root_geom=""


#------------------------------------------------------ Global variables
appdir=os.getcwd()
g.appdir=appdir
isync=1
isync_save=0
iclip=0
itol=5                                       #Default tol=500 Hz
ntol=(10,20,50,100,200,500,1000)             #List of available tolerances
idsec=0
lauto=0
altmsg=0
bm_geom=""
bm2_geom=""
cmap0="Linrad"
fileopened=""
font1='Helvetica'
hiscall=""
hisgrid=""
isec0=-99
k2txb=IntVar()
kb8rq=IntVar()
loopall=0
mode=StringVar()
mode.set("")
mrudir=os.getcwd()
nafc=IntVar()
naz=0
ndepth=IntVar()
nel=0
nblank=IntVar()
ncall=0
ndmiles=0
ndkm=0
ndebug=IntVar()
ndebug2=IntVar()
ndebug.set(0)
ndebug2.set(0)
neme=IntVar()
nfreeze=IntVar()
nopen=0
nosh441=IntVar()
noshjt65=IntVar()
setseq=IntVar()
tx6alt=""
txsnrdb=99.
TxFirst=IntVar()
green=zeros(500,'f')
im=Image.new('P',(500,120))
im.putpalette(Colormap2Palette(colormapLinrad),"RGB")
pim=ImageTk.PhotoImage(im)
balloon=Pmw.Balloon(root)

g.freeze_decode=0
g.mode=""
g.ndecphase=0
g.ndevin=IntVar()
g.ndevout=IntVar()
g.DevinName=StringVar()
g.DevoutName=StringVar()

g.fc=["" for i in range(200)]

#------------------------------------------------------ showspecjt
def showspecjt(event=NONE):
    if g.showspecjt==0: g.showspecjt=1

#------------------------------------------------------ restart
def restart():
    Audio.gcom2.nrestart=1
    Audio.gcom2.mantx=1

#------------------------------------------------------ restart2
def restart2():
    Audio.gcom2.nrestart=1

#------------------------------------------------------ toggle_freeze
def toggle_freeze(event=NONE):
    nfreeze.set(1-nfreeze.get())

#------------------------------------------------------ toggle_zap
def toggle_zap(event=NONE):
    nzap.set(1-nzap.get())

#------------------------------------------------------ btx (1-6)
def btx1(event=NONE):
    ntx.set(1)
    Audio.gcom2.txmsg=(tx1.get()+'                            ')[:28]
    Audio.gcom2.ntxreq=1
    restart()
def btx2(event=NONE):
    ntx.set(2)
    Audio.gcom2.txmsg=(tx2.get()+'                            ')[:28]
    Audio.gcom2.ntxreq=2
    restart()
def btx3(event=NONE):
    ntx.set(3)
    Audio.gcom2.txmsg=(tx3.get()+'                            ')[:28]
    Audio.gcom2.ntxreq=3
    restart()
def btx4(event=NONE):
    ntx.set(4)
    Audio.gcom2.txmsg=(tx4.get()+'                            ')[:28]
    Audio.gcom2.ntxreq=4
    restart()
def btx5(event=NONE):
    ntx.set(5)
    Audio.gcom2.txmsg=(tx5.get()+'                            ')[:28]
    Audio.gcom2.ntxreq=5
    restart()
def btx6(event=NONE):
    ntx.set(6)
    Audio.gcom2.txmsg=(tx6.get()+'                            ')[:28]
    Audio.gcom2.ntxreq=6
    restart()

#------------------------------------------------------ quit
def quit():
    root.destroy()

#------------------------------------------------------ testmsgs
def testmsgs():
    for m in (tx1, tx2, tx3, tx4, tx5, tx6):
        m.delete(0,99)
    tx1.insert(0,"@A")
    tx2.insert(0,"@B")
    tx3.insert(0,"@C")
    tx4.insert(0,"@D")
    tx5.insert(0,"@1000")
    tx6.insert(0,"@2000")

#------------------------------------------------------ delta_phi
def delta_phi():
    global lauto
    Audio.gcom2.monitoring=0
    lauto=0
    Audio.gcom2.lauto=0
    Audio.gcom2.ndphi=1
    decode()

#------------------------------------------------------ 
def messages(event=NONE):
    global Version,bm,bm_geom,msgtext
    bm=Toplevel(root)
    bm.title("Messages")
    bm.geometry(bm_geom)
    if g.Win32: bm.iconbitmap("wsjt.ico")
    iframe_bm1 = Frame(bm, bd=1, relief=SUNKEN)
    msgtext=Text(iframe_bm1, height=35, width=41, bg="Navy", fg="yellow")
    msgtext.bind('<Double-Button-1>',dbl_click_msgtext)
    msgtext.pack(side=LEFT, fill=X, padx=1, pady=3)
    bmsb = Scrollbar(iframe_bm1, orient=VERTICAL, command=msgtext.yview)
    bmsb.pack(side=RIGHT, fill=Y)
    msgtext.configure(yscrollcommand=bmsb.set)
    msgtext.tag_configure('age0',foreground='red')
    msgtext.tag_configure('age1',foreground='yellow')
    msgtext.tag_configure('age2',foreground='gray75')
    msgtext.tag_configure('age3',foreground='gray50')
    iframe_bm1.pack(expand=1, fill=X, padx=4)

#------------------------------------------------------ bandmap
def bandmap(event=NONE):
    global Version,bm2,bm2_geom,bmtext
    bm2=Toplevel(root)
    bm2.title("Band Map")
    bm2.geometry(bm2_geom)
    if g.Win32: bm2.iconbitmap("wsjt.ico")
    iframe_bm2 = Frame(bm2, bd=1, relief=SUNKEN)
    bmtext=Text(iframe_bm2, height=24, width=36, bg="Navy", fg="yellow")
    bmtext.bind('<Double-Button-1>',dbl_click_bmtext)
    bmtext.pack(side=LEFT, fill=X, padx=1, pady=3)
    bmtext.tag_configure('age0',foreground='red')
    bmtext.tag_configure('age1',foreground='yellow')
    bmtext.tag_configure('age2',foreground='gray75')
    bmtext.tag_configure('age3',foreground='gray50')
    iframe_bm2.pack(expand=1, fill=X, padx=4,pady=5)

#------------------------------------------------------ logqso
def logqso(event=NONE):
    t=time.strftime("%Y-%b-%d,%H:%M",time.gmtime())
    t=t+","+hiscall+","+hisgrid+","+str(g.nfreq)+","+g.mode+"\n"
    t2="Please confirm making the following entry in MAP65.LOG:\n\n" + t
    msg=Pmw.MessageDialog(root,buttons=('Yes','No'),message_text=t2)
    msg.geometry(msgpos())
    if g.Win32: msg.iconbitmap("wsjt.ico")
    msg.focus_set()
    result=msg.activate()
    if result == 'Yes':
        f=open(appdir+'/WSJT.LOG','a')
        f.write(t)
        f.close()
    
#------------------------------------------------------ monitor
def monitor(event=NONE):
    bmonitor.configure(bg='green')
    Audio.gcom2.monitoring=1

#------------------------------------------------------ stopmon
def stopmon(event=NONE):
    global loopall
    loopall=0
    bmonitor.configure(bg='gray85')
    Audio.gcom2.monitoring=0

#------------------------------------------------------ dbl_click_text
def dbl_click_text(event):
    t=text.get('1.0',END)           #Entire contents of text box
    t1=text.get('1.0',CURRENT)      #Contents from start to cursor
    dbl_click_call(t,t1,event)
#------------------------------------------------------ dbl_click_msgtext
def dbl_click_msgtext(event):
    t=msgtext.get('1.0',END)           #Entire contents of text box
    t1=msgtext.get('1.0',CURRENT)      #Contents from start to cursor
    dbl_click_call(t,t1,event)
#------------------------------------------------------ dbl_click_bmtext
def dbl_click_bmtext(event):
    t=bmtext.get('1.0',END)           #Entire contents of text box
    t1=bmtext.get('1.0',CURRENT)      #Contents from start to cursor
    dbl_click_call(t,t1,event)
#------------------------------------------------------ dbl_click_ave
def dbl_click_ave(event):
    t=avetext.get('1.0',END)        #Entire contents of text box
    t1=avetext.get('1.0',CURRENT)   #Contents from start to cursor
    dbl_click_call(t,t1,event)
#------------------------------------------------------ dbl_click_call
def dbl_click_call(t,t1,event):
    global hiscall
    i=len(t1)                       #Length to mouse pointer
    i1=t1.rfind(' ')+1              #index of preceding space
    i2=i1+t[i1:].find(' ')          #index of next space
    hiscall=t[i1:i2]                #selected word, assumed as callsign
    ToRadio.delete(0,END)
    ToRadio.insert(0,hiscall)
    i3=t1.rfind('\n')+1             #start of selected line
    if i>6 and i2>i1:
        try:
            nsec=3600*int(t1[i3+13:i3+15]) + 60*int(t1[i3+15:i3+17])
        except:
            nsec=0
        if setseq.get(): TxFirst.set((nsec/Audio.gcom1.trperiod)%2)
        lookup()
        GenStdMsgs()
        i3=t[:i1].strip().rfind(' ')+1
        if t[i3:i1].strip() == 'CQ':
            ntx.set(1)
        else:
            ntx.set(2)
        if event.num==3 and not lauto: toggleauto()

def textkey(event=NONE):
    text.configure(state=DISABLED)
def avetextkey(event=NONE):
    avetext.configure(state=DISABLED)

#------------------------------------------------------ decode
def decode(event=NONE):
    if Audio.gcom2.ndecoding==0:        #If already busy, ignore request
        Audio.gcom2.nagain=1
        n=1
        Audio.gcom2.mousebutton=0
        if Audio.gcom2.ndecoding0==4: n=4
        Audio.gcom2.ndecoding=n         #Standard decode, full file (d2a)

#------------------------------------------------------ decode_include
def decode_include(event=NONE):
    global isync,isync_save
    isync_save=isync
    isync=-99
    Audio.gcom2.minsigdb=-99
    decode()

#------------------------------------------------------ decode_exclude
def decode_exclude(event=NONE):
    global isync,isync_save
    isync_save=isync
    isync=99
    Audio.gcom2.minsigdb=99
    decode()

#------------------------------------------------------ openfile
def openfile(event=NONE):
    global mrudir,fileopened,nopen
    nopen=1                         #Work-around for "click feedthrough" bug
    try:
        os.chdir(mrudir)
    except:
        pass
    fname=askopenfilename(filetypes=[("Linrad timf2 files","*.tf2 *.TF2")])
    if fname:
        Audio.getfile(fname,len(fname))
        if Audio.gcom2.ierr: print 'Error ',Audio.gcom2.ierr, \
           'when trying to read file',fname
        mrudir=os.path.dirname(fname)
        fileopened=os.path.basename(fname)
    os.chdir(appdir)
 
#------------------------------------------------------ opennext
def opennext(event=NONE):
    global ncall,fileopened,loopall,mrudir
    if fileopened=="" and ncall==0:
        openfile()
        ncall=1
    else:
# Make a list of *.tf2 files in mrudir
        la=os.listdir(mrudir)
        la.sort()
        lb=[]
        for i in range(len(la)):
            j=la[i].find(".tf2") + la[i].find(".TF2")
            if j>0: lb.append(la[i])
        for i in range(len(lb)):
            if lb[i]==fileopened:
                break
        if i<len(lb)-1:
            fname=mrudir+"/"+lb[i+1]
#            if not lauto: stopmon()
            Audio.getfile(fname,len(fname))
            if Audio.gcom2.ierr: print 'Error ',Audio.gcom2.ierr, \
               'when trying to read file',fname
            mrudir=os.path.dirname(fname)
            fileopened=os.path.basename(fname)
        else:
            t="No more files to process."
            msg=Pmw.MessageDialog(root,buttons=('OK',),message_text=t)
            msg.geometry(msgpos())
            if g.Win32: msg.iconbitmap("wsjt.ico")
            msg.focus_set()
            ncall=0
            loopall=0

#------------------------------------------------------ decodeall
def decodeall(event=NONE):
    global loopall
    loopall=1
    opennext()

#------------------------------------------------------ astro1
def astro1(event=NONE):
    astro.astro2(g.astro_geom0)

#------------------------------------------------------ options1
def options1(event=NONE):
    options.options2(root_geom[root_geom.index("+"):])

#------------------------------------------------------ txmute
def txmute(event=NONE):
    Audio.gcom1.mute=1-Audio.gcom1.mute
    if Audio.gcom1.mute:
        lab7.configure(bg='red',fg='black')
    else:
        lab7.configure(bg='gray85',fg='gray85')

#------------------------------------------------------ MsgBox
def MsgBox(t):
    msg=Pmw.MessageDialog(root,buttons=('OK',),message_text=t)
    result=msg.activate()
    msg.focus_set()

#------------------------------------------------------ txstop
def txstop(event=NONE):
    if lauto: toggleauto()
    Audio.gcom1.txok=0
    Audio.gcom2.mantx=0
#    specjt.pal_gray0()      ????
    
#------------------------------------------------------ lookup
def lookup(event=NONE):
    global hiscall,hisgrid
    hiscall=ToRadio.get().upper().strip()
    ToRadio.delete(0,END)
    ToRadio.insert(0,hiscall)
    s=whois(hiscall)
    balloon.bind(ToRadio,s[:-1])
    hisgrid=""
    if s:
        i1=s.find(',')
        i2=s.find(',',i1+1)
        hisgrid=s[i1+1:i2]
        hisgrid=hisgrid[:2].upper()+hisgrid[2:4]+hisgrid[4:6].lower()
    if len(hisgrid)==4: hisgrid=hisgrid+"mm"
    if len(hisgrid)==5: hisgrid=hisgrid+"m"
    HisGrid.delete(0,99)
    HisGrid.insert(0,hisgrid)

def lookup_gen(event):
    lookup()
    GenStdMsgs()

#-------------------------------------------------------- addtodb
def addtodb():
    global hiscall
    if HisGrid.get()=="":
        MsgBox("Please enter a valid grid locator.")
    else:
        modified=0
        hiscall=ToRadio.get().upper().strip()
        hisgrid=HisGrid.get().strip()
        hc=hiscall
        NewEntry=hc + "," + hisgrid
        msg=Pmw.MessageDialog(root,buttons=('Yes','No'),
            message_text="Is this station known to be active on EME?")
        result=msg.activate()
        msg.focus_set()
        if result=="Yes":
            NewEntry=NewEntry + ",EME,,"
        else:
            NewEntry=NewEntry + ",,,"
        try:
            f=open(appdir+'/CALL3.TXT','r')
            s=f.readlines()
        except:
            print 'Error opening CALL3.TXT'
            s=""
        f.close()
        hc2=""
        stmp=[]
        for i in range(len(s)):
            hc1=hc2
            if s[i][:2]=="//":
                stmp.append(s[i])
            else:
                i1=s[i].find(",")
                hc2=s[i][:i1]
                if hc>hc1 and hc<hc2:
                    stmp.append(NewEntry+"\n")
                    modified=1
                elif hc==hc2:
                    t=s[i] + "\n\n is already in CALL3.TXT\nDo you wish to replace this entry?"
                    msg=Pmw.MessageDialog(root,buttons=('Yes','No'),
                        message_text=t)
                    result=msg.activate()
                    msg.focus_set()
                    if result=="Yes":
                        i1=s[i].find(",")
                        i2=s[i].find(",",i1+1)
                        i3=s[i].find(",",i2+1)
                        i4=len(NewEntry)
                        s[i]=NewEntry[:i4-1] + s[i][i3+1:]
                        modified=1
                stmp.append(s[i])
        if hc>hc1 and modified==0:
            stmp.append(NewEntry+"\n")
        try:
            f=open(appdir+'/CALL3.TMP','w')
            f.writelines(stmp)
            f.close()
        except:
            print 'Error in opening or writing to CALL3.TMP'

        if modified:
            if os.path.exists("CALL3.OLD"): os.remove("CALL3.OLD")
            os.rename("CALL3.TXT","CALL3.OLD")
            os.rename("CALL3.TMP","CALL3.TXT")

#-------------------------------------------------------- clrToRadio
def clrToRadio(event):
    ToRadio.delete(0,END)
    HisGrid.delete(0,99)
    ToRadio.focus_set()
    if kb8rq.get():
        ntx.set(6)
        nfreeze.set(0)

#------------------------------------------------------ whois
def whois(hiscall):
    whodat=""
    try:
        f=open(appdir+'/CALL3.TXT','r')
        s=f.readlines()
        f.close()
    except:
        print 'Error when searching CALL3.TXT, or no such file present'
        s=""
    for i in range(len(s)):
        if s[i][:2] != '//':
            i1=s[i].find(',')
            if s[i][:i1] == hiscall:
                return s[i]
    return ""

#------------------------------------------------------ cleartext
def cleartext():
    f=open(appdir+'/decoded.txt',mode='w')
    f.truncate(0)                           #Delete contents of decoded.txt
    f.close()
    f=open(appdir+'/decoded.ave',mode='w')
    f.truncate(0)                           #Delete contents of decoded.ave
    f.close()

#------------------------------------------------------ ModeJT65
def ModeJT65():
    global isync,itol
    cleartext()
    Audio.gcom1.trperiod=60
    iframe4b.pack(after=iframe4,expand=1, fill=X, padx=4)
    bclravg.configure(state=NORMAL)
    binclude.configure(state=NORMAL)
    bexclude.configure(state=NORMAL)
    itol=4
    inctol()
    nfreeze.set(0)
    ntx.set(1)
    GenStdMsgs()
    erase()

#------------------------------------------------------ ModeJT65A
def ModeJT65A(event=NONE):
    if g.mode != "JT65A":
        if lauto: toggleauto()
        mode.set("JT65A")
        ModeJT65()

#------------------------------------------------------ ModeJT65B
def ModeJT65B(event=NONE):
    if g.mode != "JT65B":
        if lauto: toggleauto()
        mode.set("JT65B")
        ModeJT65()

#------------------------------------------------------ ModeJT65C
def ModeJT65C(event=NONE):
    if g.mode != "JT65C":
        if lauto: toggleauto()
        mode.set("JT65C")
        ModeJT65()

#------------------------------------------------------ msgpos
def msgpos():
    g=root_geom[root_geom.index("+"):]
    t=g[1:]
    x=int(t[:t.index("+")])          # + 70
    y=int(t[t.index("+")+1:])        # + 70
    return "+%d+%d" % (x,y)    

#------------------------------------------------------ about
def about(event=NONE):
    global Version
    about=Toplevel(root)
    about.geometry(msgpos())
    if g.Win32: about.iconbitmap("wsjt.ico")
    t="MAP65 Version " + Version + ", by K1JT"
    Label(about,text=t,font=(font1,16)).pack(padx=20,pady=5)
    t="""
MAP65 is a weak signal communications program designed primarily
for the Earth-Moon-Earth (EME) propagation path.

Copyright (c) 2001-2007 by Joseph H. Taylor, Jr., K1JT, with
contributions from additional authors.  MAP65 is Open Source 
software, licensed under the GNU General Public License (GPL).
Source code and programming information may be found at 
http://developer.berlios.de/projects/wsjt/.
"""
    Label(about,text=t,justify=LEFT).pack(padx=20)
    t="Revision date: " + \
      "$Date$"[7:-1]
    Label(about,text=t,justify=LEFT).pack(padx=20)
    about.focus_set()

#------------------------------------------------------ shortcuts
def shortcuts(event=NONE):
    scwid=Toplevel(root)
    scwid.geometry(msgpos())
    if g.Win32: scwid.iconbitmap("wsjt.ico")
    t="""
F1	List keyboard shortcuts
Shift+F1	List special mouse commands
Ctrl+F1	About MAP65
F2	Options
F3	Tx Mute
F4	Clear "To Radio"
F5	What message to send?
F6	Open next file in directory
Shift+F6	Decode all wave files in directory
F8	Set JT65A mode
Shift+F8	Set JT65B mode
Ctrl+F8	Set JT65C mode
F10	Show Waterfall
Shift+F10   Show astronomical data
F11	Decrease DF
F12	Increase DF
Shift+F11   Decrease QSO Frequency
Shift+F12   Increase QSO Frequency
Alt+1 to Alt+6	Tx1 to Tx6
Alt+A	Toggle Auto On/Off
Alt+D	Decode
Alt+E	Erase
Alt+G	Generate Standard Messages
Ctrl+G	Generate Alternate JT65 Messages
Alt+I	Include
Alt+L	Lookup
Ctrl+L	Lookup, then Generate Standard Messages
Alt+M	Monitor
Alt+O	Tx Stop
Alt+Q	Log QSO
Alt+S	Stop Monitoring or Decoding
Alt+X	Exclude
"""
    Label(scwid,text=t,justify=LEFT).pack(padx=20)
    scwid.focus_set()

#------------------------------------------------------ mouse_commands
def mouse_commands(event=NONE):
    scwid=Toplevel(root)
    scwid.geometry(msgpos())
    if g.Win32: scwid.iconbitmap("wsjt.ico")
    t="""
Click on          Action
--------------------------------------------------------
Waterfall (upper)   Click to set QSO frequency; double-click to set
                               QSO frequency and Decode

Waterfall (lower)   Click to set target DF; double-click to set
                               target DF and Decode

Main screen,          Double-click puts callsign in Tx messages
text area
"""
    Label(scwid,text=t,justify=LEFT).pack(padx=20)
    scwid.focus_set()

#------------------------------------------------------ what2send
def what2send(event=NONE):
    screenf5=Toplevel(root)
    screenf5.geometry(root_geom[root_geom.index("+"):])
    if g.Win32: screenf5.iconbitmap("wsjt.ico")
    t="""
To optimize your chances of completing a valid JT65 QSO, use
the following standard procedures and *do not* exchange pertinent
information by other means (e.g., internet, telephone, ...) while
the QSO is in progress!

If you have received
    ... less than both calls, send both calls and your grid locator.
    ... both calls, send both calls, your grid locator, and OOO.
    ... both calls and OOO, send RO.
    ... RO, send RRR.
    ... RRR, the QSO is complete.  However, the other station may not
know this, so it is conventional to send 73 to signify that you are done.

(Sending grid locators is conventional in JT65, but numerical signal
reports may be substituted.)
"""
    Label(screenf5,text=t,justify=LEFT).pack(padx=20)
    screenf5.focus_set()

#------------------------------------------------------ prefixes
def prefixes(event=NONE):
    pfx=Toplevel(root)
    pfx.geometry(msgpos())
    if g.Win32: pfx.iconbitmap("wsjt.ico")
    f=open(appdir+'/prefixes.txt','r')
    s=f.readlines()
    t2=""
    for i in range(4):
        t2=t2+s[i]
    t=""
    for i in range(len(s)-4):
        t=t+s[i+4]
    t=t.split()
    t.sort()
    t1=""
    n=0
    for i in range(len(t)):
        t1=t1+t[i]+"  "
        n=n+len(t[i])+2
        if n>60:
            t1=t1+"\n"
            n=0
    t1=t1+"\n"
    if options.addpfx.get().lstrip():
        t1=t1+"\nOptional prefix:  "+(options.addpfx.get().lstrip()+'    ')[:8]
    t2=t2+"\n"+t1
    Label(pfx,text=t2,justify=LEFT).pack(padx=20)
    pfx.focus_set()

#------------------------------------------------------ azdist
def azdist():
    if len(HisGrid.get().strip())<4:
        labAz.configure(text="")
        labDist.configure(text="")
    else:
        labAz.configure(text="Az: %d" % (naz,))
    if options.mileskm.get()==0:
        labDist.configure(text=str(ndmiles)+" mi")
    else:
        labDist.configure(text=str(int(1.609344*ndmiles))+" km")
    
#------------------------------------------------------ inctol
def inctol(event=NONE):
    global itol
    maxitol=6
    if itol<maxitol: itol=itol+1
    ltol.configure(text='Tol    '+str(ntol[itol]))

#------------------------------------------------------ dectol
def dectol(event):
    global itol
    if itol>0 : itol=itol-1
    ltol.configure(text='Tol    '+str(ntol[itol]))

#------------------------------------------------------ incdsec
def incdsec(event):
    global idsec
    idsec=idsec+5
    bg='red'
    if idsec==0: bg='white'
    ldsec.configure(text='Dsec  '+str(0.1*idsec),bg=bg)
    Audio.gcom1.ndsec=idsec

#------------------------------------------------------ decdsec
def decdsec(event):
    global idsec
    idsec=idsec-5
    bg='red'
    if idsec==0: bg='white'
    ldsec.configure(text='Dsec  '+str(0.1*idsec),bg=bg)
    Audio.gcom1.ndsec=idsec

#------------------------------------------------------ erase
def erase(event=NONE):
    text.configure(state=NORMAL)
    text.delete('1.0',END)
    text.configure(state=DISABLED)
    avetext.configure(state=NORMAL)
    avetext.delete('1.0',END)
    avetext.configure(state=DISABLED)
    Audio.gcom2.decodedfile="                        "
#------------------------------------------------------ clear_avg
def clear_avg(event=NONE):
    avetext.configure(state=NORMAL)
    avetext.delete('1.0',END)
    avetext.configure(state=DISABLED)
    f=open(appdir+'/decoded.ave',mode='w')
    f.truncate(0)                           #Delete contents of decoded.ave
    f.close()
    Audio.gcom2.nclearave=1

#------------------------------------------------------ delwav
def delwav():
    t="Are you sure you want to delete\nall *.WAV files in the RxWav directory?"
    msg=Pmw.MessageDialog(root,buttons=('Yes','No'),message_text=t)
    msg.geometry(msgpos())
    if g.Win32: msg.iconbitmap("wsjt.ico")
    msg.focus_set()
    result=msg.activate()
    if result == 'Yes':
# Make a list of *.wav files in RxWav
        la=dircache.listdir(appdir+'/RxWav')
        lb=[]
        for i in range(len(la)):
            j=la[i].find(".wav") + la[i].find(".WAV")
            if j>0: lb.append(la[i])
# Now delete them all.
        for i in range(len(lb)):
            fname=appdir+'/RxWav/'+lb[i]
            os.remove(fname)

#------------------------------------------------------ del_all
def del_all():
    Audio.gcom1.ns0=-999999

#------------------------------------------------------ clr_all
def clr_all():
    Audio.gcom2.nrw26=1                 #Request rewind of tmp26.txt
    msgtext.delete('1.0',END)
    bmtext.delete('1.0',END)

#------------------------------------------------------ toggleauto
def toggleauto(event=NONE):
    global lauto
    lauto=1-lauto
    Audio.gcom2.lauto=lauto
    if lauto:
        monitor()
    else:
        Audio.gcom1.txok=0
        Audio.gcom2.mantx=0
    if lauto==0: auto.configure(text='Auto is OFF',bg='gray85',relief=RAISED)
    if lauto==1: auto.configure(text='Auto is ON',bg='red',relief=SOLID)
    
#----------------------------------------------------- dtdf_change
# Readout of graphical cursor location
def dtdf_change(event):
    if event.y<40 and Audio.gcom2.nspecial==0:
        lab1.configure(text='Time (s)',bg="#33FFFF")   #light blue
        t="%.1f" % (12.0*event.x/500.0-2.0,)
        lab6.configure(text=t,bg="#33FFFF")
    elif (event.y>=40 and event.y<95) or \
             (event.y<95 and Audio.gcom2.nspecial>0):
        lab1.configure(text='DF (Hz)',bg='red')
        idf=Audio.gcom2.idf
        t="%d" % int(idf+1200.0*event.x/500.0-600.0,)
        lab6.configure(text=t,bg="red")
    else:
        lab1.configure(text='Time (s)',bg='green')
        t="%.1f" % (53.0*event.x/500.0,)
        lab6.configure(text=t,bg="green")

#---------------------------------------------------- mouse_click_g1
def mouse_click_g1(event):
    global nopen
    if not nopen:
        Audio.gcom2.mousedf=int(Audio.gcom2.idf+(event.x-250)*2.4)
    nopen=0

#------------------------------------------------------ double-click_g1
def double_click_g1(event):
    if Audio.gcom2.ndecoding==0:
        g.freeze_decode=1
    
#------------------------------------------------------ mouse_up_g1
def mouse_up_g1(event):
# This is a fix for certain mouse-clicks
    pass

#------------------------------------------------------ right_arrow
def right_arrow(event=NONE):
    n=5*int(Audio.gcom2.mousedf/5)
    if n>0: n=n+5
    if n==Audio.gcom2.mousedf: n=n+5
    Audio.gcom2.mousedf=n
    
#------------------------------------------------------ left_arrow
def left_arrow(event=NONE):
    n=5*int(Audio.gcom2.mousedf/5)
    if n<0: n=n-5
    if n==Audio.gcom2.mousedf: n=n-5
    Audio.gcom2.mousedf=n

#------------------------------------------------------ inc_fqso
def inc_fqso(event=NONE):
    Audio.gcom2.mousefqso=Audio.gcom2.mousefqso + 1

#------------------------------------------------------ dec_fqso
def dec_fqso(event=NONE):
    Audio.gcom2.mousefqso=Audio.gcom2.mousefqso - 1
    
#------------------------------------------------------ GenStdMsgs
def GenStdMsgs(event=NONE):
    global altmsg
    t=ToRadio.get().upper().strip()
    ToRadio.delete(0,99)
    ToRadio.insert(0,t)
    if k2txb.get()!=0: ntx.set(1)
    Audio.gcom2.hiscall=(ToRadio.get()+'            ')[:12]
    for m in (tx1, tx2, tx3, tx4, tx5, tx6):
        m.delete(0,99)
    if ToRadio.get().find("/") == -1 and \
           options.MyCall.get().find("/") == -1:
        t=ToRadio.get() + " "+options.MyCall.get() + " "+options.MyGrid.get()[:4]
        tx1.insert(0,t.upper())
    else:
        tx1.insert(0,ToRadio.get() + " "+options.MyCall.get())
    tx2.insert(0,tx1.get()+" OOO")
    tx3.insert(0,"RO")
    tx4.insert(0,"RRR")
    tx5.insert(0,"73")
    t="CQ " + options.MyCall.get()+ " "+options.MyGrid.get()[:4]
    tx6.insert(0,t.upper())
    altmsg=0
    
#------------------------------------------------------ GenAltMsgs
def GenAltMsgs(event=NONE):
    global altmsg,tx6alt
    t=ToRadio.get().upper().strip()
    ToRadio.delete(0,99)
    ToRadio.insert(0,t)
    if k2txb.get()!=0: ntx.set(1)
    Audio.gcom2.hiscall=(ToRadio.get()+'            ')[:12]
    if ToRadio.get().find("/") == -1 and options.MyCall.get().find("/") == -1:
        for m in (tx1, tx2, tx3, tx4, tx5, tx6):
            m.delete(0,99)
        t=ToRadio.get() + " "+options.MyCall.get()
        tx1.insert(0,t.upper())
        tx2.insert(0,tx1.get()+" OOO")
        tx3.insert(0,tx1.get()+" RO")
        tx4.insert(0,tx1.get()+" RRR")
        tx5.insert(0,"TNX 73 GL ")
        tx6.insert(0,tx6alt.upper())
        altmsg=1

#------------------------------------------------------ update
def update():
    global root_geom,isec0,naz,nel,ndmiles,ndkm,nopen, \
           im,pim,cmap0,isync,isync_save,idsec,first,itol,txsnrdb,tx6alt,\
           bm_geom,bm2_geom
    
    utc=time.gmtime(time.time()+0.1*idsec)
    isec=utc[5]

    if isec != isec0:                           #Do once per second
        isec0=isec
        t=time.strftime('%Y %b %d\n%H:%M:%S',utc)
        Audio.gcom2.utcdate=t[:12]
        ldate.configure(text=t)
        t="Rx noise: %.1f dB" % Audio.gcom2.rxnoise
        msg4.configure(text=t)
        t="Drop: %.2f %%" % Audio.gcom2.pctlost
        msg5.configure(text=t)
        root_geom=root.geometry()
        try:
            bm_geom=bm.geometry()
            bm2_geom=bm2.geometry()
        except:
            pass
        utchours=utc[3]+utc[4]/60.0 + utc[5]/3600.0
        naz,nel,ndmiles,ndkm,nhotaz,nhotabetter=Audio.azdist0( \
            options.MyGrid.get().upper(),HisGrid.get().upper(),utchours)
        azdist()
        g.nfreq=nfreq.get()

        if Audio.gcom2.ndecoding==0:
            g.AzSun,g.ElSun,g.AzMoon,g.ElMoon,g.AzMoonB,g.ElMoonB,g.ntsky, \
                g.ndop,g.ndop00,g.dbMoon,g.RAMoon,g.DecMoon,g.HA8,g.Dgrd,  \
                g.sd,g.poloffset,g.MaxNR,g.dfdt,g.dfdt0,g.RaAux,g.DecAux, \
                g.AzAux,g.ElAux = Audio.astro0(utc[0],utc[1],utc[2],  \
                utchours,nfreq.get(),options.MyGrid.get().upper(), \
                    options.auxra.get()+'         '[:9],     \
                    options.auxdec.get()+'         '[:9])

            if len(HisGrid.get().strip())<4:
                g.ndop=g.ndop00
                g.dfdt=g.dfdt0
        astrotext.delete(1.0,END)
        astrotext.insert(END,'   Moon\n')
        astrotext.insert(END,"Az: %7.1f\n" % g.AzMoon)
        astrotext.insert(END,"El: %7.1f\n" % g.ElMoon)
        astrotext.insert(END,"DxAz: %5.1f\n" % g.AzMoonB)
        astrotext.insert(END,"DxEl: %5.1f\n" % g.ElMoonB)
        astrotext.insert(END,'    Sun\n')
        astrotext.insert(END,"Az: %7.1f\n" % g.AzSun)
        astrotext.insert(END,"El: %7.1f\n\n" % g.ElSun)
        astrotext.insert(END,"Dop:%7d\n" % g.ndop)
        astrotext.insert(END,"Dgrd:%6.1f\n" % g.Dgrd)

    if g.freeze_decode and mode.get()[:4]=='JT65':
        itol=5
        ltol.configure(text='Tol    '+str(500))
        Audio.gcom2.dftolerance=500
        nfreeze.set(1)
        Audio.gcom2.nfreeze=1
        if Audio.gcom2.monitoring:
            Audio.gcom2.ndecoding=1
 #           Audio.gcom2.nagain=0
            Audio.gcom2.nagain=1
        else:
            Audio.gcom2.ndecoding=4
            Audio.gcom2.nagain=1
        g.freeze_decode=0

    t=g.ftnstr(Audio.gcom2.decodedfile)
    i=g.rfnd(t,".")
    t=t[:i]
    if mode.get() != g.mode or first:
        if mode.get()[:4]=='JT65':
            msg1.configure(bg='#00FFFF')
        elif mode.get()=='Measure':
            msg1.configure(bg='yellow')
        g.mode=mode.get()
        first=0

    samfac_out=Audio.gcom1.mfsample2/110250.0
    t="%6.4f" % (samfac_out)
    options.meas_rateout.setvalue(t)
    msg1.configure(text=mode.get())
    t="QSO Freq:%4d" % (int(Audio.gcom2.mousefqso),)
    msg2.configure(text=t)    
    t="QSO DF:%4d" % (int(Audio.gcom2.mousedf),)
    msg3.configure(text=t)

    txminute=0
    if Audio.gcom2.lauto and utc[4]%2 == Audio.gcom1.txfirst: txminute=1
    if mode.get()[:4]=='JT65' and (Audio.gcom2.ndecoding>0 or \
         (isec>45 and  txminute==0 and Audio.gcom2.monitoring==1 and \
          Audio.datcom.kkdone!=-99 and Audio.gcom2.ndiskdat!=1)):
#Set button bg while decoding
        bc='#66FFFF'
        bdecode.configure(bg=bc,activebackground=bc,state=DISABLED)
    else:
        bdecode.configure(bg='gray85',activebackground='gray85',state=ACTIVE)
        g.ndecphase=0

    tx1.configure(bg='white')
    tx2.configure(bg='white')
    tx3.configure(bg='white')
    tx4.configure(bg='white')
    tx5.configure(bg='white')
    tx6.configure(bg='white')
    if tx6.get()[:1]=='#':
        try:
            txsnrdb=float(tx6.get()[1:])
            if txsnrdb>-99.0 and txsnrdb<40.0:
                Audio.gcom1.txsnrdb=txsnrdb
                tx6.configure(bg='orange')
        except:
            txsnrdb=99.0
    else:
        txsnrdb=99.0
        Audio.gcom1.txsnrdb=txsnrdb
    if Audio.gcom2.monitoring and not Audio.gcom1.transmitting:
        bmonitor.configure(bg='green')
    else:
        bmonitor.configure(bg='gray85')    
    if Audio.gcom1.transmitting:
        nmsg=int(Audio.gcom2.nmsg)
        t=g.ftnstr(Audio.gcom2.sending)
        t="Txing:  "+t[:nmsg]
        bgcolor='yellow'
        if Audio.gcom2.sendingsh==1:  bgcolor='#66FFFF'    #Shorthand (lt blue)
        if Audio.gcom2.sendingsh==-1: bgcolor='red'        #Plain Text
        if Audio.gcom2.sendingsh==2: bgcolor='pink'        #Test file
        if txsnrdb<90.0: bgcolor='orange'                  #Simulation mode
        if Audio.gcom2.ntxnow==1: tx1.configure(bg=bgcolor)
        elif Audio.gcom2.ntxnow==2: tx2.configure(bg=bgcolor)
        elif Audio.gcom2.ntxnow==3: tx3.configure(bg=bgcolor)
        elif Audio.gcom2.ntxnow==4: tx4.configure(bg=bgcolor)
        elif Audio.gcom2.ntxnow==5: tx5.configure(bg=bgcolor)
        else: tx6.configure(bg=bgcolor)
    else:
        bgcolor='green'
        t='Receiving'
    msg6.configure(text=t,bg=bgcolor)

    if Audio.gcom2.ndecdone>0 or g.cmap != cmap0:
        if Audio.gcom2.ndecdone==1:
            if isync==-99 or isync==99:
                isync=isync_save
                Audio.gcom2.minsigdb=isync
            try:
                f=open(appdir+'/decoded.txt',mode='r')
                lines=f.readlines()
                f.close()
            except:
                lines=""
            text.configure(state=NORMAL)
            for i in range(len(lines)-1):
                text.insert(END,lines[i])
            text.see(END)
            g.ndecphase=1
#            text.configure(state=DISABLED)

            try:
                f=open(appdir+'/decoded.ave',mode='r')
                lines=f.readlines()
                f.close()
            except:
                lines[0]=""
                lines[1]=""
            avetext.configure(state=NORMAL)
            avetext.delete('1.0',END)
            if len(lines)>1:
                avetext.insert(END,lines[0])
                avetext.insert(END,lines[1])
#            avetext.configure(state=DISABLED)
            cleartext()
            Audio.gcom2.ndecdone=0

        if Audio.gcom2.ndecdone==2:
            try:
                f=open(appdir+'/messages.txt',mode='r')
                lines=f.readlines()
                f.close()
            except:
                lines=""
            msgtext.configure(state=NORMAL)
            msgtext.delete('1.0',END)
            msgtext.insert(END,'Freq  DF Pol  UTC\n')
            msgtext.insert(END,'----------------------------------------\n')
            for i in range(len(lines)):
                try:
                    nage=int(lines[i][41:])
                except:
                    nage=0
                lines[i]=lines[i][:41]+'\n'
                if nage==0: attr='age0'
                if nage==1: attr='age1'
                if nage==2: attr='age2'
                if nage>=3: attr='age3'
                msgtext.insert(END,lines[i],attr)
            msgtext.see(END)

            try:
                f=open(appdir+'/bandmap.txt',mode='r')
                lines=f.readlines()
                f.close()
            except:
                lines=""
            bmtext.configure(state=NORMAL)
            bmtext.delete('1.0',END)
            for i in range(len(lines)):
                for j in range(3):
                    ka=14*j
                    kb=ka+12
                    t=lines[i][ka:kb]
                    try:
                        nage=int(t[10:])
                    except:
                        nage=0
                    t=t[:11]+' '
                    if j==2: t=t+'\n'
                    if nage==0: attr='age0'
                    if nage==1: attr='age1'
                    if nage==2: attr='age2'
                    if nage>=3: attr='age3'
                    bmtext.insert(END,t,attr)
                    t=t[:12]
                    if t!="            ":
                        try:
                            k=int(t[:3])
                            c=t[4:10]
                            if c!=NONE:
                                t=g.fc[k]
                                if t.find(c+" ") == -1:
                                    g.fc[k]=g.fc[k] + c + " "
                        except:
                            pass
            bmtext.see(END)
#            for i in range(100,160):
#                if g.fc[i]!="": print i,g.fc[i]

            Audio.gcom2.ndecdone=0
            if loopall: opennext()
            nopen=0

        if g.cmap != cmap0:
            im.putpalette(g.palette)
            cmap0=g.cmap
            
# Save some parameters
    g.mode=mode.get()
    Audio.gcom1.txfirst=TxFirst.get()
    try:
        Audio.gcom1.samfacin=options.samfacin.get()
    except:
        Audio.gcom1.samfacin=1.0
    try:
        Audio.gcom1.samfacout=options.samfacout.get()
    except:
        Audio.gcom1.samfacout=1.0
    Audio.gcom2.mycall=(options.MyCall.get()+'            ')[:12]
    Audio.gcom2.hiscall=(ToRadio.get()+'            ')[:12]
    Audio.gcom2.hisgrid=(HisGrid.get()+'      ')[:6]
    Audio.gcom4.addpfx=(options.addpfx.get().lstrip()+'        ')[:8]
    Audio.gcom2.ntxreq=ntx.get()
    tx=(tx1,tx2,tx3,tx4,tx5,tx6)
    Audio.gcom2.txmsg=(tx[ntx.get()-1].get()+'                            ')[:28]
    Audio.gcom2.mode=(mode.get()+'      ')[:6]
    Audio.gcom2.nsave=nsave.get()
    Audio.gcom2.nzap=nzap.get()
    n=ndebug.get()
    if ndebug2.get(): n=2
    Audio.gcom2.ndebug=n
    Audio.gcom2.minsigdb=isync
    Audio.gcom2.nclip=iclip
    Audio.gcom2.nblank=nblank.get()
    Audio.gcom2.nafc=nafc.get()
    Audio.gcom2.nfreeze=nfreeze.get()
    Audio.gcom2.dftolerance=ntol[itol]
    Audio.gcom2.neme=neme.get()
    Audio.gcom2.ndepth=ndepth.get()
    try:
        Audio.gcom2.idinterval=options.IDinterval.get()
    except:
        Audio.gcom2.idinterval=0
    Audio.gcom2.ntx2=0
    try:
        Audio.gcom2.nkeep=options.nkeep.get()
    except:
        Audio.gcom2.nkeep=20
    try:
        Audio.gcom2.idphi=options.dphi.get()
    except:
        Audio.gcom2.idphi=0
    try:
        Audio.gcom2.nfa=options.fa.get()
    except:
        Audio.gcom2.nfa=100
    try:
        Audio.gcom2.nfb=options.fb.get()
    except:
        Audio.gcom2.nfa=160
    try:
        Audio.gcom2.nfcal=options.fcal.get()
    except:
        Audio.gcom2.nfcal=0
    t=options.savedir.get() + \
        '                                        ' + \
        '                                        '
    Audio.gcom2.savedir=t[:80]
    
#    Audio.gcom1.rxdelay=float('0'+options.RxDelay.get())
#    Audio.gcom1.txdelay=float('0'+options.TxDelay.get())
    if ntx.get()==1 and noshjt65.get()==1: Audio.gcom2.ntx2=1
    Audio.gcom2.nslim2=isync-4
    try:
        Audio.gcom2.nport=int(options.PttPort.get())
    except:
        Audio.gcom2.nport=0
    Audio.gcom2.pttport=(options.PttPort.get() + '            ')[:12]
    if altmsg: tx6alt=tx6.get()    
    ldate.after(100,update)                       # Queue up the next update
    
#------------------------------------------------------ Top level frame
frame = Frame(root)

#------------------------------------------------------ Menu Bar
mbar = Frame(frame)
mbar.pack(fill = X)

#------------------------------------------------------ File Menu
filebutton = Menubutton(mbar, text = 'File')
filebutton.pack(side = LEFT)
filemenu = Menu(filebutton, tearoff=0)
filebutton['menu'] = filemenu
filemenu.add('command', label = 'Open', command = openfile, \
             accelerator='Ctrl+O')
filemenu.add('command', label = 'Open next in directory', command = opennext, \
             accelerator='F6')
filemenu.add('command', label = 'Decode remaining files in directory', \
             command = decodeall, accelerator='Shift+F6')
filemenu.add_separator()
filemenu.add('command', label = 'Delete all *.WAV files in RxWav', \
             command = delwav)
filemenu.add('command', label = 'Erase Band Map and Messages', command = clr_all)
filemenu.add('command', label = 'Erase ALL65.TXT', command = del_all)
filemenu.add_separator()
filemenu.add('command', label = 'Exit', command = quit)

#------------------------------------------------------ Setup menu
setupbutton = Menubutton(mbar, text = 'Setup')
setupbutton.pack(side = LEFT)
setupmenu = Menu(setupbutton, tearoff=0)
setupbutton['menu'] = setupmenu
setupmenu.add('command', label = 'Options', command = options1, \
              accelerator='F2')
setupmenu.add_separator()
setupmenu.add('command', label = 'Generate messages for test tones', command=testmsgs)
setupmenu.add('command', label = 'Find Delta Phi', command=delta_phi)
setupmenu.add_separator()
setupmenu.add_checkbutton(label = 'F4 sets Tx6',variable=kb8rq)
setupmenu.add_checkbutton(label = 'Double-click on callsign sets TxFirst',
                          variable=setseq)
setupmenu.add_checkbutton(label = 'GenStdMsgs sets Tx1',variable=k2txb)
setupmenu.add_separator()
setupmenu.add_checkbutton(label = 'Enable diagnostics',variable=ndebug)
setupmenu.add_checkbutton(label = 'Verbose diagnostics',variable=ndebug2)

#------------------------------------------------------ View menu
viewbutton=Menubutton(mbar,text='View')
viewbutton.pack(side=LEFT)
viewmenu=Menu(viewbutton,tearoff=0)
viewbutton['menu']=viewmenu
viewmenu.add('command', label = 'SpecJT', command = showspecjt, \
             accelerator='F10')
viewmenu.add('command', label = 'Messages', command = messages)
viewmenu.add('command', label = 'Band Map', command = bandmap)
viewmenu.add('command', label = 'Astronomical data', command = astro1, \
             accelerator='Shift+F10')

#------------------------------------------------------ Mode menu
modebutton = Menubutton(mbar, text = 'Mode')
modebutton.pack(side = LEFT)
modemenu = Menu(modebutton, tearoff=0)
modebutton['menu'] = modemenu

# To enable menu item 0:
# modemenu.entryconfig(0,state=NORMAL)
# Can use the following to retrieve the state:
# state=modemenu.entrycget(0,"state")

modemenu.add_radiobutton(label = 'JT65A', variable=mode, command = ModeJT65A, \
            state=DISABLED, accelerator='F8')
modemenu.add_radiobutton(label = 'JT65B', variable=mode, command = ModeJT65B, \
                         accelerator='Shift+F8')
modemenu.add_radiobutton(label = 'JT65C', variable=mode, command = ModeJT65C, \
            state=DISABLED, accelerator='Ctrl+F8')
modemenu.add_radiobutton(label = 'Measure', variable=mode)
modemenu.add_radiobutton(label = 'Pulsar', variable=mode,state=DISABLED)

#------------------------------------------------------ Decode menu
decodebutton = Menubutton(mbar, text = 'Decode')
decodebutton.pack(side = LEFT)
decodemenu = Menu(decodebutton, tearoff=0)
decodebutton['menu'] = decodemenu
decodemenu.add_checkbutton(label='Only EME calls',variable=neme)
decodemenu.add_checkbutton(label='No Shorthands if Tx 1',variable=noshjt65)
decodemenu.add_separator()
decodemenu.add_radiobutton(label = 'No Deep Search',
                                variable=ndepth, value=0)
decodemenu.add_radiobutton(label = 'Normal Deep Search',
                                variable=ndepth, value=1)
decodemenu.add_radiobutton(label = 'Aggressive Deep Search',
                                variable=ndepth, value=2)
#decodemenu.add_radiobutton(label ='Include Average in Aggressive Deep Search',
#                                variable=ndepth, value=3)

#------------------------------------------------------ Save menu
savebutton = Menubutton(mbar, text = 'Save')
savebutton.pack(side = LEFT)
savemenu = Menu(savebutton, tearoff=1)
savebutton['menu'] = savemenu
nsave=IntVar()
savemenu.add_radiobutton(label = 'None', variable=nsave,value=0)
savemenu.add_radiobutton(label = 'Save all', variable=nsave,value=1)
nsave.set(0)

#------------------------------------------------------ Band menu
bandbutton = Menubutton(mbar, text = 'Band')
bandbutton.pack(side = LEFT)
bandmenu = Menu(bandbutton, tearoff=1)
bandbutton['menu'] = bandmenu
nfreq=IntVar()
bandmenu.add_radiobutton(label = '50', variable=nfreq,value=50)
bandmenu.add_radiobutton(label = '144', variable=nfreq,value=144)
bandmenu.add_radiobutton(label = '222', variable=nfreq,value=222)
bandmenu.add_radiobutton(label = '432', variable=nfreq,value=432)
bandmenu.add_radiobutton(label = '1296', variable=nfreq,value=1296)
bandmenu.add_radiobutton(label = '2304', variable=nfreq,value=2304)
nfreq.set(144)
#------------------------------------------------------ Help menu
helpbutton = Menubutton(mbar, text = 'Help')
helpbutton.pack(side = LEFT)
helpmenu = Menu(helpbutton, tearoff=0)
helpbutton['menu'] = helpmenu
helpmenu.add('command', label = 'Keyboard shortcuts', command = shortcuts, \
             accelerator='F1')
helpmenu.add('command', label = 'Special mouse commands', \
             command = mouse_commands, accelerator='Shift+F1')
helpmenu.add('command', label = 'What message to send?', \
             command = what2send, accelerator='F5')
helpmenu.add('command', label = 'Available suffixes and add-on prefixes', \
             command = prefixes)
helpmenu.add('command', label = 'About MAP65', command = about, \
             accelerator='Ctrl+F1')

#------------------------------------------------------ Label above text
iframe2 = Frame(frame, bd=1, relief=FLAT,height=15)
lab2=Label(iframe2, text='Freq      DF    Pol     UTC       DT      dB')
lab2.place(x=3,y=6, anchor='w')
lab7=Label(iframe2,text='F3',fg='gray85')
lab7.place(x=495,y=6, anchor=CENTER)
iframe2.pack(expand=1, fill=BOTH, padx=4)

#-------------------------------------------------------- Decoded text
iframe4 = Frame(frame, bd=2, relief=SUNKEN)
text=Text(iframe4, height=16, width=65)
text.bind('<Double-Button-1>',dbl_click_text)
#text.bind('<Double-Button-3>',dbl_click_text)
text.bind('<Key>',textkey)

root.bind_all('<F1>', shortcuts)
root.bind_all('<Shift-F1>', mouse_commands)
root.bind_all('<Control-F1>', about)
root.bind_all('<F2>', options1)
root.bind_all('<F3>', txmute)
root.bind_all('<F4>', clrToRadio)
root.bind_all('<F5>', what2send)
root.bind_all('<F6>', opennext)
root.bind_all('<Shift-F6>', decodeall)
root.bind_all('<F8>', ModeJT65A)
root.bind_all('<Shift-F8>', ModeJT65B)
root.bind_all('<Control-F8>', ModeJT65C)
root.bind_all('<F10>', showspecjt)
root.bind_all('<Shift-F10>', astro1)
root.bind_all('<F11>',left_arrow)
root.bind_all('<Shift-F11>',dec_fqso)
root.bind_all('<F12>',right_arrow)
root.bind_all('<Shift-F12>',inc_fqso)
root.bind_all('<Alt-Key-1>',btx1)
root.bind_all('<Alt-Key-2>',btx2)
root.bind_all('<Alt-Key-3>',btx3)
root.bind_all('<Alt-Key-4>',btx4)
root.bind_all('<Alt-Key-5>',btx5)
root.bind_all('<Alt-Key-6>',btx6)

root.bind_all('<Alt-a>',toggleauto)
root.bind_all('<Alt-A>',toggleauto)
root.bind_all('<Alt-c>',clear_avg)
root.bind_all('<Alt-C>',clear_avg)
root.bind_all('<Alt-d>',decode)
root.bind_all('<Alt-D>',decode)
root.bind_all('<Alt-e>',erase)
root.bind_all('<Alt-E>',erase)
root.bind_all('<Alt-f>',toggle_freeze)
root.bind_all('<Alt-F>',toggle_freeze)
root.bind_all('<Alt-g>',GenStdMsgs)
root.bind_all('<Alt-G>',GenStdMsgs)
root.bind_all('<Control-g>', GenAltMsgs)
root.bind_all('<Control-G>', GenAltMsgs)
root.bind_all('<Alt-i>',decode_include)
root.bind_all('<Alt-I>',decode_include)
root.bind_all('<Alt-l>',lookup)
root.bind_all('<Alt-L>',lookup)
root.bind_all('<Alt-m>',monitor)
root.bind_all('<Alt-M>',monitor)
root.bind_all('<Alt-o>',txstop)
root.bind_all('<Alt-O>',txstop)
root.bind_all('<Control-o>',openfile)
root.bind_all('<Control-O>',openfile)
root.bind_all('<Alt-q>',logqso)
root.bind_all('<Alt-Q>',logqso)
root.bind_all('<Alt-s>',stopmon)
root.bind_all('<Alt-S>',stopmon)
root.bind_all('<Alt-x>',decode_exclude)
root.bind_all('<Alt-X>',decode_exclude)
root.bind_all('<Alt-z>',toggle_zap)
root.bind_all('<Alt-Z>',toggle_zap)
root.bind_all('<Control-l>',lookup_gen)
root.bind_all('<Control-L>',lookup_gen)

text.pack(side=LEFT, fill=X, padx=1)
sb = Scrollbar(iframe4, orient=VERTICAL, command=text.yview)
sb.pack(side=LEFT, fill=Y)
text.configure(yscrollcommand=sb.set)

astrotext_font='"Lucida Console" 16'
astrotext=Text(iframe4, bg="#66FFFF",height=10,width=11,font=astrotext_font)
astrotext.pack(side=LEFT, fill=BOTH, padx=4)
g2font=astrotext_font
if g2font!="": g.g2font=g2font

iframe4.pack(expand=1, fill=X, padx=4)
iframe4b = Frame(frame, bd=2, relief=SUNKEN)
avetext=Text(iframe4b, height=2, width=65)
avetext.bind('<Double-Button-1>',dbl_click_ave)
#avetext.bind('<Double-Button-3>',dbl_click_ave)
avetext.bind('<Key>',avetextkey)
avetext.pack(side=LEFT, fill=X, padx=1)
iframe4b.pack(expand=1, fill=X, padx=4)

#------------------------------------------------------- Button Bar
iframe4c = Frame(frame, bd=1, relief=SUNKEN)
blogqso=Button(iframe4c, text='Log QSO',underline=4,command=logqso,
                padx=1,pady=1)
bstop=Button(iframe4c, text='Stop',underline=0,command=stopmon,
                padx=1,pady=1)
bmonitor=Button(iframe4c, text='Monitor',underline=0,command=monitor,
                padx=1,pady=1)
bdecode=Button(iframe4c, text='Decode',underline=0,command=decode,
                padx=1,pady=1)
berase=Button(iframe4c, text='Erase',underline=0,command=erase,
                padx=1,pady=1)
bclravg=Button(iframe4c, text='Clear Avg',underline=0,command=clear_avg,
                padx=1,pady=1)
binclude=Button(iframe4c, text='Include',underline=0,
                command=decode_include,padx=1,pady=1)
bexclude=Button(iframe4c, text='Exclude',underline=1,
                command=decode_exclude,padx=1,pady=1)
btxstop=Button(iframe4c,text='TxStop',underline=4,command=txstop,
                padx=1,pady=1)

blogqso.pack(side=LEFT,expand=1,fill=X)
bstop.pack(side=LEFT,expand=1,fill=X)
bmonitor.pack(side=LEFT,expand=1,fill=X)
bdecode.pack(side=LEFT,expand=1,fill=X)
berase.pack(side=LEFT,expand=1,fill=X)
bclravg.pack(side=LEFT,expand=1,fill=X)
binclude.pack(side=LEFT,expand=1,fill=X)
bexclude.pack(side=LEFT,expand=1,fill=X)
btxstop.pack(side=LEFT,expand=1,fill=X)
iframe4c.pack(expand=1, fill=X, padx=4)

#-----------------------------------------------------General control area
iframe5 = Frame(frame, bd=1, relief=FLAT,height=180)

#------------------------------------------------------ "Other station" info
f5a=Frame(iframe5,height=170,bd=2,relief=GROOVE)
labToRadio=Label(f5a,text='To radio:', width=9, relief=FLAT)
labToRadio.grid(column=0,row=0)
ToRadio=Entry(f5a,width=9)
ToRadio.insert(0,'W8WN')
ToRadio.grid(column=1,row=0,pady=3)
bLookup=Button(f5a, text='Lookup',underline=0,command=lookup,padx=1,pady=1)
bLookup.grid(column=2,row=0,sticky='EW',padx=4)
labGrid=Label(f5a,text='Grid:', width=9, relief=FLAT)
labGrid.grid(column=0,row=1)
HisGrid=Entry(f5a,width=9)
HisGrid.grid(column=1,row=1,pady=1)
bAdd=Button(f5a, text='Add',command=addtodb,padx=1,pady=1)
bAdd.grid(column=2,row=1,sticky='EW',padx=4)
labAz=Label(f5a,text='Az 257  El 15',width=11)
labAz.grid(column=1,row=2)
labDist=Label(f5a,text='16753 km')
labDist.grid(column=2,row=2)

#------------------------------------------------------ Date and Time
ldate=Label(f5a, bg='black', fg='yellow', width=11, bd=4,
        text='2005 Apr 22\n01:23:45', relief=RIDGE,
        justify=CENTER, font=(font1,16))
ldate.grid(column=0,columnspan=3,row=3,rowspan=2,pady=2)
f5a.pack(side=LEFT,expand=1,fill=BOTH)

#------------------------------------------------------ Receiving parameters
f5b=Frame(iframe5,bd=2,relief=GROOVE)
nzap=IntVar()
ltol=Label(f5b, bg='white', fg='black', text='Tol    400', width=8, relief=RIDGE)
ltol.grid(column=0,row=2,padx=2,pady=1,sticky='EW')
Widget.bind(ltol,'<Button-1>',inctol)
Widget.bind(ltol,'<Button-3>',dectol)
ldsec=Label(f5b, bg='white', fg='black', text='Dsec  0.0', width=8, relief=RIDGE)
ldsec.grid(column=0,row=4,ipadx=3,padx=2,pady=5,sticky='EW')
Widget.bind(ldsec,'<Button-1>',incdsec)
Widget.bind(ldsec,'<Button-3>',decdsec)

f5b.pack(side=LEFT,expand=1,fill=BOTH)

#------------------------------------------------------ Tx params and msgs
f5c=Frame(iframe5,bd=2,relief=GROOVE)
txfirst=Checkbutton(f5c,text='Tx First',justify=RIGHT,variable=TxFirst)
f5c2=Frame(f5c,bd=0)
genmsg=Button(f5c,text='GenStdMsgs',underline=0,command=GenStdMsgs,
            padx=1,pady=1)
auto=Button(f5c,text='Auto is Off',underline=0,command=toggleauto,
            padx=1,pady=1)
auto.focus_set()

txfirst.grid(column=0,row=0,sticky='W',padx=4)
f5c2.grid(column=0,row=1,sticky='W',padx=4)
#sked.grid(column=0,row=3,sticky='W',padx=4)
genmsg.grid(column=0,row=4,sticky='W',padx=4)
auto.grid(column=0,row=5,sticky='EW',padx=4)

ntx=IntVar()
tx1=Entry(f5c,width=24)
rb1=Radiobutton(f5c,value=1,variable=ntx)
b1=Button(f5c, text='Tx1',underline=2,command=btx1,padx=1,pady=1)
tx1.grid(column=1,row=0)
rb1.grid(column=2,row=0)
b1.grid(column=3,row=0)

tx2=Entry(f5c,width=24)
rb2=Radiobutton(f5c,value=2,variable=ntx)
b2=Button(f5c, text='Tx2',underline=2,command=btx2,padx=1,pady=1)
tx2.grid(column=1,row=1)
rb2.grid(column=2,row=1)
b2.grid(column=3,row=1)

tx3=Entry(f5c,width=24)
rb3=Radiobutton(f5c,value=3,variable=ntx)
b3=Button(f5c, text='Tx3',underline=2,command=btx3,padx=1,pady=1)
tx3.grid(column=1,row=2)
rb3.grid(column=2,row=2)
b3.grid(column=3,row=2)

tx4=Entry(f5c,width=24)
rb4=Radiobutton(f5c,value=4,variable=ntx)
b4=Button(f5c, text='Tx4',underline=2,command=btx4,padx=1,pady=1)
tx4.grid(column=1,row=3)
rb4.grid(column=2,row=3)
b4.grid(column=3,row=3)

tx5=Entry(f5c,width=24)
rb5=Radiobutton(f5c,value=5,variable=ntx)
b5=Button(f5c, text='Tx5',underline=2,command=btx5,padx=1,pady=1)
tx5.grid(column=1,row=4)
rb5.grid(column=2,row=4)
b5.grid(column=3,row=4)

tx6=Entry(f5c,width=24)
rb6=Radiobutton(f5c,value=6,variable=ntx)
b6=Button(f5c, text='Tx6',underline=2,command=btx6,padx=1,pady=1)
tx6.grid(column=1,row=5)
rb6.grid(column=2,row=5)
b6.grid(column=3,row=5)

f5c.pack(side=LEFT,expand=1,fill=BOTH)
iframe5.pack(expand=1, fill=X, padx=4)

#------------------------------------------------------------ Status Bar
iframe6 = Frame(frame, bd=1, relief=SUNKEN)
msg1=Message(iframe6, text="Message #2", width=300,relief=SUNKEN)
msg1.pack(side=LEFT, fill=X, padx=1)
msg2=Message(iframe6,width=300,relief=SUNKEN)
msg2.pack(side=LEFT, fill=X, padx=1)
msg3=Message(iframe6, text="", width=300,relief=SUNKEN)
msg3.pack(side=LEFT, fill=X, padx=1)
msg4=Message(iframe6, text="", width=300,relief=SUNKEN)
msg4.pack(side=LEFT, fill=X, padx=1)
msg5=Message(iframe6, text="", width=300,relief=SUNKEN)
msg5.pack(side=LEFT, fill=X, padx=1)
msg6=Message(iframe6, text='                        ', width=300,relief=SUNKEN)
msg6.pack(side=RIGHT, fill=X, padx=1)
iframe6.pack(expand=1, fill=X, padx=4)
frame.pack()
ldate.after(100,update)
lauto=0
isync=1
ntx.set(1)
ndepth.set(1)
import options
ModeJT65B()
lookup()
balloon.unbind(ToRadio)
g.astro_geom0="+0+0"
Audio.gcom1.mute=0

#---------------------------------------------------------- Process INI file
try:
    f=open(appdir+'/MAP65.INI',mode='r')
    params=f.readlines()
except:
    params=""
    if g.Win32:
        options.PttPort.set("0")
    else:
        options.PttPort.set("/dev/ttyS0")
    Audio.gcom2.nport=0

try:
    for i in range(len(params)):
        key,value=params[i].split()
        if   key == 'MAP65Geometry': root.geometry(value)
        elif key == 'BMGeometry': bm_geom=value
        elif key == 'BM2Geometry': bm2_geom=value
        elif key == 'Mode':
            mode.set(value)
            if value=='JT65A':
                ModeJT65A()
            elif value=='JT65B':
                ModeJT65B()
            elif value=='JT65C':
                ModeJT65C()
        elif key == 'MyCall': options.MyCall.set(value)
        elif key == 'MyGrid': options.MyGrid.set(value)
        elif key == 'HisCall':
            hiscall=value
            if hiscall=="______": hiscall=""
            ToRadio.delete(0,END)
            ToRadio.insert(0,hiscall)
        elif key == 'HisGrid':
            hisgrid=value
            if hisgrid == "XX00xx":
                lookup()
            HisGrid.delete(0,END)
            HisGrid.insert(0,hisgrid)
#        elif key == 'RxDelay': options.RxDelay.set(value)
#        elif key == 'TxDelay': options.TxDelay.set(value)
        elif key == 'IDinterval': options.IDinterval.set(value)
        elif key == 'PttPort':
            try:
                options.PttPort.set(value)
                try:
                    Audio.gcom2.nport=int(options.PttPort.get())
                except:
                    Audio.gcom2.nport=0
            except:
                if g.Win32:
                    options.PttPort.set("0")
                else:
                    options.PttPort.set("/dev/ttyS0")
                Audio.gcom2.nport=0
            Audio.gcom2.pttport=(options.PttPort.get()+'            ')[:12]
        elif key == 'Mileskm': options.mileskm.set(value)
        elif key == 'AudioOut':
            try:
                g.ndevout.set(value)
            except:
                g.ndevout.set(0)
            g.DevoutName.set(value)
            options.DevoutName.set(value)
            Audio.gcom1.devout_name=(options.DevoutName.get()+'            ')[:12]
        elif key == 'SamFacOut': options.samfacout.set(value)
        elif key == 'AddPrefix': options.addpfx.set(value.replace("_"," ").lstrip())
        elif key == 'AuxRA': options.auxra.set(value)
        elif key == 'AuxDEC': options.auxdec.set(value)
        
        elif key == 'nkeep': options.nkeep.set(value)
        elif key == 'fa': options.fa.set(value)
        elif key == 'fb': options.fb.set(value)
        elif key == 'fcal': options.fcal.set(value)
        elif key == 'dphi': options.dphi.set(value)
        elif key == 'savedir': options.savedir.set(value)
        
        elif key == 'TxFirst': TxFirst.set(value)
        elif key == 'KB8RQ': kb8rq.set(value)
        elif key == 'K2TXB': k2txb.set(value)
        elif key == 'SetSeq': setseq.set(value)
        elif key == 'Nsave': nsave.set(value)
        elif key == 'Band': nfreq.set(value)
        elif key == 'Sync': isync=int(value)
        elif key == 'Clip': iclip=int(value)
        elif key == 'Zap': nzap.set(value)
        elif key == 'NB': nblank.set(value)
        elif key == 'NAFC': nafc.set(value)
#        elif key == 'Sked': nsked.set(value)
        elif key == 'NoSh441': nosh441.set(value)
        elif key == 'NoShJT65': noshjt65.set(value)
        elif key == 'NEME': neme.set(value)
        elif key == 'NDepth': ndepth.set(value)
        elif key == 'Debug': ndebug.set(value)
        elif key == 'Debug2': ndebug2.set(value)
        elif key == 'HisCall':
            Audio.gcom2.hiscall=(value+'            ')[:12]
            ToRadio.delete(0,99)
            ToRadio.insert(0,value)
            lookup()                       #Maybe should save HisGrid, instead?
        elif key == 'MRUDir': mrudir=value.replace("#"," ")
        elif key == 'AstroGeometry': g.astro_geom0 =value
        else: pass
except:
    print 'Error reading MAP65.INI, continuing with defaults.'
    print key,value

g.mode=mode.get()
Audio.gcom2.appdir=(appdir+'                                                                                          ')[:80]
Audio.gcom2.ndepth=ndepth.get()
f=open(appdir+'/tmp26.txt','w')
f.truncate(0)
f.close
Audio.ftn_init()
GenStdMsgs()
Audio.gcom4.addpfx=(options.addpfx.get().lstrip()+'        ')[:8]
Audio.gcom2.mousefqso=125
# stopmon()
monitor()
first=1
if g.Win32: root.iconbitmap("wsjt.ico")
root.title('  MAP65     by K1JT')
messages()
bandmap()
import astro
import specjt

# SpecJT has a "mainloop", so it does not return until terminated.
#root.mainloop()   #Superseded by mainloop in SpecJT

# Clean up and save user options before terminating
f=open(appdir+'/MAP65.INI',mode='a')
root_geom=root_geom[root_geom.index("+"):]
f.write("MAP65Geometry " + root_geom + "\n")
bm_geom=bm_geom[bm_geom.index("+"):]
f.write("BMGeometry " + bm_geom + "\n")
bm2_geom=bm2_geom[bm2_geom.index("+"):]
f.write("BM2Geometry " + bm2_geom + "\n")
f.write("Mode " + g.mode + "\n")
f.write("MyCall " + options.MyCall.get() + "\n")
f.write("MyGrid " + options.MyGrid.get() + "\n")
t=g.ftnstr(Audio.gcom2.hiscall)
if t[:1]==" ": t="______"
f.write("HisCall " + t + "\n")
t=g.ftnstr(Audio.gcom2.hisgrid)
if t=="      ": t="XX00xx"
f.write("HisGrid " + t + "\n")
#f.write("RxDelay " + str(options.RxDelay.get()) + "\n")
#f.write("TxDelay " + str(options.TxDelay.get()) + "\n")
f.write("IDinterval " + str(options.IDinterval.get()) + "\n")
f.write("PttPort " + str(options.PttPort.get()) + "\n")
f.write("Mileskm " + str(options.mileskm.get()) + "\n")
f.write("AudioOut " + options.DevoutName.get() + "\n")
f.write("SamFacOut " + str(options.samfacout.get()) + "\n")
if options.addpfx.get().lstrip()=="": options.addpfx.set("_")
f.write("AddPrefix " + options.addpfx.get().lstrip() + "\n")
if options.auxra.get()=="": options.auxra.set("0")
if options.auxdec.get()=="": options.auxdec.set("0")
f.write("AuxRA " + options.auxra.get() + "\n")
f.write("AuxDEC " + options.auxdec.get() + "\n")
f.write("nkeep " + str(options.nkeep.get()) + "\n")
f.write("dphi " + str(options.dphi.get()) + "\n")
f.write("fa " + str(options.fa.get()) + "\n")
f.write("fb " + str(options.fb.get()) + "\n")
f.write("fcal " + str(options.fcal.get()) + "\n")
f.write("SaveDir " + str(options.savedir.get()) + "\n")
f.write("TxFirst " + str(TxFirst.get()) + "\n")
f.write("KB8RQ " + str(kb8rq.get()) + "\n")
f.write("K2TXB " + str(k2txb.get()) + "\n")
f.write("SetSeq " + str(setseq.get()) + "\n")
f.write("Nsave " + str(nsave.get()) + "\n")
f.write("Band " + str(nfreq.get()) + "\n")
f.write("Sync " + str(isync) + "\n")
f.write("Clip " + str(iclip) + "\n")
f.write("Zap " + str(nzap.get()) + "\n")
f.write("NB " + str(nblank.get()) + "\n")
f.write("NAFC " + str(nafc.get()) + "\n")
f.write("NoSh441 " + str(nosh441.get()) + "\n")
f.write("NoShJT65 " + str(noshjt65.get()) + "\n")
f.write("NEME " + str(neme.get()) + "\n")
f.write("NDepth " + str(ndepth.get()) + "\n")
f.write("Debug " + str(ndebug.get()) + "\n")
f.write("Debug2 " + str(ndebug2.get()) + "\n")
mrudir2=mrudir.replace(" ","#")
f.write("MRUDir " + mrudir2 + "\n")
if g.astro_geom[:7]=="200x200": g.astro_geom="316x373" + g.astro_geom[7:]
f.write("AstroGeometry " + g.astro_geom + "\n")
f.close()

Audio.ftn_quit()
Audio.gcom1.ngo=0                         #Terminate audio streams
Audio.gcom2.lauto=0
Audio.gcom1.txok=0
time.sleep(0.5)
