# gnuplot script for "Percent copy" figure
# run: gnuplot fig_wer2.gnuplot
# then: pdflatex fig_wer2.tex
#
set term epslatex standalone size 6in,6*2/3in
set output "fig_wer2.tex"
set xlabel "SNR in 2500 Hz Bandwidth (dB)"
set ylabel "Percent Copy"
set style func linespoints
set key off
set tics in
set mxtics 2
set mytics 10 
set grid
plot [-27:-22] [0:110] \
     "ftdata-100000.dat" using 1:(100*$2) with linespoints lt 1 pt 7 title 'FT-100K', \
     "ftdata-10000.dat" using 1:(100*$2) with linespoints lt 1 pt 7 title 'FT-10K', \
     "ftdata-1000.dat" using 1:(100*$2) with linespoints lt 1 pt 7 title 'FT-1K', \
     "ftdata-100.dat" using 1:(100*$2) with linespoints lt 1 pt 7 title 'FT-100', \
     "ftdata-10.dat" using 1:(100*$2) with linespoints lt 1 pt 7 title 'FT-10', \
     "kvasd-15.dat" using 1:(100*$2) with linespoints lt 2 pt 8 title 'KV-15', \
     "bmdata.dat" using 1:(100*$2) with linespoints pt 11 title 'BM', \
     "wer2.lab" with labels
