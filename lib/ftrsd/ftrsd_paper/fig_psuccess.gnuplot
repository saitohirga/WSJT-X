# gnuplot script for "Percent copy" figure
# run: gnuplot fig_psuccess.gnuplot
# then: pdflatex fig_psuccess.tex
#
set term epslatex standalone size 20cm,10cm
set output "fig_psuccess.tex"
set xlabel "SNR in 2500 Hz BW (dB)"
set ylabel "Percent copy"
set style func linespoints
set key on top outside nobox
set tics in
set mxtics 2
set mytics 2
set grid
plot "ftdata-10000.dat" using 1:2 every ::1 with linespoints pt 4 title 'FT-10K', \
     "ftdata-100000.dat" using 1:2 every ::1 with linespoints pt 5 title 'FT-100K', \
     "ftdata-1000-rf.dat" using 1:2 every ::1 with linespoints pt 7 title 'FT-1K-RF', \
     "ftdata-100-rf.dat" using 1:2 every ::1 with linespoints pt 8 title 'FT-100-RF', \
     "bmdata.dat" using 1:2 with linespoints pt 9 title 'BM', \
     "bmdata-rf.dat" using 1:2 with linespoints pt 10 title 'BM-RF', \
     "kvasd-7999-rf.dat" using 1:2 every ::1 with linespoints pt 12 title 'KV-8-RF', \
     "kvasd-11999.dat" using 1:2 every ::1 with linespoints pt 13 title 'KV-12', \
     "kvasd-11999-rf.dat" using 1:2 every ::1 with linespoints pt 14 title 'KV-12-RF'
