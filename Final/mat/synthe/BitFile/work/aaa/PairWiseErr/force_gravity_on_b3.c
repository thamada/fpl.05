/*
 * by Tsuyoshi Hamada 
 * hamada@provence.c.u-tokyo.ac.jp
 * for G3, G5
 * Coding Start : 2004/02/25 (Wed)
 * Coding Finish: 2004/05/13 (Wed)

   adr | 31 - 19 | 18 - 16 | 15 - 0  |
        | (13bit) |  (3bit) | (16bit) |
    ----+---------+---------+---------+
             -      command    adr
                       0       jadr    : jdata (R/W)
                       1       iadr    : idata (R/W)
                       2       adro    : fo    (R)
                       3         -     : setn  (R/W)
                       4         -     : calc start (W)
                       5         0     : calc status(R/W) : data(0):  R=0 , W=1
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "b3grav.h"
#define ULL unsigned long long int

//#define DEBUG 1

#define NPIPES_IN_A_CHIP 1
//#define NPIPES_IN_A_CHIP 25

#define NCHIPS_ON_A_BOARD 4

#define NMAN 8
#define NACC 64
#define NPOS 32
#define xsize (100.0)


//#define mmin (9.765625e-04)
#define mmin (1.220703125e-04)
//#define mmin (2.44140625e-04)
//#define mmin (4.8828125e-4)
//#define mmin (6.103515e-05)

#define xoffset (xsize/2.0)
#define xscale (pow(2.0,(double)NPOS)/xsize)
//#define mscale (pow(2.0,63.95)/mmin)  /* -- for G3 -- */
#define mscale (pow(2.0,95.38)/mmin)    /* -- for G5 -- */
#define escale (xscale*xscale)
//#define foffset (pow(2.0,19.0))       /* -- for G3 -- */
#define foffset (pow(2.0,23.0))         /* -- for G5 -- */
#define fscale (-xscale*xscale*foffset/mscale)



void force_gravity_on_b3(
	 double x[][3],
	 double m[],
	 double eps2,
	 double a[][3],
	 int n)
{
  static int init=0;
  int i,j,k;
  int devid=0;
  static int chip_sel;
  unsigned int npipe,npipe_per_chip;
  unsigned int nchip;
  unsigned int dbg_jd[80000];
  unsigned int dbg_id[80000][4];
  unsigned long long int dbg_fo[80000][4];

  if(init==0){
    devid=0;
    b3_init(devid);                              // Open Biolar Board
    //    b3_init_config(devid,"ddr_top.bit");   // Open Biolar Board
    init=1;
  }

  npipe_per_chip = NPIPES_IN_A_CHIP;
  nchip = NCHIPS_ON_A_BOARD;
  npipe = nchip*npipe_per_chip;

  // --- debug chip select ---
  //  chip_sel <<= 1;
  //  if(chip_sel==0x10) chip_sel=1;
  //--------------------------

  // jpw_we
  b3_reset_jmem_adr();

  for(j=0;j<n;j++){
    unsigned int xj,yj,zj,mj;
    unsigned int jdata[4];
    unsigned int nword;

    /* -- for G3 -- */
    /*
    xj = ((unsigned int) ((x[j][0] + xoffset ) * xscale + 0.5)) & 0xfffff ;
    yj = ((unsigned int) ((x[j][1] + xoffset ) * xscale + 0.5)) & 0xfffff ;
    zj = ((unsigned int) ((x[j][2] + xoffset ) * xscale + 0.5)) & 0xfffff ;
    if(m[j] == 0.0){
      mj = 0;
    }else if(m[j] > 0.0){
      mj = (((int)(pow(2.0,(double)NMAN)*log(m[j]*mscale)/log(2.0))) & 0xfff) | 0x1000;
    }else{
      mj = (((int)(pow(2.0,(double)NMAN)*log(-m[j]*mscale)/log(2.0))) & 0xfff) | 0x3000;
    }
    */
    /* -- for G5 -- */
    //    xj = ((unsigned int) ((x[j][0] + xoffset ) * xscale + 0.5)) & 0xffffffff ;
    xj = ((int)(x[j][0]*xscale+0.5)) & 0xffffffff ;
    yj = ((int)(x[j][1]*xscale+0.5)) & 0xffffffff ;
    zj = ((int)(x[j][2]*xscale+0.5)) & 0xffffffff ;
    if(m[j] == 0.0){
      mj = 0;
    }else if(m[j] > 0.0){
      mj = (((int)(pow(2.0,(double)NMAN)*log(m[j]*mscale)/log(2.0))) & 0x7fff) | 0x8000;
    }else{
      mj = (((int)(pow(2.0,(double)NMAN)*log(-m[j]*mscale)/log(2.0))) & 0x7fff) | 0x18000;
    }

    jdata[0] = 0x0;
    jdata[1] = 0x0;
    jdata[2] = 0x0;
    jdata[3] = 0x0;

    /* -- for G3 -- */
    /*
    jdata[0] = ((0xfffff & xj)<<0)  | ((0xfff   & yj)<<20);   // lower part of jdata
    jdata[1] = ((0xff    & (yj>>12)) | ((0xfffff & zj)<<8) | (0xf&mj)<<28);  // higer part of jdata
    jdata[2] = 0x7ff&(mj>>4);
    jdata[3] = 0x0;
    */

    /* -- for G5 -- */
    jdata[0] = 0xffffffff & xj;
    jdata[1] = 0xffffffff & yj;
    jdata[2] = 0xffffffff & zj;
    jdata[3] = 0x1ffff & mj;

#ifdef DEBUG
    dbg_jd[3*j+0]=jdata[0];
    dbg_jd[3*j+1]=jdata[1];
    dbg_jd[3*j+2]=jdata[2];
#endif
    nword = 4;
    b3_set_jdata(devid,nword,jdata);
  }


  for(i=0;i<n;i+=npipe){
    //  for(i=0;i<1;i+=npipe){
    int nn,ii;
    if((i+npipe)>n){
      nn = n - i;
    }else{
      nn = npipe;
    }

    // ipw_we (0)
    for(ii=0;ii<nn;ii++){
      unsigned int xi,yi,zi,ieps2;
      unsigned int ipipe;
      // --- chip select ---
      {
	unsigned int ichip;
	ichip = ii/npipe_per_chip;
	chip_sel = 0x1<<ichip;
      }

      /* -- for G3 -- */
      /*
      xi = ((unsigned int) ((x[i+ii][0] + xoffset)*xscale + 0.5)) & 0xfffff ;
      yi = ((unsigned int) ((x[i+ii][1] + xoffset)*xscale + 0.5)) & 0xfffff ;
      zi = ((unsigned int) ((x[i+ii][2] + xoffset)*xscale + 0.5)) & 0xfffff ;
      if(eps2 == 0.0){
	ieps2 = 0;
      }else if(eps2 > 0.0){
	ieps2 = (((int)(pow(2.0,(double)NMAN)*log(eps2*escale)/log(2.0))) & 0xfff) | 0x1000;
      }else{
	ieps2 = (((int)(pow(2.0,5.0)*log(-eps2*escale)/log(2.0))) & 0xfff) | 0x3000;
      }
      */
      /* -- for G5 -- */
      xi = ((int)(x[i+ii][0]*xscale+0.5)) & 0xffffffff ;
      yi = ((int)(x[i+ii][1]*xscale+0.5)) & 0xffffffff ;
      zi = ((int)(x[i+ii][2]*xscale+0.5)) & 0xffffffff ;
      if(eps2 == 0.0){
	ieps2 = 0;
      }else if(eps2 > 0.0){
	ieps2 = (((int)(pow(2.0,(double)NMAN)*log(eps2*escale)/log(2.0))) & 0x7fff) | 0x8000;
      }else{
	ieps2 = (((int)(pow(2.0,5.0)*log(-eps2*escale)/log(2.0))) & 0x7fff) | 0x18000;
      }



      ipipe = ii%npipe_per_chip;
      b3_set_idata(devid,chip_sel,ipipe,0,xi);
      b3_set_idata(devid,chip_sel,ipipe,1,yi);
      b3_set_idata(devid,chip_sel,ipipe,2,zi);
      b3_set_idata(devid,chip_sel,ipipe,3,ieps2);

#ifdef DEBUG
      dbg_id[i+ii][0] = xi;
      dbg_id[i+ii][1] = yi;
      dbg_id[i+ii][2] = zi;
      dbg_id[i+ii][3] = ieps2;
#endif
    }
    
    //    b3_start_calc(n,0x1); // all of the pipeline FPGA start
    b3_start_calc(n,0xf); // all of the pipeline FPGA start

    for(ii=0;ii<nn;ii++){
      unsigned int sxl,sxh,syl,syh,szl,szh;
      long long int sx;
      long long int sy;
      long long int sz;
      unsigned int ipipe;
      {
	unsigned int ichip;
	ichip = ii/npipe_per_chip;
	chip_sel = 0x1<<ichip;
      }
      ipipe = ii%npipe_per_chip;  // pipe id in one chip
      //      printf("[%d %x %d]",ii+i,chip_sel,ipipe);
      //      printf("====================chip_sel 0x%x %d\n",chip_sel,ipipe);
      b3_get_fodata(devid,chip_sel,ipipe,0,&sxl);
      b3_get_fodata(devid,chip_sel,ipipe,1,&sxh);
      b3_get_fodata(devid,chip_sel,ipipe,2,&syl);
      b3_get_fodata(devid,chip_sel,ipipe,3,&syh);
      b3_get_fodata(devid,chip_sel,ipipe,4,&szl);
      b3_get_fodata(devid,chip_sel,ipipe,5,&szh);
      sx = ((long long int)sxh)<<32 | (long long int)sxl;
      sy = ((long long int)syh)<<32 | (long long int)syl;
      sz = ((long long int)szh)<<32 | (long long int)szl;
      a[i+ii][0] = ((double)(sx<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
      a[i+ii][1] = ((double)(sy<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
      a[i+ii][2] = ((double)(sz<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));

      //      fprintf(stderr,"a[0] %e\n",a[i+ii][0]); exit(0);
#ifdef DEBUG
      dbg_fo[i+ii][0] = sx;
      dbg_fo[i+ii][1] = sy;
      dbg_fo[i+ii][2] = sz;
#endif
    }
  }




#ifdef DEBUG
  b3_reset_jmem_adr();
  for(k=0;k<n;k++){
    unsigned int j0,j1,j2,j3;
    b3_get_jdata(devid,chip_sel,4*k+0,&j0);
    b3_get_jdata(devid,chip_sel,4*k+1,&j1);
    b3_get_jdata(devid,chip_sel,4*k+2,&j2);
    b3_get_jdata(devid,chip_sel,4*k+3,&j3);
    if(j0 != dbg_jd[3*k+0]){ fprintf(stderr,"err j0 != dbg_jd[3*k+0]\n"); exit(0);}
    if(j1 != dbg_jd[3*k+1]){ fprintf(stderr,"err j1 != dbg_jd[3*k+1]\n"); exit(0);}
    if(j2 != dbg_jd[3*k+2]){ fprintf(stderr,"err j2 != dbg_jd[3*k+2]\n"); exit(0);}
    printf("j[%d], 0x%08X%08X%08X\n",k,j2,j1,j0);
  }

  for(i=0;i<n;i+=npipe){
    int nn,ii;
    if((i+npipe)>n){
      nn = n - i;
    }else{
      nn = npipe;
    }
    for(ii=0;ii<nn;ii++){
      long long int fo[3];
      printf("-------(i=%d)\n",i+ii);
      for(k=0;k<4;k++) 
	printf("i[%d][%d] 0x%X\n",i+ii,k,dbg_id[i+ii][k]);
      for(k=0;k<3;k++)
	printf("f[%d][%d] 0x%llX\n",i+ii,k,dbg_fo[i+ii][k]);
    }
  }
#endif


  //  BBterm(devid);               // Terminate Biolar Board
}

