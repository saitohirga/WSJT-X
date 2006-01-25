      subroutine pfxdump(fname)
      character*(*) fname
      include 'pfx.f'

      open(11,file=fname,status='unknown')
      write(11,1001) pfx
 1001 format('Supported Add-on Prefixes:'/90('_')/(15(a5,1x)))
      write(11,1002) sfx
 1002 format(/'Supported Suffixes:'/44('_')/(11('/',a1,2x)))
      close(11)

      return
      end
