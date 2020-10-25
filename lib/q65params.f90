program q65params

  integer ntrp(5)
  integer nsps(5)
  data ntrp/15,30,60,120,300/
  data nsps/1800,3600,7200,15680,40960/

  write(*,1000)
1000 format('T/R   tsym   baud    BW     TxT    SNR'/39('-'))
  do i=1,5
     baud=12000.0/nsps(i)
     bw=65.0*baud
     tsym=1.0/baud
     txt=85.0*tsym
     snr=-27.0 + 10.0*log10(7200.0/nsps(i))
     write(*,1010) ntrp(i),tsym,baud,bw,txt,snr
1010 format(i3,2f7.3,3f7.1)
  enddo

end program q65params
