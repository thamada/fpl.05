/**
   # ハードウェア化する部分 
   #     1.加速度a[][]の初期化
   #     2.加速度a[][]の計算
*/

#include <stdio.h>
#include <math.h>
#include "nbodysim.h"
#define SIG 0.1
void force_LJ(double x[][DIM],
	   double m[],
	   double eps2,
	   double a[][DIM],
	   int n)
{
  int i,j,d;
  double dx[3];
  double sig12,sig6;
  sig12 = 12.0*pow(SIG,12.0);
  sig6 = 6.0*pow(SIG,6.0);


  /* a[][]の初期化 */
  for(i=0;i<n;i++) for(d=0;d<3;d++) a[i][d] = 0.0;

  /* 相互作用の計算  */
  for(i=0;i<n-1;i++){
    for(j=i+1;j<n;j++){
      double r2,r3,r13,r7;
      r2 = eps2;
      for(d=0;d<3;d++){
	dx[d] = x[j][d] - x[i][d];
	r2 += dx[d] * dx[d];
      }
      r3 = sqrt(r2)*r2;
      r13 = pow(r3,4.0)*sqrt(r2);
      r7  = pow(r3,2.0)*sqrt(r2);
      for(d=0;d<3;d++){
	//	a[i][d] +=  m[j]*dx[d]/r3  + m[j]*dx[d]*SIG*(1.0/r7-1.0/r13);
	//	a[j][d] += -m[i]*dx[d]/r3  - m[j]*dx[d]*SIG*(1.0/r7-1.0/r13);
	a[i][d] +=   m[j]*dx[d]*(0.1/r3+sig6/r7-sig12/r13);
	a[j][d] +=  -m[j]*dx[d]*(0.1/r3+sig6/r7-sig12/r13);
      }
    }
  }


}
