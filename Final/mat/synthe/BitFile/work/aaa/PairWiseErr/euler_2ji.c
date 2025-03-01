/** 
# xを1ステップ進める
# x(k+1) = x(k) + (dx/dt)(k)*dt + (1/2)(d2x/dt2)(k)*(dt)^2
*/

#include <stdio.h>
#include "nbodysim.h"

void euler_2ji(double dt,
	       double x[][DIM],
	       double v[][DIM],
	       double a[][DIM],
	       int n)
{
    int i,d;
    for(i=0;i<n;i++){
        for(d=0;d<3;d++){
	  x[i][d] = x[i][d] + v[i][d]*dt + a[i][d]*dt*dt/2.0;
	}
    }
}
