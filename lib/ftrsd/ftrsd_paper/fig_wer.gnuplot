# gnuplot script for "Percent copy" figure
# run: gnuplot fig_wer.gnuplot
# then: pdflatex fig_wer.tex
#
set term epslatex standalone size 6in,4in
set output "fig_wer.tex"
set xlabel "$E_b/N_0$ (dB)"
set ylabel "Word Error Rate"
set style func linespoints
set key off
set tics in
set mxtics 2
set mytics 10 
set grid
set logscale y
plot [3:9] "ftdata-100000.dat" using ($1+29.1):(1-$2) with linespoints pt 7 title 'FT-100K', \
     "kvasd-11999.dat" using ($1+29.1):(1-$2) with linespoints pt 8 title 'KV-11.999', \
     "bmdata.dat" using ($1+29.1):(1-$2) with linespoints pt 7 title 'BM', \
     "wer.lab" with labels
