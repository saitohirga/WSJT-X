# gnuplot script for comparison to theoretical bounded distance decoding word error rate
# run: gnuplot fig_bodide.gnuplot
# then: pdflatex fig_bodide.tex
#
set term epslatex standalone size 6in,4in
set output "fig_bodide.tex"
set xlabel "$E_s/N_0$ (dB)"
set ylabel "Word Error Rate"
set style func linespoints
set key off
set tics in
set mxtics 2
set mytics 10 
set grid
set logscale y
plot [3:9] [1e-4:1] "bmdata.dat" using ($1+29.7):(1-$2) with linespoints pt 4 title 'BM', \
           "bmtheory25.dat" using 1:3 with linespoints pt 5 title 'theory25', \
           "bmtheory40.dat" using 1:3 with linespoints pt 5 title 'theory40', \
           "bmtheory43.dat" using 1:3 with linespoints pt 5 title 'theory43', \
           "ftdata-100000.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 4 title 'FT'
