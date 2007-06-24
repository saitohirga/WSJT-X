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
root_geom=""
t0=""
tol0=400
ttot=0.0

c=Canvas()
NX=750
NY=130
a=zeros(NX*NY,'s')
im=Image.new('P',(NX,NY))
line0=Image.new('P',(NX,1))  #Image fragment for top line of waterfall
draw=ImageDraw.Draw(im)
pim=ImageTk.PhotoImage(im)

a2=zeros(NX*NY,'s')
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
    df=96.0/750.0
    fmid=122.8                                # empirical
    g.Freq=df*(event.x-375) + fmid
    t="Freq: %5.1f kHz" % (g.Freq,)
    fdf.configure(text=t)

def fdf_change2(event):
    g.DFreq=(2200.0/750.0)*(event.x-375)
    t="DF: %d Hz" % int(g.DFreq)
    fdf2.configure(text=t)

#---------------------------------------------------- set_fqso
def set_fqso(event):
    n=int(g.Freq + 0.5)
    Audio.gcom2.mousefqso=n

#---------------------------------------------------- set_freezedf
def set_freezedf(event):
    n=int(g.DFreq + 0.5)
    Audio.gcom2.mousedf=n

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
        dx=288.7 + (1500-fmid)/df
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

#---------------------------------------------------- change_fmid
##def change_fmid1():
##    global fmid
##    fmid=fmid+100
##    if fmid>5000-1000*nfr.get(): fmid=5000-1000*nfr.get()
##
##def change_fmid2():
##    global fmid
##    fmid=fmid-100
##    if fmid<1000*nfr.get(): fmid=1000*nfr.get()
##
##def set_fmid():
##    global fmid
##    if nfr.get()==1: fmid=1200
##    if nfr.get()==2: fmid=2200

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

#def set_frange():
#    nfr.set(3-nfr.get())

#---------------------------------------------------- freq_center
##def freq_center(event):
### Move clicked location to center of frequency scale
##    global fmid,frange
##    n=100*int(0.01*df*(event.x-375))
##    fmid = fmid + n
##    if fmid<1000: fmid=1000
##    if fmid>1700: fmid=1700

#---------------------------------------------------- decode_request
##def decode_request(event):
##    if g.mode[:4]!='JT65' and nspeed0.get()>5:
### If decoder is busy or we are not monitoring, ignore request
##        if Audio.gcom2.ndecoding==0 and Audio.gcom2.monitoring:
##            Audio.gcom2.mousebutton=event.num       #Left=1, Right=3
##            Audio.gcom2.npingtime=int(40*event.x)   #Time (ms) of selected ping
##            if event.y <= 150:
##                Audio.gcom2.ndecoding=2             #Mouse pick, top half
##            else:
##                Audio.gcom2.ndecoding=3             #Mouse pick, bottom half

#---------------------------------------------------- freeze_decode
def freeze_decode(event):
# If decoder is busy or we are not monitoring, ignore request
    if Audio.gcom2.ndecoding==0 or Audio.gcom2.monitoring==0:
        set_freezedf(event)
        g.freeze_decode=1

#---------------------------------------------------- update
def update():
    global a,a2,b0,c0,g0,im,im2,isec0,line0,line02,newMinute,\
           nscroll,pim,pim2, \
           root_geom,t0,mousedf0,nfreeze0,tol0,mode0,nmark0, \
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
    brightness=sc1.get()
    contrast=sc2.get()
    g0=sc3.get()

    newspec=Audio.gcom2.newspec                   #True if new data available
    if newspec:
        Audio.spec(brightness,contrast,g0,nspeed,a,a2) #Call Fortran routine spec

    if newspec or brightness!=b0 or contrast!=c0:
        if brightness==b0 and contrast==c0:
            n=Audio.gcom2.nlines
            box=(0,0,NX,130-n)                  #Define region
            region=im.crop(box)                 #Get all but last line(s)
            region2=im2.crop(box)               #Get all but last line(s)
            box=(125,0,624,120)
            try:
                im.paste(region,(0,n))          #Move waterfall down
                im2.paste(region2,(0,n))        #Move waterfall down
            except:
                print "Images did not match, continuing anyway."
            for i in range(n):
                line0.putdata(a[NX*i:NX*(i+1)]) #One row of pixels to line0
                im.paste(line0,(0,i))           #Paste in new top line(s)
                line02.putdata(a2[NX*i:NX*(i+1)])#One row of pixels to line0
                im2.paste(line02,(0,i))         #Paste in new top line(s)
            nscroll=nscroll+n
        else:                                   #A scale factor has changed
            im.putdata(a)                       #Compute whole new image
            im2.putdata(a2)                     #Compute whole new image
            b0=brightness                       #Save scale values
            c0=contrast

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
        draw.text((4,1),t[0:5],fill=253)   #Insert time label
        draw2.text((4,1),t[0:5],fill=253)  #Insert time label


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

    if (Audio.gcom2.mousedf != mousedf0 or Audio.gcom2.dftolerance != tol0):
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
        draw_axis()
        mode0=g.mode

    if nmark.get()!=nmark0:
        df_mark()
        nmark0=nmark.get()

    if newspec: Audio.gcom2.ndiskdat=0
    Audio.gcom2.nlines=0
    Audio.gcom2.nflat=nflat.get()
    frange=nfr.get()*2000
    if(fmid<>fmid0 or frange<>frange0):
        if fmid<1000*nfr.get(): fmid=1000*nfr.get()
        if fmid>5000-1000*nfr.get(): fmid=5000-1000*nfr.get()
#        draw_axis()
        df_mark()
        fmid0=fmid
        frange0=frange
    Audio.gcom2.nfmid=int(fmid)
    Audio.gcom2.nfrange=int(frange)

    ltime.after(200,update)                      #Reset the timer

#-------------------------------------------------------- draw_axis
def draw_axis():
    c.delete(ALL)
    xmid=125.0 - 2.3                            #Empirical
    bw=96.0
    x1=int(xmid-0.6*bw)
    x2=int(xmid+0.6*bw)
    xdf=bw/NX                                    #128 Hz
    for ix in range(x1,x2,1):
        i=0.5*NX + (ix-xmid)/xdf
        j=20
        if (ix%5)==0: j=16
        if (ix%10)==0 :
            j=16
            x=i-1
            if ix<100: x=x+1
            y=8
            c.create_text(x,y,text=str(ix))
        c.create_line(i,25,i,j,fill='black')
            
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

    tol=Audio.gcom2.dftolerance
    x1=(Audio.gcom2.mousedf-tol)/xdf2 + 0.5*NX
    x2=(Audio.gcom2.mousedf+tol)/xdf2 + 0.5*NX
    c2.create_line(x1,25,x2,25,fill='green',width=2)


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
setupmenu.add_checkbutton(label='Flatten spectra',variable=nflat)
setupmenu.add_checkbutton(label='Mark JT65 tones only if Freeze is checked',
            variable=nmark)
setupmenu.add_separator()
setupmenu.add_radiobutton(label='Frequency axis',command=df_mark,
            value=0,variable=naxis)
setupmenu.add_radiobutton(label='JT65 DF axis',command=df_mark,
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

lab1=Label(mbar,padx=20,bd=0)
lab1.pack(side=LEFT)
fdf=Label(mbar,width=15,bd=0)
fdf.pack(side=LEFT)
fdf2=Label(mbar,width=15,bd=0)
fdf2.pack(side=LEFT)

lab3=Label(mbar,padx=13,bd=0)
lab3.pack(side=LEFT)
#bbw=Button(mbar,text='BW',command=set_frange,padx=1,pady=1)
#bbw.pack(side=LEFT)

lab0=Label(mbar,padx=10,bd=0)
lab0.pack(side=LEFT)
#bfmid1=Button(mbar,text='<',command=change_fmid1,padx=1,pady=1)
#bfmid2=Button(mbar,text='>',command=change_fmid2,padx=1,pady=1)
#bfmid3=Button(mbar,text='|',command=set_fmid,padx=3,pady=1)
#bfmid1.pack(side=LEFT)
#bfmid3.pack(side=LEFT)
#bfmid2.pack(side=LEFT)

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
#Widget.bind(c,"<Control-Button-1>",freq_center)

graph1=Canvas(iframe1, bg='black', width=NX, height=NY,bd=0,cursor='crosshair')
graph1.pack(side=TOP)
Widget.bind(graph1,"<Motion>",fdf_change)
#Widget.bind(graph1,"<Button-1>",decode_request)
#Widget.bind(graph1,"<Button-3>",decode_request)
Widget.bind(graph1,"<Button-1>",set_fqso)
Widget.bind(graph1,"<Double-Button-1>",freeze_decode)
iframe1.pack(expand=1, fill=X)

c2=Canvas(iframe1, bg='white', width=NX, height=25,bd=0)
c2.pack(side=TOP)
Widget.bind(c2,"<Shift-Button-1>",freq_range)
Widget.bind(c2,"<Shift-Button-2>",freq_range)
Widget.bind(c2,"<Shift-Button-3>",freq_range)
#Widget.bind(c2,"<Control-Button-1>",freq_center)

graph2=Canvas(iframe1, bg='black', width=NX, height=NY,bd=0,cursor='crosshair')
graph2.pack(side=TOP)
Widget.bind(graph2,"<Motion>",fdf_change2)
#Widget.bind(graph2,"<Button-1>",decode_request)
#Widget.bind(graph2,"<Button-3>",decode_request)
Widget.bind(graph2,"<Button-1>",set_freezedf)
Widget.bind(graph2,"<Double-Button-1>",freeze_decode)
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
        elif key == 'Brightness': sc1.set(value)
        elif key == 'Contrast': sc2.set(value)
        elif key == 'DigitalGain': sc3.set(value)
        elif key == 'AxisLabel': naxis.set(value)
        elif key == 'MarkTones': nmark.set(value)
        elif key == 'Flatten': nflat.set(value)
        elif key == 'Palette': g.cmap=value
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
root.title('  MAP65     by K1JT')
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

