# Gnu Octave script to calculate
# cross correlation between 2 Costas arrays
costas1=[2,5,6,0,4,1,3];
costas2=[3,1,4,0,6,5,2];
array1=zeros(7,7);
array2=zeros(7,7);
for i=1:7
  array1(i,costas1(i)+1)=1;
  array2(i,costas2(i)+1)=1;
endfor
xcorr2(array1,array1,"none")
xcorr2(array2,array2,"none")
xcorr2(array1,array2,"none")

