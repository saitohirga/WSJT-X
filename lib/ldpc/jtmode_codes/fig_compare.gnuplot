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
set format y "%1.0e"
plot [-1:6] [1e-6:1] \
   "198-72-peg-reg3.results" using 1:(1-$2/1000000) with linespoints lt 1 lw 2 pt 1, \
   "198-72-peg-reg3.results" using 1:($3/1000000) with linespoints lt 1 lw 2 pt 1, \
   "198-72-peg-reg4.results" using 1:(1-$2/1000000) with linespoints lt 2 lw 2 pt 2, \
   "198-72-peg-reg4.results" using 1:($3/1000000) with linespoints lt 2 lw 2 pt 2, \
   "198-72-peg-irreg-8x3-2x4.results" using 1:(1-$2/1000000) with linespoints lt 3 lw 2 pt 3, \
   "198-72-peg-irreg-8x3-2x4.results" using 1:($3/1000000) with linespoints lt 3 lw 2 pt 3, \
   "198-72-sf9.results" using 1:(1-$2/1000000) with linespoints lt 4 lw 2 pt 4, \
   "198-72-sf9.results" using 1:($3/1000000) with linespoints lt 4 lw 2 pt 4, \
   "compare.lab" with labels
exit
