/*
 * by Tsuyoshi Hamada 
 * thamada@riken.jp
 * for PGR
 * Modify       : 2005/01/05 (Wed)
 * Coding Finish: 2004/05/13 (Wed)
 * Coding Start : 2004/02/25 (Wed)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "nbodysim.h"
#include "b3api.h"

#define NPIPES_IN_A_CHIP 16
//#define NPIPES_IN_A_CHIP 1
#define NCHIPS_ON_A_BOARD 4

#define NMAN 8
#define NACC 64
#define NPOS 32
#define xsize (100.0)
#define mmin (1.220703125e-04)
#define xoffset (xsize/2.0)
#define xscale (pow(2.0,(double)NPOS)/xsize)
//#define mscale (pow(2.0,63.95)/mmin)  /* -- for G3 -- */
#define mscale (pow(2.0,95.38)/mmin)    /* -- for G5 -- */
#define escale (xscale*xscale)
//#define foffset (pow(2.0,19.0))       /* -- for G3 -- */
#define foffset (pow(2.0,23.0))         /* -- for G5 -- */
#define fscale (-xscale*xscale*foffset/mscale)


#include "e_time.h"

//static unsigned nfoget = 0;
//void show_nfoget(){fprintf(stderr,"nfoget = %d\n",nfoget);}

void force_vhd(
	 double x[][3],
	 double m[],
	 double eps2,
	 double a[][3],
	 int n)
{
  double dum_i,dum_j,dum_c,dum_f;

  static int init=0;
  int i,j,k;
  int devid=0;
  static int chip_sel;
  unsigned int npipe,npipe_per_chip;
  unsigned int nchip;
  unsigned int jdata[NMAX][JDIM];

  if(init==0){
    b3open(devid);
    b3reset(devid);
    pgr_set_npipe_per_chip(devid,NPIPES_IN_A_CHIP); // 2005/01/05
    lap_clean();
    init=1;
  }

  npipe_per_chip = NPIPES_IN_A_CHIP;
  nchip = NCHIPS_ON_A_BOARD;
  npipe = nchip*npipe_per_chip;

  // -------- JPSET PUT  -----------------------------------------------
  dum_j = e_time();
  pgr_setjpset_offset_reset(devid);
  for(j=0;j<n;j++){
    unsigned int xj,yj,zj,mj;
    /* -- for G5 --        */
    xj = ((unsigned int) ((x[j][0] + xoffset ) * xscale + 0.5)) & 0xffffffff ;
    yj = ((unsigned int) ((x[j][1] + xoffset ) * xscale + 0.5)) & 0xffffffff ;
    zj = ((unsigned int) ((x[j][2] + xoffset ) * xscale + 0.5)) & 0xffffffff ;

    if(m[j] == 0.0){
      mj = 0;
    }else if(m[j] > 0.0){
      mj = (((int)(pow(2.0,(double)NMAN)*log(m[j]*mscale)/log(2.0))) & 0x7fff) | 0x8000;
    }else{
      mj = (((int)(pow(2.0,(double)NMAN)*log(-m[j]*mscale)/log(2.0))) & 0x7fff) | 0x18000;
    }



    /* -- for G5 -- */
    jdata[j][0] = 0xffffffff & xj;
    jdata[j][1] = 0xffffffff & yj;
    jdata[j][2] = 0xffffffff & zj;
    jdata[j][3] = 0x1ffff & mj;
    //    for(i=4 ; i<JDIM; i++) jdata[j][i] = 0xffffffff;
    pgr_setjpset_one(devid, j, jdata[j]);
  }
  //  pgr_setjpset(devid, jdata, n);

  lap_j += e_time() - dum_j;

  for(i = 0;i < n; i+=npipe){
    unsigned int idata[(1<<12)];
    int nn,ii;
    if((i+npipe)>n){
      nn = n - i;
    }else{
      nn = npipe;
    }

    // -------- IPSET PUT  -----------------------------------------------
    dum_i=e_time();

    for(ii = 0; ii < nn; ii+=npipe_per_chip){
      unsigned ichip,np,ip;
      ichip = ii/npipe_per_chip;
      if((ii+npipe_per_chip)>nn){
	np = nn - ii;
      }else{
	np = npipe_per_chip;
      }
      for(ip=0;ip<np;ip++){
	idata[0|(ip<<XI_AWIDTH)] = ((unsigned int) ((x[i+ii+ip][0] + xoffset)*xscale + 0.5)) & 0xffffffff ;
	idata[1|(ip<<XI_AWIDTH)] = ((unsigned int) ((x[i+ii+ip][1] + xoffset)*xscale + 0.5)) & 0xffffffff ;
	idata[2|(ip<<XI_AWIDTH)] = ((unsigned int) ((x[i+ii+ip][2] + xoffset)*xscale + 0.5)) & 0xffffffff ;
	if(eps2 == 0.0){
	  idata[3|(ip<<XI_AWIDTH)] = 0;
	}else if(eps2 > 0.0){
	  idata[3|(ip<<XI_AWIDTH)] = (((int)(pow(2.0,(double)NMAN)*log(eps2*escale)/log(2.0))) & 0x7fff) | 0x8000;
	}else{
	  idata[3|(ip<<XI_AWIDTH)] = (((int)(pow(2.0,5.0)*log(-eps2*escale)/log(2.0))) & 0x7fff) | 0x18000;
	}
      }
      pgr_setipset_ichip(devid, ichip, idata, np); // send ipsets of a chip 
    }
    lap_i += e_time()-dum_i;

    // -------- START CALC -----------------------------------------------
    dum_c = e_time();
    pgr_start_calc(devid, n);
    lap_c += e_time()-dum_c;

    // -------- FOSET GET  -----------------------------------------------
    dum_f = e_time();
    for(ii = 0; ii < nn; ii+=npipe){
      unsigned np,ip;
      unsigned long long int fdata[0x1000][FDIM];
      long long int sx;
      long long int sy;
      long long int sz;
      if((ii+npipe)>nn){
	np = nn - ii;
      }else{
        np = npipe;
      }
      pgr_getfoset(devid, fdata);   // fdata becomes unsigned long long array !
      //      fprintf(stderr, "%i %i\n", i, ii);
      for(ip=0;ip<np;ip++){
        sx = (long long int)fdata[ip][0];
        sy = (long long int)fdata[ip][1];
        sz = (long long int)fdata[ip][2];
        a[i+ii+ip][0] = ((double)(sx<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
        a[i+ii+ip][1] = ((double)(sy<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
        a[i+ii+ip][2] = ((double)(sz<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));

	//	printf("%d\t",i+ii+ip);
	//	printf("%llx\t",sx);
	//	printf("%llx\t",sy);
	//	printf("%llx\n",sz);
      }
    }
    //    exit(0);
    lap_f += e_time()-dum_f;
  }

}

