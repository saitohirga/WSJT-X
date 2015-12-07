# gnuplot script for "word error rate" figure
# run: gnuplot fig_wer2.gnuplot
# then: pdflatex fig_wer2.tex
#
set term epslatex standalone size 12cm,8cm
set output "fig_wer2.tex"
set xlabel "$E_s/N_o$ (dB)"
set ylabel "WER"
set style func linespoints
set key on top outside nobox
set tics in
set mxtics 2
set mytics 10 
set grid
set logscale y
plot "ftdata-2.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 7 title "FT", \
"bmdata-2.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 5 title 'BM'
