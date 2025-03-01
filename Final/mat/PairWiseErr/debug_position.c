#include <stdio.h>
#include "nbodysim.h"

void debug_position(double x[][DIM], double time,int n)
{
    int i;
    for(i=0;i<n;i++){
      //        printf("%d,%e,%1.8e,%1.8e,%1.8e\n",i,t,x[i][0],x[i][1],x[i][2]);
        printf("%1.8e\t%1.8e\t%1.8e\t%1.1e\n",x[i][0],x[i][1],x[i][2],time);
    }
}

