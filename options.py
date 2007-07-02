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

mycall=Pmw.EntryField(g1.interior(),labelpos=W,label_text='My Call:',
        value='K1JT',entry_textvariable=MyCall,entry_width=12)
mygrid=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Grid Locator:',
        value='FN20qi',entry_textvariable=MyGrid,entry_width=12)
##rxdelay=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Rx Delay (s):',
##        value='0.2',entry_textvariable=RxDelay)
##txdelay=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Tx Delay (s):',
##        value='0.2',entry_textvariable=TxDelay)
idinterval=Pmw.EntryField(g1.interior(),labelpos=W,label_text='ID Interval (m):',
        value=10,entry_textvariable=IDinterval,entry_width=12)
comport=Pmw.EntryField(g1.interior(),labelpos=W,label_text='PTT Port:',
        value='/dev/ttyS0',entry_textvariable=PttPort,entry_width=12)
audioout=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Audio Out:',
        value='0',entry_textvariable=DevoutName,entry_width=12)
rateout=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Rate Out:',
        value=1.0000,entry_textvariable=samfacout,entry_width=12)
meas_rateout=Pmw.EntryField(g1.interior(),labelpos=W,label_text='Actual:',
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

#g3=Pmw.Group(root)
g3=Pmw.Group(root,tag_text="Miscellaneous")
temp_prefix=Pmw.EntryField(g3.interior(),labelpos=W,label_text='DXCC prefix:',
    entry_width=9,entry_textvariable=addpfx)
aux_ra=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Source RA:',
    entry_width=9,entry_textvariable=auxra)
aux_dec=Pmw.EntryField(g3.interior(),labelpos=W,label_text='Source DEC:',
    entry_width=9,entry_textvariable=auxdec)
widgets = (temp_prefix,aux_ra,aux_dec)
for widget in widgets:
    widget.pack(padx=10,pady=2)
Pmw.alignlabels(widgets)

g1.pack(side=LEFT,fill=BOTH,expand=1,padx=6,pady=6)
g3.pack(side=LEFT,fill=BOTH,expand=1,padx=6,pady=6)

