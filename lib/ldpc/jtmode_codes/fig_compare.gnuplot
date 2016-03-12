# run: gnuplot fig_compare.gnuplot
# then: pdflatex fig_compare.tex

set term epslatex standalone size 6in,2*6/3in
set output "fig_compare.tex"
set xlabel "$E_b/N_0$ (dB)"
set ylabel "Word Error Rate"
set style func linespoints
set key off
set tics in
set mxtics 2
set mytics 10 
set grid
set logscale y
plot [-1:6] [1e-6:1] \
   "jtmskcode.results" using 1:(100000-$2)/100000 with linespoints lt 1 lw 2 pt 1, \
   "jtmskcode.results" using 1:($5/1000000) with linespoints lt 1 lw 2 pt 1, \
   "160-80-sf4.results" using 1:(1000000-$2)/1000000 with linespoints lt 2 lw 2 pt 2, \
   "160-80-sf4.results" using 1:($3/1000000) with linespoints lt 2 lw 2 pt 2, \
   "128-80-sf13.results" using 1:(1000000-$10)/1000000 with linespoints lt 3 lw 2 pt 3, \
   "128-80-sf13.results" using 1:($11/1000000) with linespoints lt 3 lw 2 pt 3, \
   "206-72-sf14.results" using 1:(1000000-$4)/1000000 with linespoints lt 4 lw 2 pt 4, \
   "206-72-sf14.results" using 1:($5/1000000) with linespoints lt 4 lw 2 pt 4, \
   "compare.lab" with labels
exit
