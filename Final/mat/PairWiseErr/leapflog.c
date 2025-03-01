/** 
# x��1���ƥå׿ʤ��
# x(k+1) = x(k) + v(k+1/2)*dt
*/

#include <stdio.h>
#include "nbodysim.h"

void leapflog(double dt,double x[][DIM],double v[][DIM],int n)
{
    int i,d;
    for(i=0;i<n;i++)
        for(d=0;d<3;d++)
            x[i][d] = x[i][d]+v[i][d]*dt;
}
