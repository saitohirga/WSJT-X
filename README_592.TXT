Changes in WSJT 5.9.2: January 10, 2006
---------------------------------------

Enhancements
------------

1.  Thread priorities have been adjusted for smoother operation.  One
    result is that there will be fewer audio glitches caused by the
    Windows O/S paying attention to other programs.

2.  The JT65 decoder now has improved immunity to "garbage data," and
    it exhibits better performance on strong signals.

3.  The FSK441 decoder produces less on-screen gibberish when you do
     mouse-picked decodes.

4.  The JT6M decoder now makes better use of Freeze and Tol. You can
    set the value of "Freeze DF" by using the Right/Left arrow keys.

5.  On-screen font sizes can be set by using Windows Notepad (or
    another text editor) to edit the file wsjtrc.win.  If your screen
    has resolution greater than 1024 x 768, or if you have old eyes
    like mine, you may want to increase the sizes from 8 and 9 points
    (first three lines of the file) to, say, 9 and 10 points.

6.  A simulator mode is now built into WSJT.  It is presently most
    useful in JT65 mode.  By entering, say, "#-22" in the text box for
    Tx6, you signify that the program should generate its Tx audio
    files with the signal embedded in white gaussian noise, 22 dB
    below the noise power in a 2.5 kHz bandwidth.  You can direct this
    signal into a second computer running WSJT, for eaxmple to test
    the decoder or to practice operating in JT65 mode.  You can even
    have the two computers "work each other", although changing
    messages of course requires operator action.

7.  Dividing lines are now provided on the waterfall display between
    spectra corresponding to wave files read from disk.

8.  The PTT line is explicitly set low on program startup.

9.  The F10 key brings up the SpecJT screen (if it was hidden) and
    toggles foreground and focus between the WSJT and SpecJT screens.
 
10. You can use the Alt-F keyboard shortcut to toggle "Freeze", and
    Alt-Z to toggle "Zap".

11. "Accelerated decoding" has been removed from the Setup menu.  In
    effect, it is now always ON.


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

WSJT is no longer a one-person effort and no longer runs only in
Microsoft Windows.  It has become a full-fledged Open Source project,
with an active working group making contributions to future
development.  Source code is now stored in a public repository under
control of a version control system called Subversion, or SVN.  You
can learn more at http://developer.berlios.de/projects/wsjt/.

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
    Stewart Nelson, KK7KA
    Joe Taylor, K1JT
    Kaj Wiik, OH6EH


