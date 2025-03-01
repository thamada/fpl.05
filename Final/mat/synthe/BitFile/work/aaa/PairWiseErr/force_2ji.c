/**
   Last Modified at 2003/11/09
   Author: Tsuyoshi Hamada
*/

#include <stdio.h>
#include <math.h>
#include "nbodysim.h"

void force_2ji(double x[][DIM],
	       double m[],
	       double v[][DIM],
	       double eps2,
	       double a_dt[][DIM],
	       int n)
{
  int i,j,d;
  double r2,r3,r5;
  double dx[3],dv[3];
  double pvr; /* ì‡êœ(vij,rij) */

  /* a_dt[][]ÇÃèâä˙âª */
  for(i=0;i<n;i++) for(d = 0;d<3;d++) a_dt[i][d] = 0.0;

  /* â¡ë¨ìx1äKî˜ï™ÇÃåvéZ */
  for(i=0;i<n-1;i++){
    for(j=i+1;j<n;j++){
      r2 = eps2;
      pvr = 0.0;
      for(d = 0;d<3;d++){
	dx[d] = x[j][d] - x[i][d];
	dv[d] = v[j][d] - v[i][d];
	r2  += dx[d] * dx[d];
	pvr += dx[d] * dv[d];
      }
      r3 = sqrt(r2)*r2;
      r5 = sqrt(r2)*r2*r2;
      for(d=0;d<3;d++){
	a_dt[i][d] +=  (m[j]*dv[d])/r3 - (m[j]*3.0*dx[d]*pvr)/r5;
	a_dt[j][d] += -(m[i]*dv[d])/r3 + (m[i]*3.0*dx[d]*pvr)/r5;
      }
    }
  }
}
