#include<stdio.h>
#define LONG long long int 
// bit level check between emulator and hardware(pg2)
void check_pg2emu(LONG accel[][3],LONG accel_pg2[][3],int n)
{
  int i,j;
  for(i=0;i<n;i++){
    for(j=0;i<3;j++){
      LONG a_emu,a_pg2;
      a_emu = accel[i][j];
      a_pg2 = accel_pg2[i][j];
      if(a_emu != a_pg2){fprintf(stderr,"error\n");}
    }
  }
}
