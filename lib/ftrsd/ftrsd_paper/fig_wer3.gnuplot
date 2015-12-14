# gnuplot script for AWGN vs Rayleigh figure
#
set term epslatex standalone size 16cm,8cm
set output "fig_wer3.tex"
set xlabel "$E_s/N_o$ (dB)"
set ylabel "WER"
set style func linespoints
set key on top outside nobox
set tics in
set mxtics 2
set mytics 10 
set grid
set logscale y
#set format y "10^{%L}"
plot "ftdata-1000-rf.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 7 title "FT-1K-RF", \
"bmdata-rf.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 5 title 'BM-RF', \
"ftdata-10000.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 7 title 'FT-10K-AWGN', \
"bmdata.dat" using ($1+29.7):(1-$2) with linespoints pt 5 title 'BM-AWGN'
