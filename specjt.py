#----------------------------------------------------- SpecJT
from Tkinter import *
from tkMessageBox import showwarning
import time
import os
import Pmw
import Audio
import g
import string
import cPickle
#from Numeric import zeros, multiarray
import numpy
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
g.cmap0="Linrad"
bw=96.0
df=2.69165
fmid=1500
fmid0=1500
frange=2000
frange0=2000
isec0=-99
mode0=""
mousedf0=0
mousefqso0=0
dftolerance0=500
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
root_geom=""
t0=""
tol0=400
ttot=0.0

c=Canvas()
NX=750
NY=130
#a=zeros(NX*NY,'s')
a=numpy.zeros(NX*NY,numpy.int16)
im=Image.new('P',(NX,NY))
line0=Image.new('P',(NX,1))  #Image fragment for top line of waterfall
draw=ImageDraw.Draw(im)
pim=ImageTk.PhotoImage(im)

#a2=zeros(NX*NY,'s')
a2=numpy.zeros(NX*NY,numpy.int16)
im2=Image.new('P',(NX,NY))
line02=Image.new('P',(NX,1)) #Image fragment for top line of zoomed waterfall
draw2=ImageDraw.Draw(im2)
pim2=ImageTk.PhotoImage(im2)
balloon=Pmw.Balloon(root)

def pal_gray0():
    g.cmap="gray0"
    im.putpalette(Colormap2Palette(colormapgray0),"RGB")
    im2.putpalette(Colormap2Palette(colormapgray0),"RGB")
def pal_gray1():
    g.cmap="gray1"
    im.putpalette(Colormap2Palette(colormapgray1),"RGB")
    im2.putpalette(Colormap2Palette(colormapgray1),"RGB")
def pal_linrad():
    g.cmap="Linrad"
    im.putpalette(Colormap2Palette(colormapLinrad),"RGB")
    im2.putpalette(Colormap2Palette(colormapLinrad),"RGB")
def pal_blue():
    g.cmap="blue"
    im.putpalette(Colormap2Palette(colormapblue),"RGB")
    im2.putpalette(Colormap2Palette(colormapblue),"RGB")
def pal_Hot():
    g.cmap="Hot"
    im.putpalette(Colormap2Palette(colormapHot),"RGB")
    im2.putpalette(Colormap2Palette(colormapHot),"RGB")
def pal_AFMHot():
    g.cmap="AFMHot"
    im.putpalette(Colormap2Palette(colormapAFMHot),"RGB")
    im2.putpalette(Colormap2Palette(colormapAFMHot),"RGB")

#--------------------------------------------------- Command button routines

#---------------------------------------------------- fdf_change
# Readout of graphical cursor location
def fdf_change(event):
    global bw
    fmid=0.5*float(Audio.gcom2.nfb + Audio.gcom2.nfa)
    if Audio.gcom2.nfullspec:  fmid=125.0 - 2.2         #Empirical
    df=bw/NX                                   #kHz per pixel
    g.Freq=df*(event.x-375) + fmid
    n=int(g.Freq+0.5)
    t="%d" % (n,)
    if g.fc[n] != "":
        t=t + ":  " + g.fc[n]
    fdf.configure(text=t)

def fdf_change2(event):
    g.DFreq=(2200.0/750.0)*(event.x-375)

#---------------------------------------------------- set_fqso
def set_fqso(event):
    n=int(g.Freq + 0.5)
    Audio.gcom2.mousefqso=n
    df_mark()

#---------------------------------------------------- set_freezedf
def set_freezedf(event):
    n=int(g.DFreq + 0.5)
    Audio.gcom2.mousedf=n
    df_mark()

#------------------------------------------------------ ftnstr
def ftnstr(x):
    y=""
    for i in range(len(x)):
        y=y+x[i]
    return y

#---------------------------------------------------- df_mark
def df_mark():
    global bw
    draw_axis()
# Mark QSO freq in top graph
    color='green'
    fmid=0.5*float(Audio.gcom2.nfb + Audio.gcom2.nfa)
    if Audio.gcom2.nfullspec: fmid=125.0 - 2.3      #Empirical    
    df=bw/NX                                #kHz per pixel
    x1=375.0 + (Audio.gcom2.mousefqso-fmid)/df    
    c.create_line(x1,25,x1,12,fill=color,width=2)
    if Audio.gcom2.nfullspec:
        x1=375.0 + (Audio.gcom2.nfa-fmid)/df
        x2=375.0 + (Audio.gcom2.nfb-fmid)/df
        c.create_line(x1,25,x2,25,fill=color,width=2)

    df=96000.0/32768.0
# Mark sync tone and top JT65 tone (green) and shorthand tones (red)
    fstep=20.0*11025.0/4096.0
    x1=375.0 + (Audio.gcom2.mousedf + 6.6*fstep)/df
    c2.create_line(x1,25,x1,12,fill=color,width=2)
    x1=375.0 + (Audio.gcom2.mousedf - Audio.gcom2.dftolerance)/df
    x2=375.0 + (Audio.gcom2.mousedf + Audio.gcom2.dftolerance)/df
    c2.create_line(x1,25,x2,25,fill=color,width=2)
    for i in range(5):
        x1=375.0 + (Audio.gcom2.mousedf + i*fstep)/df
        j=12
        if i>0: j=15
        if i!=1: c2.create_line(x1,25,x1,j,fill=color,width=2)
        color='red'

#-------------------------------------------------------- draw_axis
def draw_axis():
    c.delete(ALL)
    xdf=bw/NX                                   #kHz per pixel
    xmid=0.5*float(Audio.gcom2.nfb + Audio.gcom2.nfa)
    if Audio.gcom2.nfullspec:
        xmid=125.0 - 2.3                        #Empirical    
    x1=int(xmid-0.6*bw)                         #Make it too wide, to be
    x2=int(xmid+0.6*bw)                         #sure to get all the numbers
    ilab=10
    if bw <= 60.0: ilab=5
    if bw <= 30.0: ilab=2
    for ix in range(x1,x2,1):
        i=0.5*NX + (ix-xmid)/xdf
        j=20
        if (ix%5)==0: j=16
        if (ix%ilab)==0 :
            j=16
            x=i-1
            if ix<100: x=x+1
            y=8
            c.create_text(x,y,text=str(ix))
        c.create_line(i,25,i,j,fill='black')     #Draw the upper scale
            
    c2.delete(ALL)
    xmid2=0
    bw2=750.0*96000.0/32768.0                     #approx 2197.27 Hz
    x1=int(xmid-0.5*bw2)/100 - 1
    x1=100*x1
    x2=int(xmid+0.5*bw2)
    xdf2=bw2/NX
    for ix in range(x1,x2,20):
        i=0.5*NX + (ix-xmid2)/xdf2
        j=20
#        if (ix%5)==0: j=16
        if (ix%100)==0 :
            j=16
            x=i-1
            if ix<1000: x=x+2
            if ix<0: x=x-2
            y=8
            c2.create_text(x,y,text=str(ix))
        c2.create_line(i,25,i,j,fill='black')


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

#---------------------------------------------------- freeze_decode1
def freeze_decode1(event):
# If decoder is busy or we are not monitoring, ignore request
    if Audio.gcom2.ndecoding==0 or Audio.gcom2.monitoring==0:
        set_fqso(event)
        g.freeze_decode=1

#---------------------------------------------------- freeze_decode2
def freeze_decode2(event):
# If decoder is busy or we are not monitoring, ignore request
    if Audio.gcom2.ndecoding==0 or Audio.gcom2.monitoring==0:
        set_freezedf(event)
        g.freeze_decode=2

#---------------------------------------------------- update
def update():
    global a,a2,b0,c0,g0,im,im2,isec0,line0,line02,newMinute,\
           nscroll,pim,pim2,nfa0,nfb0,bw, \
           root_geom,t0,mousedf0,mousefqso0,nfreeze0,tol0,mode0,nmark0, \
           fmid,fmid0,frange,frange0,dftolerance0
    
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

    nbpp=int((Audio.gcom2.nfb - Audio.gcom2.nfa)*32768/(96.0*NX))
    bw=750.0*(96.0/32768.0)*nbpp
    if Audio.gcom2.nfullspec:
        nbpp=int(32768.0/NX)
        bw=750.0*(96.0/32768.0)*nbpp

    if g.showspecjt==1:
        showspecjt()
    nspeed=nspeed0.get()                        #Waterfall update rate
    brightness=sc1.get()
    contrast=sc2.get()
    g0=sc3.get()

    newspec=Audio.gcom2.newspec                   #True if new data available
    if newspec or brightness != b0 or contrast != c0 or g.cmap != g.cmap0:
        Audio.spec(brightness,contrast,g0,nspeed,a,a2) #Call Fortran routine spec
        n=Audio.gcom2.nlines
        box=(0,0,NX,130-n)                  #Define region
        region=im.crop(box)                 #Get all but last line(s)
        region2=im2.crop(box)               #Get all but last line(s)
        box=(125,0,624,120)
        try:
            if newspec==1:
                im.paste(region,(0,n))      #Move waterfall down
                im2.paste(region2,(0,n))        #Move waterfall down
        except:
            print "Images did not match, continuing anyway."
        for i in range(n):
            line0.putdata(a[NX*i:NX*(i+1)]) #One row of pixels to line0
            im.paste(line0,(0,i))           #Paste in new top line(s)
            line02.putdata(a2[NX*i:NX*(i+1)])#One row of pixels to line0
            im2.paste(line02,(0,i))         #Paste in new top line(s)
        nscroll=nscroll+n

    if newspec:
        if Audio.gcom2.monitoring:
            if newMinute:
                draw.line((0,0,749,0),fill=128)     #Draw the minute separator
                draw2.line((0,0,749,0),fill=128)    #Draw the minute separator
#            if nscroll == 13:
#                draw.text((5,2),t0[0:5],fill=253)   #Insert time label
#                draw2.text((5,2),t0[0:5],fill=253)  #Insert time label
        else:
            draw.line((0,0,749,0),fill=128)     #Draw the minute separator
            draw2.line((0,0,749,0),fill=128)    #Draw the minute separator

        t=g.ftnstr(Audio.gcom2.utcdata)

# This test shouldn.t be needed, but ...
        try:
            draw.text((4,1),t[0:5],fill=253)   #Insert time label
            draw2.text((4,1),t[0:5],fill=253)  #Insert time label
        except:
            pass

    if newspec or brightness != b0 or contrast != c0 or g.cmap != g.cmap0:
        pim=ImageTk.PhotoImage(im)              #Convert Image to PhotoImage
        graph1.delete(ALL)
        pim2=ImageTk.PhotoImage(im2)            #Convert Image to PhotoImage
        graph2.delete(ALL)
        #For some reason, top two lines are invisible, so we move down 2
        graph1.create_image(0,0+2,anchor='nw',image=pim)
        graph2.create_image(0,0+2,anchor='nw',image=pim2)        
        g.ndecphase=2
        newMinute=0
        Audio.gcom2.newspec=0
        b0=brightness                           #Save scale values
        c0=contrast
        g.cmap0=g.cmap

    if (Audio.gcom2.mousedf != mousedf0 or
            Audio.gcom2.mousefqso != mousefqso0 or
            Audio.gcom2.dftolerance != dftolerance0 or
            Audio.gcom2.nfa != nfa0 or Audio.gcom2.nfb != nfb0): 
        df_mark()
# The following int() calls are to ensure that the values copied to
# mousedf0 and mousefqso0 are static.
        mousedf0=int(Audio.gcom2.mousedf)
        mousefqso0=int(Audio.gcom2.mousefqso)
        dftolerance0=int(Audio.gcom2.dftolerance)
        nfa0=int(Audio.gcom2.nfa)
        nfb0=int(Audio.gcom2.nfb)

    if Audio.gcom2.nfreeze != nfreeze0:
        if not Audio.gcom2.nfreeze: draw_axis()
        if Audio.gcom2.nfreeze: df_mark()
        nfreeze0=int(Audio.gcom2.nfreeze)

    if g.mode!=mode0:
        df_mark()                        ### was draw_axis()
        mode0=g.mode

    if nmark.get()!=nmark0:
        df_mark()
        nmark0=nmark.get()

#    if newspec: Audio.gcom2.ndiskdat=0
    Audio.gcom2.nlines=0
    Audio.gcom2.nflat=nflat.get()
    frange=nfr.get()*2000
    if(fmid<>fmid0 or frange<>frange0):
        if fmid<1000*nfr.get(): fmid=1000*nfr.get()
        if fmid>5000-1000*nfr.get(): fmid=5000-1000*nfr.get()
        df_mark()
        fmid0=fmid
        frange0=frange
    Audio.gcom2.nfmid=int(fmid)
    Audio.gcom2.nfrange=int(frange)

    ltime.after(200,update)                      #Reset the timer

#-------------------------------------------------------- Create GUI widgets

#-------------------------------------------------------- Menu bar
frame = Frame(root)
frame.pack()

mbar = Frame(frame)
mbar.pack(fill=X)

#--------------------------------------------------------- Palette menu
setupbutton = Menubutton(mbar, text = 'Palette', )
setupbutton.pack(side = LEFT)
setupmenu = Menu(setupbutton,tearoff=0)
setupbutton['menu'] = setupmenu
setupmenu.add_radiobutton(label='Gray0',command=pal_gray0,
            value=0,variable=npal)
setupmenu.add_radiobutton(label='Gray1',command=pal_gray1,
            value=1,variable=npal)
setupmenu.add_radiobutton(label='Linrad',command=pal_linrad,
            value=2,variable=npal)
setupmenu.add_radiobutton(label='Blue',command=pal_blue,
            value=3,variable=npal)
setupmenu.add_radiobutton(label='Hot',command=pal_Hot,
            value=4,variable=npal)
setupmenu.add_radiobutton(label='AFMHot',command=pal_AFMHot,
            value=5,variable=npal)

lab1=Label(mbar,width=20,padx=20,bd=0)
lab1.pack(side=LEFT)
fdf=Label(mbar,width=30,bd=0,anchor=W)
fdf.pack(side=LEFT)
lab3=Label(mbar,padx=13,bd=0)
lab3.pack(side=LEFT)
lab0=Label(mbar,padx=10,bd=0)
lab0.pack(side=LEFT)

#------------------------------------------------- Speed selection buttons
for i in (5, 4, 3, 2, 1):
    t=str(i)
    Radiobutton(mbar,text=t,value=i,variable=nspeed0).pack(side=RIGHT)
nspeed0.set(1)
lab2=Label(mbar,text='Speed: ',bd=0)
lab2.pack(side=RIGHT)
#------------------------------------------------- Graphics frame
iframe1 = Frame(frame, bd=1, relief=SUNKEN)
c=Canvas(iframe1, bg='white', width=NX, height=25,bd=0)
c.pack(side=TOP)
Widget.bind(c,"<Shift-Button-1>",freq_range)
Widget.bind(c,"<Shift-Button-2>",freq_range)
Widget.bind(c,"<Shift-Button-3>",freq_range)

graph1=Canvas(iframe1, bg='black', width=NX, height=NY,bd=0,cursor='crosshair')
graph1.pack(side=TOP)
Widget.bind(graph1,"<Motion>",fdf_change)
Widget.bind(graph1,"<Button-1>",set_fqso)
Widget.bind(graph1,"<Double-Button-1>",freeze_decode1)
iframe1.pack(expand=1, fill=X)

c2=Canvas(iframe1, bg='white', width=NX, height=25,bd=0)
c2.pack(side=TOP)
Widget.bind(c2,"<Shift-Button-1>",freq_range)
Widget.bind(c2,"<Shift-Button-2>",freq_range)
Widget.bind(c2,"<Shift-Button-3>",freq_range)

graph2=Canvas(iframe1, bg='black', width=NX, height=NY,bd=0,cursor='crosshair')
graph2.pack(side=TOP)
Widget.bind(graph2,"<Motion>",fdf_change2)
Widget.bind(graph2,"<Button-1>",set_freezedf)
Widget.bind(graph2,"<Double-Button-1>",freeze_decode2)
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
iframe2.pack(expand=1, fill=X)

#----------------------------------------------- Restore params from INI file
try:
    f=open('MAP65.INI',mode='r')
    params=f.readlines()
except:
    params=""

try:
    for i in range(len(params)):
        key,value=params[i].split()
        if   key == 'SpecJTGeometry': root.geometry(value)
        elif key == 'UpdateInterval': nspeed0.set(value)
        elif key == 'Brightness':
            sc1.set(value)
            b0=sc1.get()
        elif key == 'Contrast':
            sc2.set(value)
            c0=sc2.get()
        elif key == 'DigitalGain': sc3.set(value)
        elif key == 'AxisLabel': naxis.set(value)
        elif key == 'MarkTones': nmark.set(value)
        elif key == 'Flatten': nflat.set(value)
        elif key == 'Palette':
            g.cmap=value
            g.cmap0=value
        elif key == 'Frange': nfr.set(value)
        elif key == 'Fmid': fmid=int(value)
        else: pass
except:
    print 'Error reading MAP65.INI, continuing with defaults.'
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
#draw_axis()
df_mark()

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
root.title('Waterfall')
if(__name__=="__main__"):
    Audio.gcom2.monitoring=1
root.mainloop()

#-------------------------------------------------- Save user params and quit
f=open('MAP65.INI',mode='w')
f.write("UpdateInterval " + str(nspeed0.get()) + "\n")
f.write("Brightness " + str(b0)+ "\n")
f.write("Contrast " + str(c0)+ "\n")
f.write("DigitalGain " + str(g0)+ "\n")
f.write("AxisLabel " + str(naxis.get()) + "\n")
f.write("MarkTones " + str(nmark.get()) + "\n")
f.write("Flatten " + str(nflat.get()) + "\n")
f.write("Palette " + g.cmap + "\n")
f.write("Frange " + str(nfr.get()) + "\n")
f.write("Fmid " + str(fmid) + "\n")
root_geom=root_geom[root_geom.index("+"):]
f.write("SpecJTGeometry " + root_geom + "\n")
f.close()

