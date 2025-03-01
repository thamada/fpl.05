#include <stdio.h>
#include <stdlib.h> // rand()
#include <math.h>
#define XSIZE (100.0)


int main()
{
  double x;
  int xi;

  srand(0x1192296);

  for(j=0;j<n;j++){
    x = XSIZE*rand()/(RAND_MAX+1.0);
    xi = ((unsigned int)( (x+(XSIZE/2.0))*(pow(2.0,32.0)/XSIZE) + 0.5)) & 0xffffffff;
  }



}
