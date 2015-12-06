# gnuplot script for "Percent copy" figure
# run: gnuplot fig_psuccess.gnuplot
# then: pdflatex fig_psuccess.tex
#
set term epslatex standalone size 12cm,8cm
set output "fig_psuccess.tex"
set xlabel "SNR in 2500 Hz BW (dB)"
set ylabel "Percent copy"
set style func linespoints
set key on top outside nobox
set tics in
set mxtics 2
set mytics 2
set grid
plot "ftdata-10000-tight.dat" using 1:2 every ::1 with linespoints pt 5 title 'FT-1', \
     "ftdata-100000-loose.dat" using 1:2 every ::1 with linespoints pt 5 title 'FT-2', \
     "bmdata.dat" using 1:2 with linespoints pt 7 title 'BM'
