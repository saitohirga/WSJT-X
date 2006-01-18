Changes in WSJT 5.9.2: January 16, 2006
---------------------------------------

Enhancements
------------

1.  Thread priorities have been adjusted for smoother operation.  

2.  The JT65 decoder has been giver improved immunity to garbage data
    (birdies, QRM, etc).  It exhibits better performance on strong
    signals and provides more accurate estimates of their S/N.

3.  The FSK441 decoder produces less on-screen gibberish when
    processing mouse-picked decodes.

4.  The JT6M decoder now makes better use of Freeze and Tol. You can
    set the value of "Freeze DF" by using the Right/Left arrow keys.
    (This feature is also useful in JT65 mode.)

5.  On-screen font sizes can be set by using Windows Notepad to edit
    the file wsjtrc.win.  If your screen has resolution greater than
    1024 x 768, or if you have old eyes like mine, you may want to
    increase the font sizes from 8 and 9 points (first three lines of
    the file) to, say, 9 and 10 points.

6.  A simulator mode is now built into WSJT for testing purposes.  It
    is presently most useful in JT65 mode.  By entering, say, "#-22"
    in the text box for Tx6, you signify that the program should
    generate its Tx audio files with the signal embedded in white
    gaussian noise, 22 dB below the noise power in a 2.5 kHz
    bandwidth.  You can direct this signal into a second computer
    running WSJT, for example to test the decoder or to practice
    operating in JT65 mode.  You can even have the two computers "work
    each other" in a simulated QSO, although changing messages of
    course requires operator action.

7.  Dividing lines are now provided on the waterfall display between
    spectra corresponding to wave files read from disk.

8.  The PTT line is explicitly set low on program startup.

9.  The F10 key brings up the SpecJT screen (if it was hidden) and
    toggles foreground and focus status between the WSJT and SpecJT
    screens.
 
10. You can use the Alt-F and Alt-Z keyboard shortcut to toggle
    "Freeze" and "Zap" on and off.

11. "Accelerated decoding" has been removed from the Setup menu.  In
    effect, this option is now always ON.

12. Text windows are now cleared when switching between modes.

13. Linux and FreeBSD versions (see below) offer PTT control via
    parallel port, as well as serial port.  They offer sound support
    via ALSA and OSS.

Bug Fixes:
----------
1.  The use of non-threadsafe code for FFTs could cause occasional and
    unpredictable program crashes.  Fixed.

2.  A bug in the JT65 decoder could (rarely) cause large errors in the
    reported level of strong signals. Fixed.

3.  The program could be made to crash by trying to read a very short
    wave file. Fixed.


For Curious Users, and Especially for Programmers
-------------------------------------------------

WSJT is no longer a one-person effort, and the program no longer runs
only under Microsoft Windows.  WSJT is now a full-fledged Open Source
project, with an active working group making contributions to future
development.  Source code is now stored in a public repository under
control of a version control system called "Subversion", or SVN.  You
can learn more at http://developer.berlios.de/projects/wsjt/.

The first significant result of the group effort has been to create
versions of WSJT that run under the Linux and FreeBSD operating
systems.  Porting WSJT to the Macintosh platform should be
straightforward, as well, but has not yet been attempted.

If you are interested in testing and using WSJT on your own Linux or
FreeBSD system, we'd like to hear from you.

If you feel that you can usefully contribute to the future development
of WSJT on any platform, we would also like to hear from you!  We
could use help with documentation and website maintenance, as well as
actual programming.

The present WSJT working group consists of:

    Diane Bruce, VA3DB
    James Courtier-Dutton
    Bob McGwier, N4HY
    Jonathan Naylor, ON/G4KLX
    Stewart Nelson, KK7KA
    Joe Taylor, K1JT
    Kaj Wiik, OH6EH


