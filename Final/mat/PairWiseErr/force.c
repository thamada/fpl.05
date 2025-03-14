/**
   # ハードウェア化する部分 
   #     1.加速度a[][]の初期化
   #     2.加速度a[][]の計算
*/

#include <stdio.h>
#include <math.h>
#include "nbodysim.h"

void force(double x[][DIM],
	   double m[],
	   double eps2,
	   double a[][DIM],
	   int n)
{
  int i,j,d;
  double dx[3];

  /* a[][]の初期化 */
  for(i=0;i<n;i++) for(d=0;d<3;d++) a[i][d] = 0.0;

  /* 相互作用の計算  */
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
	a[i][d] +=  m[j]*dx[d]/r3;
	a[j][d] += -m[i]*dx[d]/r3;
      }
    }
  }


}
