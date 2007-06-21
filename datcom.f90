parameter (NSMAX=60*96000)          !Samples per 60 s file
integer*2 id                        !46 MB: raw data from Linrad timf2
character*80 fname80
common/datcom/nutc,newdat2,id(4,NSMAX,2),kbuf,nlost,nlen,fname80
