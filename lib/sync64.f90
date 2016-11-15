subroutine sync64(dd,npts,nf1,nf2,nfqso,ntol,mode64,maxf1,dtx,f0,jpk,kpk,   &
     sync,c0)

  use timer_module, only: timer

  parameter (NMAX=60*12000)                  !Max size of raw data at 12000 Hz
  parameter (NSPS=3456)                      !Samples per symbol at 6000 Hz
  parameter (NSPC=7*NSPS)                    !Samples per Costas array
  real dd(NMAX)                              !Raw data
  real s1(0:NSPC-1)                          !Power spectrum of Costas 1
  real s2(0:NSPC-1)                          !Power spectrum of Costas 2
  real s3(0:NSPC-1)                          !Power spectrum of Costas 3
  real s0(0:NSPC-1)                          !Sum of s1+s2+s3
  real s0a(0:NSPC-1)                         !Best synchromized spectrum (saved)
  real s0b(0:NSPC-1)                         !tmp
  logical old_qra_sync
  integer icos7(0:6)                         !Costas 7x7 tones
  integer ipk0(1)
  complex cc(0:NSPC-1)                       !Costas waveform
  complex c0(0:720000)                       !Complex spectrum of dd()
  complex c1(0:NSPC-1)                       !Complex spectrum of Costas 1
  complex c2(0:NSPC-1)                       !Complex spectrum of Costas 2
  complex c3(0:NSPC-1)                       !Complex spectrum of Costas 3
  data icos7/2,5,6,0,4,1,3/                  !Costas 7x7 tone pattern
  data mode64z/-1/
  save

  if(mode64.ne.mode64z) then
     nsync=10
     inquire(file='old_qra_sync',exist=old_qra_sync)
     if(old_qra_sync) nsync=1
     twopi=8.0*atan(1.0)
     dfgen=mode64*12000.0/6912.0
     k=-1
     phi=0.
     do j=0,6                               !Compute complex Costas waveform
        dphi=twopi*nsync*icos7(j)*dfgen/6000.0
        do i=1,NSPS
           phi=phi + dphi
           if(phi.gt.twopi) phi=phi-twopi
           k=k+1
           cc(k)=cmplx(cos(phi),sin(phi))
        enddo
     enddo
     mode64z=mode64
  endif

  nfft1=672000
  nfft2=nfft1/2
  df1=12000.0/nfft1
  fac=2.0/nfft1
  c0(0:npts-1)=fac*dd(1:npts)
  c0(npts:nfft1)=0.
  call four2a(c0,nfft1,1,-1,1)             !Forward c2c FFT
  c0(nfft2/2+1:nfft2)=0.
  c0(0)=0.5*c0(0)
  call four2a(c0,nfft2,1,1,1)              !Inverse c2c FFT; c0 is analytic sig
  npts2=npts/2                            !Downsampled complex data length
  nfft3=NSPC
  nh3=nfft3/2
  df3=6000.0/nfft3
  
  fa=max(nf1,nfqso-ntol)
  fb=min(nf2,nfqso+ntol)
  iaa=max(maxf1,nint(fa/df3))
  ibb=min(NSPC-1-maxf1,nint(fb/df3))

  maxtol=max(ntol,500)
  fa=max(nf1,nfqso-maxtol)
  fb=min(nf2,nfqso+maxtol)
  ia=max(maxf1,nint(fa/df3))
  ib=min(NSPC-1-maxf1,nint(fb/df3))
  id=0.1*(ib-ia)

  iz=ib-ia+1
  sync=0.
  jpk=0
  ja=0
  jb=6*5000
  jstep=100
  ka=-maxf1
  kb=maxf1
  ipk=0
  kpk=0
!  nadd=(7*mode64)/2
!  nadd=7*mode64
  nadd=10*mode64
  if(mod(nadd,2).eq.0) nadd=nadd+1       !Make nadd odd
!  nskip=max(14,2*mode64)
  nskip=max(14,nadd)
    
  do j1=ja,jb,jstep
     call timer('sync64_1',0)
     j2=j1 + 39*NSPS
     j3=j1 + 77*NSPS
     c1=1.e-4*c0(j1:j1+NSPC-1) * conjg(cc)
     call four2a(c1,nfft3,1,-1,1)
     c2=1.e-4*c0(j2:j2+NSPC-1) * conjg(cc)
     call four2a(c2,nfft3,1,-1,1)
     c3=1.e-4*c0(j3:j3+NSPC-1) * conjg(cc)
     call four2a(c3,nfft3,1,-1,1)
     s0=0.
     s1=0.
     s2=0.
     s3=0.
     do i=ia,ib
        freq=i*df3
        s1(i)=real(c1(i))**2 + aimag(c1(i))**2
        s2(i)=real(c2(i))**2 + aimag(c2(i))**2
        s3(i)=real(c3(i))**2 + aimag(c3(i))**2
     enddo
     call timer('sync64_1',1)

     call timer('sync64_2',0)
     do k=ka,kb
        s0(ia:ib)=s1(ia-k:ib-k) + s2(ia:ib) + s3(ia+k:ib+k)
        s0(:ia-1)=0.
        s0(ib+1:)=0.
        if(nadd.ge.3) then
           do ii=1,3
              s0b(ia:ib)=s0(ia:ib)
              call smo(s0b(ia:ib),iz,s0(ia:ib),nadd)
        
           enddo
        endif
        call smo121(s0(ia:ib),iz)
        call averms(s0(ia+id:ib-id),iz-2*id,nskip,ave,rms)
        s=(maxval(s0(ia:ib))-ave)/rms
        ipk0=maxloc(s0(ia:ib))
        ip=ipk0(1) + ia - 1
        if(s.gt.sync .and. ip.ge.iaa .and. ip.le.ibb) then
           jpk=j1
           s0a=(s0-ave)/rms
           sync=s
           dtx=jpk/6000.0 - 1.0
           ipk=ip
           f0=ip*df3
           kpk=k
        endif
     enddo
     call timer('sync64_2',1)
  enddo
  sync=sync-3.5

  ja=max(0,jpk-2*jstep)
  jb=min(336000-NSPC,jpk+2*jstep)
  jstep=10

  s0a=s0a+2.0
  write(17) ia,ib,s0a(ia:ib)                !Save data for red curve
  close(17)

  return
end subroutine sync64
