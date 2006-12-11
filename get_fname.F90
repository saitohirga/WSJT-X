
subroutine get_fname(hiscall,ntime,trperiod,lauto,fname)

#ifdef Win32
  use dfport
#endif

  external gmtime_r
  character hiscall*12,fname*24,tag*7
  integer ntime
  integer trperiod
  integer it(9)

  n1=ntime
  n2=(n1+2)/trperiod
  n3=n2*trperiod
  call gmtime_r(n3,it)
  it(5)=it(5)+1
  it(6)=mod(it(6),100)
  write(fname,1000) (it(j),j=6,1,-1)
1000 format('_',3i2.2,'_',3i2.2,'.WAV')
  tag=hiscall
  i=index(hiscall,'/')
  if(i.ge.5) tag=hiscall(1:i-1)
  if(i.ge.2.and.i.le.4) tag=hiscall(i+1:)
  if(hiscall(1:1).eq.' ' .or. lauto.eq.0) tag='Mon'
  i=index(tag,' ')
  fname=tag(1:i-1)//fname
  
  return
end subroutine get_fname
