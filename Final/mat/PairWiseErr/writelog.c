#include <stdio.h>
#include <math.h>
#include "nbodysim.h"

void writelog(double m[], double x[][DIM], double v[][DIM], double eps2 , int n)
{
  int i,j,d;
  double v2,r2;
  double dx[3];
  double Ep;        /* �e���q�̈ʒu�G�l���M�[ */
  double Em;        /* �e���q�̉^���G�l���M�[ */
  double Ea;        /* �e���q�̑S�͊w�I�G�l���M�[ */
  double a[NMAX][DIM];

  /* a[][]�̏����� */
  for(i=0;i<n;i++) for(d = 0;d<3;d++) a[i][d] = 0.0;

  for(i=0;i<n-1;i++){
    for(j=i+1;j<n;j++){
      double r2,r3;
      r2 = eps2;
      for(d=0;d<3;d++){
	dx[d] = x[j][d] - x[i][d];
	r2 += dx[d] * dx[d];
      }
      r3 = sqrt(r2)*r2;
      for(d=0;d<3;d++){
	a[i][d] =  m[j]*dx[d]/r3;
	a[j][d] = -m[i]*dx[d]/r3;
      }
    }
  }

  /* �n�̈ʒu�G�l���M�[ Ep ���v�Z����B */ 
  for(i=0;i<n;i++){
    Ep=0.0;
    for(j=0;j<n;j++){
      r2 = eps2;           /* ���΋��������� */
      for(d=0;d<3;d++){
	dx[d] = x[j][d] - x[i][d];
	r2 += dx[d] * dx[d];
      }
      if(i!=j) Ep -= m[i]*m[j]*(1/sqrt(r2));
    }

    Em=0.0;
    v2=0.0;    /* ��Α��x2��l������ */
    for(d=0;d<3;d++) v2 += v[i][d]*v[i][d];
    Em = 0.5 * m[i] * v2;

    //      Ea = Em + Ep;
    Ea = Ep;
    printf("%1.8e\t%1.8e\t%1.8e\t%d\t%1.8e\t%1.8e\t%1.8e\n",x[i][0],x[i][1],x[i][2],i,m[i],
	   (v[i][0]*v[i][0]+v[i][1]*v[i][1]),
	   (a[i][0]*a[i][0]+a[i][1]*a[i][1]));
  }

  return;
}
