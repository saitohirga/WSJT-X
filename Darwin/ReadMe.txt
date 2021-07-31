                    Notes on WSJT-X Installation for Mac OS X
                    -----------------------------------------

If you have already downloaded a previous version of WSJT-X then I suggest 
you change the name in the Applications folder from WSJT-X to WSJT-X_previous 
before proceeding.  

I recommend that you follow the installation instructions especially if you
are moving from v2.3 to v2.4 or later, of WSJT-X or you have upgraded macOS.

Double-click on the wsjtx-...-Darwin.dmg file you have downloaded from K1JT's web-site.

Now open a Terminal window by going to Applications->Utilities and clicking on Terminal.

Along with this ReadMe file there is a file:   com.wsjtx.sysctl.plist  which must be copied to a
system area by typing this line in the Terminal window and then pressing the Return key.

      sudo  cp  /Volumes/WSJT-X/com.wsjtx.sysctl.plist  /Library/LaunchDaemons

you will be asked for your normal password because authorisation is needed to copy this file.
(Your password will not be echoed but press the Return key when completed.)
Now re-boot your Mac. This is necessary to install the changes.  After the
reboot you should re-open the Terminal window as before and you can check that the
change has been made by typing:

      sysctl -a | grep sysv.shm

If shmmax is not shown as 52428800 then contact me since WSJT-X might fail to load with
an error message: "Unable to create shared memory segment".

You can now close the Terminal window.  It will not be necessary to repeat this procedure 
again, even when you download an updated version of WSJT-X.  It might be necessary if you
upgrade macOS.
 
Drag the WSJT-X app to your preferred location, such as Applications.

You need to configure your sound card.   Visit Applications > Utilities > Audio MIDI 
Setup and select your sound card and then set Format to be "48000Hz 2ch-16bit" for 
input and output.

Now double-click on the WSJT-X app and two windows will appear.  Select Preferences 
under the WSJT-X Menu and fill in various station details on the General panel.   
I recommend checking the 4 boxes under the Display heading and the first 4 boxes under 
the Behaviour heading.

Depending on your macOS you might see a pop-up window suggesting that wsjtx wants to use the
microphone.   What this means is that audio input must be allowed.  Agree.

Next visit the Audio panel and select the Audio Codec you use to communicate between 
WSJT-X and your rig.   There are so many audio interfaces available that it is not 
possible to give detailed advice on selection.  If you have difficulties contact me.   
Note the location of the Save Directory.  Decoded wave forms are located here.

Look at the Reporting panel.  If you check the "Prompt me" box, a logging panel will appear 
at the end of the QSO.  Visit Section 11 of the User Guide for information about log files
and how to access them.

Finally, visit the Radio panel.  WSJT-X is most effective when operated with CAT 
control.  You will need to install the relevant Mac device driver for your rig, 
and then re-launch WSJT-X. Return to the Radio panel in Preferences and in 
the "Serial port" panel select your driver from the list that is presented.   If you 
do not know where to get an appropriate driver, contact me.

WSJT-X needs the Mac clock to be accurate.  Visit System Preferences > Date & Time 
and make sure that Date and Time are set automatically.  The drop-down menu will 
normally offer you several time servers to choose from.

On the Help menu, have a look at the new Online User's Guide for operational hints 
and tips and possible solutions to any problem you might have.

Please email me if you have problems.

--- John G4KLA     (g4kla@rmnjmn.co.uk)

Additional Notes:

1.  Information about com.wsjtx.sysctl.plist and multiple instances of WSJT-X

WSJT-X makes use of a block of memory which is shared between different parts of
the code.  The normal allocation of shared memory on a Mac is insufficient and this 
has to be increased.  The com.wsjtx.sysctl.plist file is used for this purpose.  You can 
use a Mac editor to examine the file.  (Do not use another editor - the file 
would probably be corrupted.)

It is possible to run two instances of WSJT-X simultaneously.  See "Section 16.2 
Frequently asked Questions" in the User Guide.  If you wish to run more than two instances
simultaneously, the shmall parameter in the com.wsjtx.sysctl.plist file needs to be modified as follows.

The shmall parameter determines the amount of shared memory which is allocated in 4096 byte pages
with 50MB (52428800) required for each instance.   The shmall parameter is calculated as: 
(n * 52428800)/4096  where 'n' is the number of instances required to run simultaneously.
Replace your new version of this file in /Library/LaunchDaemons and remember to reboot your
Mac afterwards.

Note that the shmmax parameter remains unchanged.  This is the maximum amount of shared memory that
any one instance is allowed to request from the total shared memory allocation and should not
be changed.

If two instances of WSJT-X are running, it is likely that you might need additional
audio devices, from two rigs for example.  Visit Audio MIDI Setup and create an Aggregate Device
which will allow you to specify more than one interface.  I recommend you consult Apple's guide
on combining multiple audio interfaces which is at https://support.apple.com/en-us/HT202000.

2.  Preventing WSJT-X from being put into 'sleep' mode (App Nap).

In normal circumstances an application which has not been directly accessed for a while can be 
subject to App Nap which means it is suspended until such time as its windows are accessed.  If
it is intended that WSJT-X should be submitting continued reports to, for example, PSK Reporter
then reporting will be interrupted.  App Nap can be disabled as follows, but first quit WSJT-X:

Open a Terminal window and type:    defaults  write  org.k1jt.wsjtx  NSAppSleepDisable  -bool  YES
If you type:   defaults  read  org.k1jt.wsjtx   then the response will be:  NSAppSleepDisable = 1;
Close the Terminal window and launch WSJT-X.  (If you 'Hide' WSJT-X, this scheme will be suspended.)
