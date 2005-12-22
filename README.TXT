Changes in WSJT 5.9.0 -- November 15, 2005
------------------------------------------

1. JT65 decoding has been made faster and significantly improved in
   other ways.  Three new options appear on the Decode->JT65 menu:
   "Fast", "Normal", and "Exhaustive".  The program is most sensitive
   if you choose "Exhaustive".  Choosing "Normal" will make decoding
   slightly less sensitive, but the loss is not great, and decoding
   can be twice as fast.  The "Fast" setting is faster still, but can
   be less sensitive by 2 dB or more in some cases.  If you have a 1.5
   GHz or faster computer, use "Exhaustive".  With a slower computer
   you may want to experiment with the other settings.
   
2. In JT65 mode, double-clicking on the waterfall (SpecJT window) or
   on the red curve (main window) will set "Freeze DF" at the selected
   frequency, turn Freeze ON, and invoke the decoder.  Using this
   feature, you can quickly decode a transmission at several different
   values of DF.  I find this feature to be *extremely* useful.

3. The range of DT values searched to establish synchronization has
   been doubled, now extending from -2 to +10 seconds.  The reported
   values of DT are more accurate, as well.  You should normally
   expect EME signals to have DT in the range 2 to 3 seconds, but the
   program will now synchronize properly even if DT is well outside
   this range.

4. WSJT now offers the ability to correct for errors in soundcard
   input and output sampling rates.  Numbers displayed in the first
   panel of the status bar (at lower left of the main screen) give the
   ratio of actual sample rates for input and output to the correct
   value, 11025 Hz.  The numbers should stabilize about one minute
   after program startup.  If they fall in a "safe" range between
   about 0.9990 and 1.0010, you have a good sound card (at least in
   respect to sampling frequency).  You can then leave the entry
   fields "Rate In" and "Rate Out" on the "Setup -> Options" page at
   their default values, 1.0.

   If your soundcard gives one or both numbers well outside the safe
   range, you should enter the displayed errant numbers as "Rate In"
   and/or "Rate Out" on the Setup->Options page.  This needs to be
   done only once; subsequent changes in the last decimal place of the
   displayed values are not very significant, and can be safely
   ignored.

   The result of this procedure is that your Tx signal will be
   "trimmed" so that your tone spacings in time and frequency are
   correct.  In addition, your digitized Rx signals will be adjusted
   so that the software can properly interpret them.

   This is an important procedure.  Some recent sound cards produce
   sampling error factors as low as 0.9932 or as high as 1.0068.  If
   uncorrected, such results can degrade your S/N in WSJT modes by 2
   dB or more.

   If one of the measured sample rates differs from the corresponding
   value specified for "Rate In" or "Rate Out" by more than 0.1%, a
   red warning label will appear just below the graphical area on the
   main screen.

5. Graphical display of information obtained during JT65 decoding has
   been enhanced.  As before, a red line illustrates the maximum
   correlation between the pseudo-random sync tone pattern and the
   received signal at each value of frequency offset, DF.  A blue line
   shows the correlation at the best DF, plotted as a function of time
   offset, DT.  If a shorthand message is detected, two new lines
   colored magenta and orange replace the red and blue lines.  The new
   lines illustrate phase-resolved spectra measured in each of the two
   phases of the shorthand square-wave pattern.  A properly detected
   shorthand message will show a peak in the magenta curve, followed
   at a specified distance by a peak in the orange curve.  The correct
   locations of the two peaks are marked by small yellow ticks.
   Unlike the alternating shorthand message tones, birdies will appear
   approximately equally in the magenta and orange curves.

6. For the convenience of temporary DXpeditions, a new JT65 feature
   permits use of add-on DXCC prefixes that are not in the published
   list of supported prefixes.  Both stations in a QSO must enter the
   required prefix (for example, PJ8 or FS) in a box on the
   Setup->Options page.  The effect will be to temporarily add the
   entry to the table of supported prefixes.

7. The Setup->Options page has new entry fields labeled "Source RA"
   and "Source DEC".  You can enter the current right ascension and
   declination of a radio source to be used for system calibration, or
   perhaps a pulsar or a deep space probe that you wish to detect.
   The program will display (on the Astronomical Data screen) the
   current Azimuth and Elevation of the specified object at your
   station.  The source Azimuth and Elevation are also written every
   second to the file azel.dat, in case you have automated tracking
   capabilities that depend on this information.

8. To facilitate the coming release of the full source code of WSJT
   under the General Public License, the proprietary soft-decision
   Reed Solomon decoder has been removed from WSJT proper and made
   into a separate executable module.  This change is invisible to the
   user, and the full benefit of the soft-decision decoder is still
   available.  An open source hard-decision decoder is also provided;
   it's what you get when you select the "Fast" JT65 decoding option.

9. In WSJT 5.8.6, if the value of "Freeze DF" (as displayed in the
   Status Bar) differs from the sync tone frequency by more than
   "Tol", shorthand decoding was suppressed even if Freeze was not
   checked.  This is a bug, and it has been fixed.

10. Earlier versions of WSJT also had a bug that could cause the "Zap"
    function to notch out a valid sync tone.  Fixed.

11. The Help screens called up by F1 and Shift-F1 have been updated.
    Be sure to read these screens: they contain many operational
    conveniences that you may not have discovered!

12. At scrolling speed 5, the time labels and "minute separator" lines
    were displayed erratically and the CPU load was excessive.  Fixed.

13. Signal strength measurements above -20 dB were formerly compressed
   and significantly underestimated.  This has been fixed.

14. Decodings of the average of many properly synchronized transmissions
    would sometimes go from "good" to "bad" after approximately 8-12 
    transmissions.  This was a bug, and it has been fixed.

15. Several bugs in the FSK441 decoder have been fixed.  Both automatic
   decoding and mouse-picked decoding have been improved.

16. Changing WSJT modes now sets Auto to OFF, Tol to 400, and the Tx
   message number to 1.

17. The generated audio tones for CW ID in FSK441 and JT6M modes have
    been moved down to 440 Hz, to avoid possible confusion with the
    other tones used in these modes.

18. Readout of "Rx noise" on the main screen is now highlighted in red
   if the level is outside the range -10 to +10 dB.

19. The Monitor button is no longer highlighted in green while you are
   transmitting.

20. No attempt is made to decode if the Rx level is very low -- for
   example, if your receiver is turned off.

21. If the Grid box does not contain a valid locator, readouts of
   azimuth and distance are suppressed.

22. Keying of the audio tone to produce Morse code has been "softened"
    to suppress key clicks.

23. Your transmitted messages recorded in the file ALL.TXT are now
    identified as to mode, and shorthand transmissions are noted.

23. A number of other very minor bugs have been fixed.
