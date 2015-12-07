# gnuplot script for "Percent copy" figure
# run: gnuplot fig_wer.gnuplot
# then: pdflatex fig_wer.tex
#
set term epslatex standalone size 12cm,8cm
set output "fig_wer.tex"
set xlabel "$E_s/N_o$ (dB)"
set ylabel "WER"
set style func linespoints
set key on top outside nobox
set tics in
set mxtics 2
set mytics 10 
set grid
set logscale y
plot "ftdata-10000-tight.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 5 title 'FT-1', \
     "ftdata-100000-loose.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 5 title 'FT-2', \
     "bmdata.dat" using ($1+29.7):(1-$2) with linespoints pt 7 title 'BM'
