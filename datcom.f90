parameter (NSMAX=60*96000)          !Samples per 60 s file
integer*2 id                        !46 MB: raw data from Linrad timf2
character*80 fname80
common/datcom/id(4,NSMAX,2),nutc,newdat2,kbuf,kk,kkdone,nlost,   &
     nlen,fname80
