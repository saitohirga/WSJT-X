Changes in WSJT 5.9.2: January 10, 2006
---------------------------------------

Enhancements
------------

1.  Thread priorities have been adjusted for smoother operation.  One
    result is that there will be fewer audio glitches caused by the
    Windows O/S paying attention to other programs.

2.  The JT65 decoder has improved immunity to "garbage data," and
    it exhibits better performance on strong signals.

3.  The FSK441 decoder produces less on-screen gibberish when you do
     mouse-picked decodes.

4.  The JT6M decoder now makes better use of Freeze and Tol. You can
    set the value of "Freeze DF" by using the Right/Left arrow keys.

5.  On-screen font sizes can be set by using Windows Notepad to edit
    the file wsjtrc.win.  If your screen has resolution greater than
    1024 x 768, or if you have old eyes (like mine), you may want to
    increase the sizes from 8 and 9 (first three lines of the file) to
    9 and 10, say.

6.  Dividing lines are now provided on the waterfall display between
    spectra corresponding to wave files read from disk.

7.  The PTT line is explicitly set low on program startup.

8.  The F10 key brings up the SpecJT screen (if it was hidden) and
    toggles focus between the WSJT and SpecJT screens.
 
9.  Use the Alt-F keyboard shortcut to toggle "Freeze", and Alt-Z to
    toggle "Zap".

10. "Accelerated decoding" HAS BEEN removed from the Setup menu.
    In effect, it is now always ON.


Bug Fixes:
----------
1.  The use of non-threadsafe code for FFTs caused occasional and
    unpredictable program crashes.  Fixed.

2.  A bug in the JT65 decoder could (rarely) cause large errors in the
    reported level of strong signals. Fixed.

3.  The program could be made to crash by trying to read a very short
    wave file. Fixed.


Information for Programmers
---------------------------

WSJT is no longer a one-person effort.  It has become a full-fledged
Open Source project, with an active working group making contributions
to future development.  Source code is now stored in a public
repository under control of the Subversion (SVN) version control
system.  You can learn more at
http://developer.berlios.de/projects/wsjt/.

The first significant result of the group effort has been to create
versions of WSJT that run under the Linux and FreeBSD operating
systems.  If you are interested in testing and using WSJT on your own
Linux or FreeBSD system, we'd like to hear from you.  

If you feel that you can usefully contribute to the future development
of WSJT on any platform, we would also like to hear from you!

The present WSJT working group consists of:

    Diane Bruce, VA3DB
    James Courtier-Dutton
    Bob McGwier, N4HY
    Jonathan Naylor, ON/G4KLX
    Stewart Nelson, KK7A
    Joe Taylor, K1JT
    Kaj Wiik, OH6EH


