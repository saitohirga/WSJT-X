! Variable             Purpose                              Set in Thread
!-------------------------------------------------------------------------
integer*2 nfmt2        !Standard header for *.WAV file         Decoder
integer*2 nchan2
integer*2 nbitsam2
integer*2 nbytesam2
integer*4 nchunk
integer*4 lenfmt
integer*4 nsamrate
integer*4 nbytesec
integer*4 ndata
character*4 ariff
character*4 awave
character*4 afmt
character*4 adata

common/gcom3/ariff,nchunk,awave,afmt,lenfmt,nfmt2,nchan2,nsamrate, &
     nbytesec,nbytesam2,nbitsam2,adata,ndata

!### volatile /gcom3/
