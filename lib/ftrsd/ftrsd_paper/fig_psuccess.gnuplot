# gnuplot script for "Percent copy" figure
# run: gnuplot fig_psuccess.gnuplot
# then: pdflatex fig_psuccess.tex
#
set term epslatex standalone size 6in,4in
set output "fig_psuccess.tex"
set xlabel "SNR in 2500 Hz Bandwidth (dB)"
set ylabel "Percent copy"
set style func linespoints
set key off
set tics in
set mxtics 2
set mytics 2
set grid
plot [-30:-18] [0:105] "stats_0.0" using 1:($3)/10.0 with linespoints lt 4 pt 1 title 'Sync', \
     "stats_0.0" using 1:($4)/10.0 with linespoints lt 2 lw 2 pt 2 title 'BB 0', \
     "stats_0.0" using 1:($5)/10.0 with linespoints lt 1 lw 2 pt 3 title 'FT 0', \
     "stats_0.0" using 1:($6)/10.0 with linespoints lt 3 lw 2 pt 4 title 'DS 0', \
     "stats_0.2" using 1:($4)/10.0 with linespoints lt 2 pt 2 title 'BB 0.2', \
     "stats_0.2" using 1:($5)/10.0 with linespoints lt 1 pt 3 title 'FT 0.2', \
     "stats_0.2" using 1:($6)/10.0 with linespoints lt 3 pt 4 title 'DS 0.2', \
     "stats_1.0" using 1:($4)/10.0 with linespoints lt 2 pt 2 title 'BB 1', \
     "stats_1.0" using 1:($5)/10.0 with linespoints lt 1 pt 3 title 'FT 1', \
     "stats_1.0" using 1:($6)/10.0 with linespoints lt 3 pt 4 title 'DS 1', \
     "psuccess.lab" with labels
