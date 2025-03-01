#include <stdio.h>
#include "nbodysim.h"

void debug_func_force(double x[][DIM],double m[], double eps2,double a[][DIM],int n)
{
    int i,j;

    printf("-------------------------------\n");
    printf("The debuging routine is called.\n");
    printf("-------------------------------\n");
    printf("n = %d\n",n);
    printf("eps2 = %e\n",eps2);

    for(i=0;i<n;i++){
        printf("---\n");
        printf("particle %d\n",i);
        printf("m[%d] = %e\n",i,m[i]);
        for(j=0;j<3;j++) printf("x[%d][%d] = %e\n",i,j,x[i][j]);
        for(j=0;j<3;j++) printf("a[%d][%d] = %e\n",i,j,a[i][j]);
    }
}

