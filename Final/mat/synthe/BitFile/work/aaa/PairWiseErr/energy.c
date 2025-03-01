#include <stdio.h>
#include <math.h>
#include "nbodysim.h"

double energy(double m[], double x[][DIM], double v[][DIM], double eps2 , int n)
{
    int i,j,d;
    double v2,r2;
    double dx[3];
    double Ep;  /* �n�̈ʒu�G�l���M�[ */
    double Em;  /* �n�̉^���G�l���M�[ */
    double Ea;  /* �n�̑S�͊w�I�G�l���M�[ */


    /* �n�̈ʒu�G�l���M�[ Ep ���v�Z����B */ 
    Ep=0.0;
    for(i=0;i<n-1;i++){
        for(j=i+1;j<n;j++){
            r2 = eps2;           /* ���΋��������� */
            for(d=0;d<3;d++){
                dx[d] = x[j][d] - x[i][d];
                r2 += dx[d] * dx[d];
            }
            Ep -= m[i] * m[j] * ( 1/sqrt(r2)  );
        }
    }


    /* �n�̉^���G�l���M�[ Em ���v�Z����B */ 
    Em=0.0;
    for(i=0;i<n;i++){
        v2=0.0;    /* ��Α��x2��l������ */
        for(d=0;d<3;d++){
            v2 += v[i][d]*v[i][d];
        }
        Em += 0.5 * m[i] * v2;
    }

    /* �n�̑S�͊w�I�G�l���M�[ Ea ���v�Z����B */ 
    Ea=0.0;
    Ea = Em + Ep;

/*    printf("Emove=%1.6e,   Epot=%1.3e,   Eall=%1.25e\n",Em,Ep,Ea);*/
/*    printf("%e\n",Ea);*/

    return Ea;
}
