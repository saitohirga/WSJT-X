#---------------------------------------------------- SpecJT
from Tkinter import *
from tkMessageBox import showwarning
import time
import os
import Pmw
import smeter
import Audio
import g
import string
import cPickle
#import Numeric
from Numeric import zeros, multiarray
import Image, ImageTk, ImageDraw
from palettes import colormapblue, colormapgray0, colormapHot, \
     colormapAFMHot, colormapgray1, colormapLinrad, Colormap2Palette
#import wsjt                         #Is this OK to do?

def hidespecjt():
    root.withdraw()
    g.showspecjt=0
def showspecjt():
    root.deiconify()
    g.showspecjt=2
    g.focus=1

if(__name__=="__main__"):
    root = Tk()
else:
    root=Toplevel()
    root.protocol('WM_DELETE_WINDOW',hidespecjt)
    
root.withdraw()

#-------------------------------------------  Define globals and initialize.
b0=0
c0=0
g0=0
g.cmap="Linrad"
df=2.69165
fmid=1500
fmid0=1500
frange=2000
frange0=2000
isec0=-99
logmap=IntVar()
logmap.set(0)
logm0=0
minsep=IntVar()
mode0=""
mousedf0=0
naxis=IntVar()
ncall=0
newMinute=0
nflat=IntVar()
nfr=IntVar()
nfr.set(1)
nfreeze0=0
nmark=IntVar()
nmark0=0
nn=0
npal=IntVar()
npal.set(2)
nscroll=0
nspeed0=IntVar()
nspeed00=99
root_geom=""
t0=""
tol0=400
ttot=0.0

c=Canvas()
a=zeros(225000,'s')
im=Image.new('P',(750,300))
line0=Image.new('P',(750,1))      #Image fragment for top line of waterfall
draw=ImageDraw.Draw(im)
pim=ImageTk.PhotoImage(im)
balloon=Pmw.Balloon(root)

def pal_gray0():
    g.cmap="gray0"
    im.putpalette(Colormap2Palette(colormapgray0),"RGB")
def pal_gray1():
    g.cmap="gray1"
    im.putpalette(Colormap2Palette(colormapgray1),"RGB")
def pal_linrad():
    g.cmap="Linrad"
    im.putpalette(Colormap2Palette(colormapLinrad),"RGB")
def pal_blue():
    g.cmap="blue"
    im.putpalette(Colormap2Palette(colormapblue),"RGB")
def pal_Hot():
    g.cmap="Hot"
    im.putpalette(Colormap2Palette(colormapHot),"RGB")
def pal_AFMHot():
    g.cmap="AFMHot"
    im.putpalette(Colormap2Palette(colormapAFMHot),"RGB")

#--------------------------------------------------- Command button routines
#--------------------------------------------------- rx_volume
def rx_volume():
    for path in string.split(os.environ["PATH"], os.pathsep):
        file = os.path.join(path, "sndvol32") + ".exe"
        try:
            return os.spawnv(os.P_NOWAIT, file, (file,) + (" -r",))
        except os.error:
            pass
    raise os.error, "Cannot find "+file

#--------------------------------------------------- tx_volume
def tx_volume():
    for path in string.split(os.environ["PATH"], os.pathsep):
        file = os.path.join(path, "sndvol32") + ".exe"
        try:
            return os.spawnv(os.P_NOWAIT, file, (file,))
        except os.error:
            pass
    raise os.error, "Cannot find "+file

#---------------------------------------------------- fdf_change
# Readout of graphical cursor location
def fdf_change(event):
    if nspeed0.get()<6:
        g.DFreq=df*(event.x-288.7) + fmid - 1500
        if nfr.get()==2: g.DFreq=2*df*(event.x-375.5) + fmid - 1270.5
        g.Freq=g.DFreq+1270.46
        t="Freq: %5d    DF: %5d  (Hz)" % (int(g.Freq),int(g.DFreq))
    else:
        g.PingTime=0.04*event.x
        g.PingFreq=(121-event.y)*21.533
        g.PingFile="current"
        if event.y > 150:
            g.PingFile="previous"
            g.PingFreq=(271-event.y)*21.533
        if g.PingFreq<400: g.PingFreq=0
        t="Time: %4.1f s %s  Freq: %d Hz" % (g.PingTime,g.PingFile,g.PingFreq)
    fdf.configure(text=t)

#---------------------------------------------------- set_freezedf
def set_freezedf(event):
    if g.mode[:4]=='JT65':
        n=int(df*(event.x-288.7) + fmid - 1500)
        if nfr.get()==2: n=int(2*df*(event.x-375.5) + fmid - 1270.5)
#        if n<-600: n=-600
#        if n>600:  n=600
        if n<-1270: n=-1270
        if n>3800: n=3800
        Audio.gcom2.mousedf=n
    else:
        decode_request(event)

#------------------------------------------------------ ftnstr
def ftnstr(x):
    y=""
    for i in range(len(x)):
        y=y+x[i]
    return y

#---------------------------------------------------- df_mark
def df_mark():
    draw_axis()
    if nmark.get()==0 or Audio.gcom2.nfreeze:
        fstep=10.0*11025.0/4096.0
        if g.mode[4:5]=='B': fstep=2*fstep
        if g.mode[4:5]=='C': fstep=4*fstep

# Mark sync tone and top JT65 tone (green) and shorthand tones (red)
        if(frange==2000):
            dx=288.7 + (1500-fmid)/df
            if g.mode[:4]=="JT65":
                color='green'
                x1=(Audio.gcom2.mousedf + 6.6*fstep)/df + dx
                c.create_line(x1-0.5,25,x1-0.5,12,fill=color)
                c.create_line(x1+0.5,25,x1+0.5,12,fill=color)
                for i in range(5):
                    x1=(Audio.gcom2.mousedf + i*fstep)/df + dx
                    j=12
                    if i>0: j=15
                    if i!=1: c.create_line(x1-0.5,25,x1-0.5,j,fill=color)
                    if i!=1: c.create_line(x1+0.5,25,x1+0.5,j,fill=color)
                    color='red'
        if(frange==4000):
            dx=375 + (1270.5-fmid)/(2*df)
            if g.mode[:4]=="JT65":
                color='green'
                x1=(Audio.gcom2.mousedf + 6.6*fstep)/(2*df) + dx
                c.create_line(x1-0.5,25,x1-0.5,12,fill=color)
                c.create_line(x1+0.5,25,x1+0.5,12,fill=color)
                for i in range(5):
                    x1=(Audio.gcom2.mousedf + i*fstep)/(2*df) + dx
                    j=12
                    if i>0: j=15
                    if i!=1: c.create_line(x1-0.5,25,x1-0.5,j,fill=color)
                    if i!=1: c.create_line(x1+0.5,25,x1+0.5,j,fill=color)
                    color='red'

#---------------------------------------------------- change_fmid
def change_fmid1():
    global fmid
    fmid=fmid+100
    if fmid>5000-1000*nfr.get(): fmid=5000-1000*nfr.get()

def change_fmid2():
    global fmid
    fmid=fmid-100
    if fmid<1000*nfr.get(): fmid=1000*nfr.get()

def set_fmid():
    global fmid
    if nfr.get()==1: fmid=1200
    if nfr.get()==2: fmid=2200

#---------------------------------------------------- freq_range
def freq_range(event):
# Move frequency scale left or right in 100 Hz increments
    global fmid
    if event.num==1:
        fmid=fmid+100
    else:
        if event.num==3:
            fmid=fmid-100
    if fmid<1000*nfr.get(): fmid=1000*nfr.get()
    if fmid>5000-1000*nfr.get(): fmid=5000-1000*nfr.get()

def set_frange():
    nfr.set(3-nfr.get())

#---------------------------------------------------- freq_center
##def freq_center(event):
### Move clicked location to center of frequency scale
##    global fmid,frange
##    n=100*int(0.01*df*(event.x-375))
##    fmid = fmid + n
##    if fmid<1000: fmid=1000
##    if fmid>1700: fmid=1700

#---------------------------------------------------- decode_request
def decode_request(event):
    if g.mode[:4]!='JT65' and nspeed0.get()>5:
# If decoder is busy or we are not monitoring, ignore request
        if Audio.gcom2.ndecoding==0 and Audio.gcom2.monitoring:
            Audio.gcom2.mousebutton=event.num       #Left=1, Right=3
            Audio.gcom2.npingtime=int(40*event.x)   #Time (ms) of selected ping
            if event.y <= 150:
                Audio.gcom2.ndecoding=2             #Mouse pick, top half
            else:
                Audio.gcom2.ndecoding=3             #Mouse pick, bottom half

#---------------------------------------------------- freeze_decode
def freeze_decode(event):
    if g.mode[:4]=='JT65' and nspeed0.get()<6:
# If decoder is busy or we are not monitoring, ignore request
        if Audio.gcom2.ndecoding==0 or Audio.gcom2.monitoring==0:
            set_freezedf(event)
            g.freeze_decode=1

#---------------------------------------------------- update
def update():
    global a,b0,c0,g0,im,isec0,line0,newMinute,nscroll,nspeed00,pim, \
           root_geom,t0,mousedf0,nfreeze0,tol0,mode0,nmark0,logm0, \
           fmid,fmid0,frange,frange0
    
    utc=time.gmtime(time.time()+0.1*Audio.gcom1.ndsec)
    isec=utc[5]

    if isec != isec0:                           #Do once per second
        isec0=isec
        t0=time.strftime('%H:%M:%S',utc)
        ltime.configure(text=t0)
        root_geom=root.geometry()
        g.rms=Audio.gcom1.rms
        if isec==0: nscroll=0
        if isec==59: newMinute=1

    if g.showspecjt==1:
        showspecjt()
    nspeed=nspeed0.get()                        #Waterfall update rate
    if (nspeed<6 and nspeed00>=6) or (nspeed>=6 and nspeed00<6):
        draw_axis()
    nspeed00=nspeed

    brightness=sc1.get()
    contrast=sc2.get()
    logm=logmap.get()
    g0=sc3.get()
    
# Don't calculate spectra for waterfall while decoding
    if Audio.gcom2.ndecoding==0 and \
           (Audio.gcom2.monitoring or Audio.gcom2.ndiskdat):
        Audio.spec(brightness,contrast,logm,g0,nspeed,a) #Call Fortran routine spec
        newdat=Audio.gcom1.newdat                   #True if new data available
    else:
        newdat=0

    sm.updateProgress(newValue=Audio.gcom1.level) #S-meter bar
    if newdat or brightness!=b0 or contrast!=c0 or logm!=logm0:
        if brightness==b0 and contrast==c0 and logm==logm0 and nspeed<6:
            n=Audio.gcom2.nlines
            box=(0,0,750,300-n)                 #Define region
            region=im.crop(box)                 #Get all but last line(s)
            try:
                im.paste(region,(0,n))          #Move waterfall down
            except:
                print "Images did not match, continuing anyway."
            for i in range(n):
                line0.putdata(a[750*i:750*(i+1)])   #One row of pixels to line0
                im.paste(line0,(0,i))               #Paste in new top line
            nscroll=nscroll+n
        else:                                   #A scale factor has changed
            im.putdata(a)                       #Compute whole new image
            b0=brightness                       #Save scale values
            c0=contrast
            logm0=logm

    if newdat:
        if Audio.gcom2.monitoring:
            if minsep.get() and newMinute:
                draw.line((0,0,749,0),fill=128)     #Draw the minute separator
            if nscroll == 13:
                draw.text((5,2),t0[0:5],fill=253)   #Insert time label
        else:
            if minsep.get():
                draw.line((0,0,749,0),fill=128)     #Draw the minute separator

        pim=ImageTk.PhotoImage(im)              #Convert Image to PhotoImage
        graph1.delete(ALL)
        #For some reason, top two lines are invisible, so we move down 2
        graph1.create_image(0,0+2,anchor='nw',image=pim)

        if nspeed>5:
            color="white"
            if g.cmap=="gray1": color="black"
            t=time.strftime("%H:%M:%S",time.gmtime(Audio.gcom2.ntime + \
                0.1*Audio.gcom1.ndsec))
            graph1.create_text(5,110,anchor=W,text=t,fill=color)
            t=g.filetime(g.ftnstr(Audio.gcom2.fnamea))
            graph1.create_text(5,260,anchor=W,text=t,fill=color)

        newMinute=0

    if (Audio.gcom2.mousedf != mousedf0 or Audio.gcom2.dftolerance != tol0) \
            and g.mode[:4]=='JT65':
        df_mark()
        
# The following int() calls are to ensure that the values copied to
# mousedf0 and tol0 are static.
        mousedf0=int(Audio.gcom2.mousedf)
        tol0=int(Audio.gcom2.dftolerance)

    if Audio.gcom2.nfreeze != nfreeze0:
        if not Audio.gcom2.nfreeze: draw_axis()
        if Audio.gcom2.nfreeze: df_mark()
        nfreeze0=int(Audio.gcom2.nfreeze)

    if g.mode!=mode0:
        if g.mode[:4]=="JT65" and nspeed0.get()>5: nspeed0.set(3)
        if g.mode=="FSK441" and nspeed0.get()<6: nspeed0.set(6)
        if g.mode=="JT6M" and nspeed0.get()<6: nspeed0.set(6)
        draw_axis()
        mode0=g.mode

    if nmark.get()!=nmark0:
        df_mark()
        nmark0=nmark.get()

    if newdat: Audio.gcom2.ndiskdat=0
    Audio.gcom2.nlines=0
    Audio.gcom2.nflat=nflat.get()
    frange=nfr.get()*2000
    if(fmid<>fmid0 or frange<>frange0):
        if fmid<1000*nfr.get(): fmid=1000*nfr.get()
        if fmid>5000-1000*nfr.get(): fmid=5000-1000*nfr.get()
        draw_axis()
        fmid0=fmid
        frange0=frange
    Audio.gcom2.nfmid=int(fmid)
    Audio.gcom2.nfrange=int(frange)

    if g.focus==2:
        root.focus_set()
    ltime.after(200,update)                      #Reset the timer

#-------------------------------------------------------- draw_axis
def draw_axis():
    xmid=fmid
    if naxis.get(): xmid=xmid-1270.46
    c.delete(ALL)
    if nspeed0.get()<6:
# Draw the frequency or DF tick marks
        if(frange==2000):
            for ix in range(-1300,5001,20):
                i=374.5 + (ix-xmid)/df
                j=20
                if (ix%100)==0 :
                    j=16
                    x=i-2
                    if ix<1000 : x=x+2
                    y=8
                    c.create_text(x,y,text=str(ix))
                c.create_line(i,25,i,j,fill='black')

        if(frange==4000):
            for ix in range(-2600,5401,50):
                i=374.5 + (ix-xmid)/(2*df)
                j=20
                if (ix%200)==0 :
                    j=16
                    x=i-2
                    if ix<1000 : x=x+2
                    y=8
                    c.create_text(x,y,text=str(ix))
                c.create_line(i,25,i,j,fill='black')
                
        if g.mode[:4]=="JT65":
            dx=288.7 + (1500-fmid)/df
            dff=df
            if frange==4000:
                dx=375 + (1270.5-fmid)/(2*df)
                dff=2*df
            if Audio.gcom2.nfreeze==0:
#                x1=-600/dff + dx
#                x2=600/dff + dx
                x1=0
                x2=749
            else:
                tol=Audio.gcom2.dftolerance    
                x1=(Audio.gcom2.mousedf-tol)/dff + dx
                x2=(Audio.gcom2.mousedf+tol)/dff + dx
            c.create_line(x1,25,x2,25,fill='green',width=2)
            
    else:
        for ix in range(1,31):
            i=25*ix
            j=20
            if (ix%5)==0:
                j=16
                x=i
                if x==750: x=745
                c.create_text(x,8,text=str(ix))
            c.create_line(i,25,i,j,fill='black')

#-------------------------------------------------------- Create GUI widgets

#-------------------------------------------------------- Menu bar
frame = Frame(root)
frame.pack()

mbar = Frame(frame)
mbar.pack(fill=X)

#--------------------------------------------------------- Options menu
setupbutton = Menubutton(mbar, text = 'Options', )
setupbutton.pack(side = LEFT)
setupmenu = Menu(setupbutton, tearoff=1)
setupbutton['menu'] = setupmenu
setupmenu.add_checkbutton(label = 'Mark T/R boundaries',variable=minsep)
setupmenu.add_checkbutton(label='Flatten spectra',variable=nflat)
setupmenu.add_checkbutton(label='Mark JT65 tones only if Freeze is checked',
            variable=nmark)
setupmenu.add_separator()
setupmenu.add('command', label = 'Rx volume control', command = rx_volume)
setupmenu.add('command', label = 'Tx volume control', command = tx_volume)
setupmenu.add_separator()
setupmenu.add_radiobutton(label='Frequency axis',command=draw_axis,
            value=0,variable=naxis)
setupmenu.add_radiobutton(label='JT65 DF axis',command=draw_axis,
            value=1,variable=naxis)
setupmenu.add_separator()
setupmenu.palettes=Menu(setupmenu,tearoff=0)
setupmenu.palettes.add_radiobutton(label='Gray0',command=pal_gray0,
            value=0,variable=npal)
setupmenu.palettes.add_radiobutton(label='Gray1',command=pal_gray1,
            value=1,variable=npal)
setupmenu.palettes.add_radiobutton(label='Linrad',command=pal_linrad,
            value=2,variable=npal)
setupmenu.palettes.add_radiobutton(label='Blue',command=pal_blue,
            value=3,variable=npal)
setupmenu.palettes.add_radiobutton(label='Hot',command=pal_Hot,
            value=4,variable=npal)
setupmenu.palettes.add_radiobutton(label='AFMHot',command=pal_AFMHot,
            value=5,variable=npal)
setupmenu.add_cascade(label = 'Palette',menu=setupmenu.palettes)

lab1=Label(mbar,padx=40,bd=0)
lab1.pack(side=LEFT)
fdf=Label(mbar,width=20,bd=0,padx=20)
fdf.pack(side=LEFT)

lab3=Label(mbar,padx=13,bd=0)
lab3.pack(side=LEFT)
bbw=Button(mbar,text='BW',command=set_frange,padx=1,pady=1)
bbw.pack(side=LEFT)

lab0=Label(mbar,padx=5,bd=0)
lab0.pack(side=LEFT)
bfmid1=Button(mbar,text='<',command=change_fmid1,padx=1,pady=1)
bfmid2=Button(mbar,text='>',command=change_fmid2,padx=1,pady=1)
bfmid3=Button(mbar,text='|',command=set_fmid,padx=3,pady=1)
bfmid1.pack(side=LEFT)
bfmid3.pack(side=LEFT)
bfmid2.pack(side=LEFT)

#------------------------------------------------- Speed selection buttons
for i in (7, 6, 5, 4, 3, 2, 1):
    t=str(i)
    if i==6: t="H1"
    if i==7: t="H2"
    Radiobutton(mbar,text=t,value=i,variable=nspeed0).pack(side=RIGHT)
nspeed0.set(6)
lab2=Label(mbar,text='Speed: ',bd=0)
lab2.pack(side=RIGHT)
#------------------------------------------------- Graphics frame
iframe1 = Frame(frame, bd=1, relief=SUNKEN)
c=Canvas(iframe1, bg='white', width=750, height=25,bd=0)
c.pack(side=TOP)
Widget.bind(c,"<Shift-Button-1>",freq_range)
Widget.bind(c,"<Shift-Button-2>",freq_range)
Widget.bind(c,"<Shift-Button-3>",freq_range)
#Widget.bind(c,"<Control-Button-1>",freq_center)

graph1=Canvas(iframe1, bg='black', width=750, height=300,bd=0,cursor='crosshair')
graph1.pack(side=TOP)
Widget.bind(graph1,"<Motion>",fdf_change)
#Widget.bind(graph1,"<Button-1>",decode_request)
Widget.bind(graph1,"<Button-3>",decode_request)
Widget.bind(graph1,"<Button-1>",set_freezedf)
Widget.bind(graph1,"<Double-Button-1>",freeze_decode)
iframe1.pack(expand=1, fill=X)

#-------------------------------------------------- Status frame
iframe2 = Frame(frame, bd=1, relief=SUNKEN)
status=Pmw.MessageBar(iframe2,entry_width=17,entry_relief=GROOVE)
status.pack(side=LEFT)
sc1=Scale(iframe2,from_=-100.0,to_=100.0,orient='horizontal',
    showvalue=0,sliderlength=5)
sc1.pack(side=LEFT)
sc2=Scale(iframe2,from_=-100.0,to_=100.0,orient='horizontal',
    showvalue=0,sliderlength=5)
sc2.pack(side=LEFT)
balloon.bind(sc1,"Brightness", "Brightness")
balloon.bind(sc2,"Contrast", "Contrast")
balloon.configure(statuscommand=status.helpmessage)
ltime=Label(iframe2,bg='black',fg='yellow',width=8,bd=2,font=('Helvetica',16))
ltime.pack(side=LEFT)
msg1=Label(iframe2,padx=2,bd=2,text=" ")
msg1.pack(side=LEFT)
sc3=Scale(iframe2,from_=-100.0,to_=100.0,orient='horizontal',
    showvalue=0,sliderlength=5)
sc3.pack(side=LEFT)
balloon.bind(sc3,"Gain", "Digital Gain")
sm=smeter.Smeter(iframe2,fillColor='slateblue',width=150,
    doLabel=1)
sm.frame.pack(side=RIGHT)
balloon.bind(sm.frame,"Rx noise level","Rx noise level")
iframe2.pack(expand=1, fill=X)

#----------------------------------------------- Restore params from INI file
try:
    f=open('WSJT.INI',mode='r')
    params=f.readlines()
except:
    params=""

try:
    for i in range(len(params)):
        key,value=params[i].split()
        if   key == 'SpecJTGeometry': root.geometry(value)
        elif key == 'UpdateInterval': nspeed0.set(value)
        elif key == 'Brightness': sc1.set(value)
        elif key == 'Contrast': sc2.set(value)
        elif key == 'DigitalGain': sc3.set(value)
        elif key == 'MinuteSeparators': minsep.set(value)
        elif key == 'AxisLabel': naxis.set(value)
        elif key == 'MarkTones': nmark.set(value)
        elif key == 'Flatten': nflat.set(value)
        elif key == 'LogMap': logmap.set(value)
        elif key == 'Palette': g.cmap=value
        elif key == 'Frange': nfr.set(value)
        elif key == 'Fmid': fmid=int(value)
        else: pass
except:
    print 'Error reading WSJT.INI, continuing with defaults.'
    print key,value
        
#------------------------------------------------------  Select palette
if g.cmap == "gray0":
    pal_gray0()
    npal.set(0)
if g.cmap == "gray1":
    pal_gray1()
    npal.set(1)
if g.cmap == "Linrad":
    pal_linrad()
    npal.set(2)
if g.cmap == "blue":
    pal_blue()
    npal.set(3)
if g.cmap == "Hot":
    pal_Hot()
    npal.set(4)
if g.cmap == "AFMHot":
    pal_AFMHot()
    npal.set(5)

#---------------------------------------------- Display GUI and start mainloop
draw_axis()
try:
    ndevin=g.ndevin.get()
except:
    ndevin=0
Audio.gcom1.ndevin=ndevin

try:
    ndevout=g.ndevout.get()
except:
    ndevout=0
Audio.gcom1.ndevout=ndevout
						# Only valid for windows
                                                # for now
Audio.audio_init(ndevin,ndevout)                #Start the audio stream

ltime.after(200,update)

root.deiconify()
g.showspecjt=2
if g.Win32: root.iconbitmap("wsjt.ico")
root.title('  SpecJT     by K1JT')
if(__name__=="__main__"):
    Audio.gcom2.monitoring=1
root.mainloop()

#-------------------------------------------------- Save user params and quit
f=open('WSJT.INI',mode='w')
f.write("UpdateInterval " + str(nspeed0.get()) + "\n")
f.write("Brightness " + str(b0)+ "\n")
f.write("Contrast " + str(c0)+ "\n")
f.write("DigitalGain " + str(g0)+ "\n")
f.write("MinuteSeparators " + str(minsep.get()) + "\n")
f.write("AxisLabel " + str(naxis.get()) + "\n")
f.write("MarkTones " + str(nmark.get()) + "\n")
f.write("Flatten " + str(nflat.get()) + "\n")
f.write("LogMap " + str(logmap.get()) + "\n")
f.write("Palette " + g.cmap + "\n")
f.write("Frange " + str(nfr.get()) + "\n")
f.write("Fmid " + str(fmid) + "\n")
root_geom=root_geom[root_geom.index("+"):]
f.write("SpecJTGeometry " + root_geom + "\n")
f.close()

