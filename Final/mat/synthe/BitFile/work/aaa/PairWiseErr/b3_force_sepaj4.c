/*
 * by Tsuyoshi Hamada 
 * thamada@riken.jp
 * Coding Start : 2004/04/14 (Wed)
 * Coding Finish: 2004/04/15 (Thu)

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

#define NPIPES_IN_A_CHIP 25
#define NCHIPS_ON_A_BOARD 4

#define NMAN 5
#define NACC 56
#define NPOS 20
#define xsize (100.0)


//#define mmin (9.765625e-04)
//#define mmin (2.44140625e-04)
//#define mmin (4.8828125e-4)
//#define mmin (1.220703125e-04)
//#define mmin (6.103515e-05)
#define mmin (3.0517578125000e-05)
//#define mmin (1.5258789062500e-05)

#define xoffset (xsize/2.0)
#define xscale (pow(2.0,(double)NPOS)/xsize)
#define mscale (pow(2.0,63.95)/mmin)
#define escale (xscale*xscale)
#define foffset (pow(2.0,19.0))
#define fscale (-xscale*xscale*foffset/mscale)


void b3_force_sepaj4(
	 double x[][3],
	 double m[],
	 double eps2,
	 double a[][3],
	 int n)
{
  static int init=0;
  int i,j,ic;
  int devid=0;
  int chip_sel;
  //  unsigned int npipe;
  unsigned int npipe_per_chip;
  unsigned int nchip;
  unsigned int nrun[4];    // jmem count for each chip

  if(init==0){
    devid=0;
    b3_init(devid);       // Open Biolar Board
    init=1;
  }

  npipe_per_chip = NPIPES_IN_A_CHIP;
  nchip = NCHIPS_ON_A_BOARD;
  //  npipe = nchip*npipe_per_chip;

  if(nchip != 4){fprintf(stderr,"not support nchip != 4 "); exit(0);}


  {
    unsigned int mod;
    mod = n%nchip;
    if(mod==0){ nrun[0]=nrun[1]=nrun[2]=nrun[3]=(int)(n/4);}
    else if(mod==1){ nrun[1]=nrun[2]=nrun[3]=(int)(n/4); nrun[0]=nrun[1]+1;}
    else if(mod==2){ nrun[2]=nrun[3]=(int)(n/4); nrun[0]=nrun[1]=nrun[2]+1;}
    else{ nrun[3]=(int)(n/4); nrun[0]=nrun[1]=nrun[2]=nrun[3]+1;}
  }
  
  // jpw_we
  b3_reset_jmem_adr();
  j=0;
  for(ic=0;ic<nchip;ic++){
    int jj;
    for(jj=0;jj<nrun[ic];jj++){
      unsigned int xj,yj,zj,mj;
      unsigned int jdata[4];
      unsigned int nword;
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
      jdata[0] = 0x0;
      jdata[1] = 0x0;
      jdata[0] = ((0xfffff & xj)<<0)  | ((0xfff   & yj)<<20);   // lower part of jdata
      jdata[1] = ((0xff    & (yj>>12)) | ((0xfffff & zj)<<8) | (0xf&mj)<<28);  // higer part of jdata
      jdata[2] = 0x7ff&(mj>>4);
      jdata[3] = 0x0;
      nword = 4;
      b3_set_jdata_n_chip(devid,ic,nword,jdata);
      //      printf("%d 0x%08X %08X %08X\n",j,jdata[2],jdata[1],jdata[0]);
      j++;
    }
  }

  for(i=0;i<n;i+=npipe_per_chip){
    int nn,ii;
    if((i+npipe_per_chip)>n){
      nn = n - i;
    }else{
      nn = npipe_per_chip;
    }
    // ipw_we (0) , ii: i-th pipeline in a chip
    for(ii=0;ii<nn;ii++){
      unsigned int xi,yi,zi,ieps2;
      // --- chip select ---
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
      for(ic=0;ic<nchip;ic++){
	chip_sel = 0xF&(0x1<<ic);
	b3_set_idata(devid,chip_sel,ii,0,xi);
	b3_set_idata(devid,chip_sel,ii,1,yi);
	b3_set_idata(devid,chip_sel,ii,2,zi);
	b3_set_idata(devid,chip_sel,ii,3,ieps2);
      }
    }

    b3_start_calc_sepa4jM(nrun); // all of the pipeline FPGA start

    for(ii=0;ii<nn;ii++){
      unsigned int sxl,sxh,syl,syh,szl,szh;
      long long int sx;
      long long int sy;
      long long int sz;

      for(ic=0;ic<nchip;ic++){
	sx=0;
	sy=0;
	sz=0;
      }

      for(ic=0;ic<nchip;ic++){
	chip_sel = 0xf&(0x1<<ic);
	b3_get_fodata(devid,chip_sel,ii,0,&sxl);
	b3_get_fodata(devid,chip_sel,ii,1,&sxh);
	b3_get_fodata(devid,chip_sel,ii,2,&syl);
	b3_get_fodata(devid,chip_sel,ii,3,&syh);
	b3_get_fodata(devid,chip_sel,ii,4,&szl);
	b3_get_fodata(devid,chip_sel,ii,5,&szh);
	sx += (((long long int)sxh)<<32 | (long long int)sxl);
	sy += (((long long int)syh)<<32 | (long long int)syl);
	sz += (((long long int)szh)<<32 | (long long int)szl);
	//	fprintf(stderr,"sx %016llx\n",sy<<(64-NACC));
	//	fprintf(stderr,"%d %016llx\n",i+ii,sx);
      }
      //      exit(0);
      sx &= (long long int)((0x1ULL<<NACC)-0x1ULL);
      sy &= (long long int)((0x1ULL<<NACC)-0x1ULL);
      sz &= (long long int)((0x1ULL<<NACC)-0x1ULL);
      a[i+ii][0] = ((double)(sx<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
      a[i+ii][1] = ((double)(sy<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
      a[i+ii][2] = ((double)(sz<<(64-NACC)))*fscale/pow(2.0,(double)(64-NACC));
      //      fprintf(stderr,"%d %016llx\t",i+ii,sx<<(64-NACC));
      //      fprintf(stderr,"%d %e\n",i+ii,a[i+ii][0]);

    }
  }
}

