# gnuplot script for "word error rate" figure
# run: gnuplot fig_wer2.gnuplot
# then: pdflatex fig_wer2.tex
#
set term epslatex standalone size 16cm,10cm
set output "fig_wer2.tex"
set xlabel "$E_s/N_o$ (dB)"
set x2label "SNR in 2500 Hz (dB)"
set ylabel "WER"
#set autoscale xfix
#set autoscale x2fix
set style func linespoints
set key on top outside nobox
set tics in
set mxtics 2
set mytics 10 
set grid ytics
set logscale y
set x2tics out
set xtics nomirror
set mx2tics 2
#set xrange [3:13]
#set x2range [(3-29.7):(13-29.7)]
set xrange [4:7.5]
set x2range [(4-29.7):(7.5-29.7)]
set yrange [0.001:1.0]
plot "ftdata-1000-rf.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 4 title "FT-1K-RF", \
"ftdata-100-rf.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 5 title 'FT-100-RF', \
"kvasd-7999-rf.dat" using ($1+29.7):(1-$2) every ::1 with linespoints pt 6 title 'KV-8-RF', \
"kvasd-11999-rf.dat" using 1:(1-$2) every ::1 with linespoints pt 7 title 'KV-12-RF' axes x2y1
#"bmdata-rf.dat" using 1:(1-$2) every ::1 with linespoints pt 8 title 'BM-RF' axes x2y1
