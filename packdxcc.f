      subroutine packdxcc(c,ng,ldxcc)

      character*3 c
      logical ldxcc

      parameter (NZ=303)
      character*5 pfx(NZ)
      data pfx/
     +  '1A   ','1S   ','3A   ','3B6  ','3B8  ','3B9  ','3C   ','3C0  ',
     +  '3D2  ',                '3DA  ','3V   ','3W   ','3X   ','3Y   ',
     +          '4J   ','4L   ','4S   ','4U1  ',                '4W   ',
     +  '4X   ','5A   ','5B   ','5H   ','5N   ','5R   ','5T   ','5U   ',
     +  '5V   ','5W   ','5X   ','5Z   ','6W   ','6Y   ','7O   ','7P   ',
     +  '7Q   ','7X   ','8P   ','8Q   ','8R   ','9A   ','9G   ','9H   ',
     +  '9J   ','9K   ','9L   ','9M2  ','9M6  ','9N   ','9Q   ','9U   ',
     +  '9V   ','9X   ','9Y   ','A2   ','A3   ','A4   ','A5   ','A6   ',
     +  'A7   ','A9   ','AP   ','BS7  ','BV   ','BV9  ','BY   ','C2   ',
     +  'C3   ','C5   ','C6   ','C9   ','CE   ','CE0  ',                
     +  'CE9  ','CM   ','CN   ','CP   ','CT   ','CT3  ','CU   ','CX   ',
     +  'CY0  ','CY9  ','D2   ','D4   ','D6   ','DL   ','DU   ','E3   ',
     +  'E4   ','EA   ','EA6  ','EA8  ','EA9  ','EI   ','EK   ','EL   ',
     +  'EP   ','ER   ','ES   ','ET   ','EU   ','EX   ','EY   ','EZ   ',
     +  'F    ','FG   ','FH   ','FJ   ','FK   ',        'FM   ','FO   ',
     +                          'FP   ','FR   ',                        
     +  'FT5  ',                'FW   ','FY   ','M    ','MD   ','MI   ',
     +  'MJ   ','MM   ',        'MU   ','MW   ','H4   ','H40  ','HA   ',
     +  'HB   ','HB0  ','HC   ','HC8  ','HH   ','HI   ','HK   ','HK0  ',
     +          'HL   ','HM   ','HP   ','HR   ','HS   ','HV   ','HZ   ',
     +  'I    ','IG9  ','IS   ','IT9  ','J2   ','J3   ','J5   ','J6   ',
     +  'J7   ','J8   ','JA   ','JD   ',        'JT   ','JW   ',        
     +  'JX   ','JY   ','K    ','KG4  ','KH0  ','KH1  ','KH2  ','KH3  ',
     +  'KH4  ','KH5  ',        'KH6  ','KH7  ','KH8  ','KH9  ','KL   ',
     +  'KP1  ','KP2  ','KP4  ','KP5  ','LA   ','LU   ','LX   ','LY   ',
     +  'LZ   ','OA   ','OD   ','OE   ','OH   ','OH0  ','OJ0  ','OK   ',
     +  'OM   ','ON   ','OX   ','OY   ','OZ   ','P2   ','P4   ','PA   ',
     +  'PJ2  ','PJ7  ','PY   ','PY0  ',                'PZ   ','R1F  ',
     +  'R1M  ','S0   ','S2   ','S5   ','S7   ','S9   ','SM   ','SP   ',
     +  'ST   ','SU   ','SV   ',        'SV5  ','SV9  ','T2   ','T30  ',
     +  'T31  ','T32  ','T33  ','T5   ','T7   ','T8   ','T9   ','TA   ',
     +  'TA1  ','TF   ','TG   ','TI   ','TI9  ','TJ   ','TK   ','TL   ',
     +  'TN   ','TR   ','TT   ','TU   ','TY   ','TZ   ','UA   ','UA2  ',
     +  'UA9  ','UK   ','UN   ','UR   ','V2   ','V3   ','V4   ','V5   ',
     +  'V6   ','V7   ','V8   ','VE   ','VK   ','VK0  ',        'VK9  ',
     +                                          'VP2  ',                
     +  'VP5  ','VP6  ',        'VP8  ',                                
     +  'VP9  ','VQ9  ','VR   ','VU   ','VU4  ','VU7  ','XE   ','XF4  ',
     +  'XT   ','XU   ','XW   ','XX9  ','XZ   ','YA   ','YB   ','YI   ',
     +  'YJ   ','YK   ','YL   ','YN   ','YO   ','YS   ','YU   ','YV   ',
     +  'YV0  ','Z2   ','Z3   ','ZA   ','ZB   ','ZC4  ','ZD7  ','ZD8  ',
     +  'ZD9  ','ZF   ','ZK1  ',        'ZK2  ','ZK3  ','ZL   ','ZL7  ',
     +  'ZL8  ','ZL9  ','ZP   ','ZS   ','ZS8  '/

      ldxcc=.false.
      ng=0
      do i=1,NZ
         if(pfx(i)(1:3).eq.c) go to 10
      enddo
      go to 20

 10   ng=180*180+61+i
      ldxcc=.true.

 20   return
      end
