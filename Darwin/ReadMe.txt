                          Notes on WSJT-X Installation for Mac OS X
                          -----------------------------------------

If you have already downloaded a previous version of WSJT-X then I suggest 
you change the name in the Applications folder from WSJT-X to WSJT-X_previous 
before proceeding.  

If you have installed a previous version of WSJT-X before then there is no 
need to change anything on your system so proceed to NEXT.  

BEGIN:

There are some system matters you must deal with first.  Open a Terminal window
by going to Applications->Utilities and clicking on Terminal.

Along with this ReadMe file there is a file:   sysctl.conf.   Drag this file to your Desktop.
Then type in the Terminal window:

   cd $HOME/Desktop

WSJT-X makes use of a block of memory which is shared between different parts of
the code.  The normal allocation of shared memory on a Mac is insufficient and this 
has to be increased.   You can look at the new allocation by typing:

   cat  sysctl.conf

This shows the following:

kern.sysv.shmmax=33554432
kern.sysv.shmmin=1
kern.sysv.shmmni=128
kern.sysv.shmseg=32
kern.sysv.shmall=8192

You can check the current allocation on your Mac by typing:

  sysctl -a | grep sysv.shm

If your shmmax is already at least 33554432 (32 MB) then you can close the Terminal window
and skip the next steps and go to (NEXT).

Now move this file into place for the system to use by typing:

  sudo mv sysctl.conf /etc/

and then reboot your Mac.  This is necessary to install the changes.  After the
reboot you should re-open the Terminal window as before and you can check that the
change has been made by typing:

  sysctl -a | grep sysv.shm

You are finished with system changes.  You should make certain that NO error messages
have been produced during these steps.   You can now close the Terminal window.  It will
not be necessary to repeat this procedure again, even when you download an updated
version of WSJT-X.

NEXT:

Drag the WSJT-X app to your preferred location, such as Applications.

You need to configure your sound card.   Visit Applications > Utilities > Audio MIDI Setup  and
select your sound card and then set Format to be "48000Hz 2ch-16bit" for input and output.

Now double-click on the WSJT-X app and two windows will appear.  Select Preferences under the 
WSJT-X Menu and fill in various station details on the General panel.   I recommend checking the
4 boxes under the Display heading and the first 4 boxes under the Behaviour heading.

Next visit the Audio panel and select the Audio Codec you use to communicate between WSJT-X
and your rig.   There are so many audio interfaces available that it is not possible to give
detailed advice on selection.  If you have difficulties contact me.   Note the location of the
Save Directory.  Decoded wave forms are located here.

Look at the Reporting panel.  If you check the "Prompt me" box, a logging panel will appear
at the end of the QSO.  Two log files are provided in  Library/Application Support/WSJT-X.
These are a simple wsjtx.log file and wsjtx_log.adi which is formatted for use with logging
databases.

Finally, visit the Radio panel.  WSJT-X is most effective when operated with CAT control.  You 
will need to install the relevant Mac driver for your rig.   This must be located in the system
driver directory  /dev.  I use a Prolific USB-Serial Adapter to a Kenwood TS870s and the relevant
driver is  /dev/tty.PL2303-00002226.   You should install your driver and then re-launch WSJT-X.
Return to the the Radio panel in Preferences and insert the full name of your driver in the
Serial Port panel.   Such as:  /dev/tty.PL2303-00002226 or what ever driver you have.  The /dev/
prefix is mandatory.  Set the relevant communication parameters as required by your transceiver.

WSJT-X needs the Mac clock to be accurate.  Visit System Preferences > Date & Time and make sure that
date and time are set automatically.   The drop-down menu will normally offer you several time
servers to choose from.

On the Help menu, have a look at the new Online User's Guide for operational hints and tips.

Please email me if you have problems.

--- John G4KLA     (g4kla@rmnjmn.demon.co.uk)

