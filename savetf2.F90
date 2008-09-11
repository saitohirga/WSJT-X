subroutine savetf2(id,nsave,ntime,nutc,savedir)

#ifdef CVF
  use dfport
#endif

  parameter (NZ=60*96000)
  parameter (NSPP=174)
  parameter (NPKTS=NZ/NSPP)
  integer*2 id(4,NZ)
  real*4 ss(NPKTS),ss2(60)
  real*8 dt,t,t2
  character*80 savedir,fname
  character cdate*8,ctime2*10,czone*5
  integer it(9),itt(8)

  if(nsave.eq.1) then
#ifdef CVF
     n2=ntime/60
     n3=(n2-1)*60
     call gmtime(n3,it)
     it(5)=it(5)+1
#else
     call date_and_time(cdate,ctime2,czone,itt)
     it(6)=itt(1)
     it(5)=itt(2)
     it(4)=itt(3)
     it(3)=itt(5)-itt(4)/60
     if(it(3).lt.0) it(3)=it(3)+24
     if(it(3).ge.24) it(3)=it(3)-24
     it(2)=itt(6)
     !  it(1)=itt(7)
     it(1)=0
#endif
     it(6)=mod(it(6),100)
     write(fname,1000) (it(j),j=6,2,-1)
1000 format('/',3i2.2,'_',2i2.2,'.tf2')
     do i=80,1,-1
        if(savedir(i:i).ne.' ') go to 1
     enddo

1    iz=i
     fname=savedir(1:iz)//fname
#ifdef CVF
     open(17,file=fname,status='unknown',form='binary',err=998)
#else
     open(17,file=fname,status='unknown',access='stream',err=998)
#endif
     write(17) id
     close(17)


  else
     dt=NSPP/96000.d0
     t=0.d0
     nh=nutc/100
     nm=mod(nutc,100)
     t2=3600*nh + 60*nm
     fac=1.0/(4.0*NSPP)
     do i=1,NPKTS
        s=0.
        do n=1,NSPP
           s=s + float(int(id(1,i)))**2 + float(int(id(2,i)))**2 +     &
                float(int(id(3,i)))**2 + float(int(id(4,i)))**2 
        enddo
        ss(i)=fac*s
        t=t+dt
        t2=t2+dt
        if(nsave.eq.3) write(24,1010) t,t2,ss(i)
1010    format(f9.6,f15.6,f10.3)
     enddo

     if(nsave.eq.2) then
        dt2=551*dt
        t=0.d0
        t2=3600*nh + 60*nm
        k=0
        do i=1,60
           s=0.
           ns=0
           do n=1,551
              k=k+1
              s=s + ss(k)
              if(ss(k).gt.0.0) ns=ns+1
           enddo
           ss2(i)=s/ns
           t=t+dt
           t2=t2+dt2
           write(25,1010) t,t2,ss2(i)
        enddo
     endif
  endif
  go to 999

998 print*,'Cannot open file:'
  print*,fname

999 return
end subroutine savetf2
