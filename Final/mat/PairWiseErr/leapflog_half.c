/** 
# v��1/2���ƥå׿ʤ��
# v(k+1/2) = v(k) + a(k)*dt/2
*/

#include <stdio.h>
#include "nbodysim.h"

void leapflog_half(double dt, double v[][DIM], double a[][DIM], int n)
{
    int i,d;
    for(i=0;i<n;i++)
      for(d=0;d<3;d++)
	v[i][d] = v[i][d] + (a[i][d]*dt)/2.0;
}
