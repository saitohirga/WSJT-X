#------------------------------------------------------ options
from Tkinter import *
import Pmw
import g

def done():
    root.withdraw()

root=Toplevel()
root.withdraw()
root.protocol('WM_DELETE_WINDOW',done)
if g.Win32: root.iconbitmap("wsjt.ico")
root.title("Options")

def options2(t):
    root.geometry(t)
    root.deiconify()
    root.focus_set()

#-------------------------------------------------------- Create GUI widgets
g1=Pmw.Group(root,tag_text="Station parameters")
MyCall=StringVar()
MyGrid=StringVar()
#RxDelay=StringVar()
#TxDelay=StringVar()
IDinterval=IntVar()
ComPort=IntVar()
PttPort=StringVar()
ndevin=IntVar()
ndevout=IntVar()
DevinName=StringVar()
DevoutName=StringVar()
forceFcenter=DoubleVar()
samfacin=DoubleVar()
samfacout=DoubleVar()
Template1=StringVar()
Template2=StringVar()
Template3=StringVar()
Template4=StringVar()
Template5=StringVar()
Template6=StringVar()
addpfx=StringVar()
auxra=StringVar()
auxdec=StringVar()
nkeep=IntVar()
dphi=IntVar()
fa=IntVar()
fb=IntVar()
fcal=IntVar()
ncsmin=IntVar()
nt1=IntVar()
savedir=StringVar()
azeldir=StringVar()

mycall=Pmw.EntryField(g1.interior(),labelpos=W,label_text='My Call:',
        value='K1JT',entry_textvariable=MyCall,entry_width=12)
mygrid=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Grid Locator:',
        value='FN20qi',entry_textvariable=MyGrid,entry_width=12)
##rxdelay=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Rx Delay (s):',
##        value='0.2',entry_textvariable=RxDelay)
##txdelay=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Tx Delay (s):',
##        value='0.2',entry_textvariable=TxDelay)
idinterval=Pmw.EntryField(g1.interior(),labelpos=W,label_text='ID Interval (m):',
        value=10,validate={'validator':'numeric','min':0,'max':60}, \
        entry_textvariable=IDinterval,entry_width=12)
comport=Pmw.EntryField(g1.interior(),labelpos=W,label_text='PTT Port:',
        value='/dev/ttyS0',entry_textvariable=PttPort,entry_width=12)
audioout=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Audio Out:',
        value='0',entry_textvariable=DevoutName,entry_width=12)
rateout=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Rate Out:',
        value=1.0000,entry_textvariable=samfacout,entry_width=12)
meas_rateout=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Measured:',
        value=1.0000,entry_width=12)
#widgets = (mycall, mygrid, rxdelay,txdelay,idinterval,comport,audioin,audioout)
widgets = (mycall, mygrid,idinterval,comport,audioout,rateout,meas_rateout)
for widget in widgets:
    widget.pack(fill=X,expand=1,padx=10,pady=2)

Pmw.alignlabels(widgets)
mycall.component('entry').focus_set()
f1=Frame(g1.interior(),width=100,height=20)
mileskm=IntVar()
Label(f1,text='Distance unit:').pack(side=LEFT)
rb5=Radiobutton(f1,text='mi',value=0,variable=mileskm)
rb6=Radiobutton(f1,text='km',value=1,variable=mileskm)
rb5.pack(anchor=W,side=LEFT,padx=2,pady=2)
rb6.pack(anchor=W,side=LEFT,padx=2,pady=2)
f1.pack()

f2=Frame(g1.interior(),width=100,height=20)
xant=IntVar()
Label(f2,text='Antennas:  ').pack(side=LEFT)
rb7=Radiobutton(f2,text='+ ',value=0,variable=xant)
rb8=Radiobutton(f2,text='x',value=1,variable=xant)
rb7.pack(anchor=W,side=LEFT,padx=2,pady=2)
rb8.pack(anchor=W,side=LEFT,padx=2,pady=2)
f2.pack()

#g3=Pmw.Group(root)
g3=Pmw.Group(root,tag_text="Miscellaneous")
temp_prefix=Pmw.EntryField(g3.interior(),labelpos=W,label_text='DXCC prefix:',
    entry_width=9,entry_textvariable=addpfx)
aux_ra=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Source RA:',
    entry_width=9,entry_textvariable=auxra)
aux_dec=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Source DEC:',
    entry_width=9,entry_textvariable=auxdec)
nkeep_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Timeout (min):',
    entry_width=9,value=20,entry_textvariable=nkeep)
dphi_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Dphi (deg):',
    entry_width=9,entry_textvariable=dphi)
fa_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Fmin (kHz):',
    entry_width=9,value=100,entry_textvariable=fa)
fb_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Fmax (kHz):',
    entry_width=9,value=160,entry_textvariable=fb)
fcal_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Fcal (Hz):',
    entry_width=9,entry_textvariable=fcal)
min_callsign_entry=Pmw.EntryField(g3.interior(),labelpos=W, \
    label_text='CSmin:',entry_width=9,value=4,entry_textvariable=ncsmin)
nt1_entry=Pmw.EntryField(g3.interior(),labelpos=W, \
    label_text='Rx t1:',entry_width=9,value=48,entry_textvariable=nt1)
forceFreq_entry=Pmw.EntryField(g3.interior(),labelpos=W, \
    label_text='Force Fcenter:',entry_width=9,value=0,entry_textvariable=forceFcenter)
savedir_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='SaveDir:',
    entry_width=23,value=g.appdir+'\save',entry_textvariable=savedir)
azeldir_entry=Pmw.EntryField(g3.interior(),labelpos=W,label_text='AzElDir:',
    entry_width=23,value=g.appdir,entry_textvariable=azeldir)
widgets = (temp_prefix,aux_ra,aux_dec,nkeep_entry,dphi_entry, \
           fa_entry,fb_entry,fcal_entry,min_callsign_entry, \
           nt1_entry,forceFreq_entry,savedir_entry,azeldir_entry,)
for widget in widgets:
    widget.pack(padx=2,pady=2)
Pmw.alignlabels(widgets)

g1.pack(side=LEFT,fill=BOTH,expand=1,padx=6,pady=6)
g3.pack(side=LEFT,fill=BOTH,expand=1,padx=6,pady=6)

