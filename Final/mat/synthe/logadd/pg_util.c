// Copyright(c) 2004- by PGPG
// The original source : contrib/src_h/vi/pg_util.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#ifndef LONG
#define LONG unsigned long long int
#endif

LONG double2pgpglog(double x, int nbit_log, int nbit_man)
{
  LONG z;
  if (x == 0.0){
    z = 0;
  }else if(x>0.0){
    double zz = pow(2.0,(double)nbit_man) * log(x)/log(2.0);
    z = ((int)zz);
    z &= (0x1ULL<<(nbit_log-2))-1;
    z |= 0x1ULL<<(nbit_log-2);
  }else{
    double zz = pow(2.0,(double)nbit_man) * log(-x)/log(2.0);
    z = ((int)zz);
    z &= (0x1ULL<<(nbit_log-2))-1;
    z |= 0x3ULL<<(nbit_log-2);
  }
  return z;
}

double pgpglog2double(LONG x, int nbit_log, int nbit_man)
{
  double z;
  LONG sign,nonz,logval;
  sign = 0x1ULL & (x>>(nbit_log-1));
  nonz = 0x1ULL & (x>>(nbit_log-2));
  logval  = ((0x1ULL<<(nbit_log-2))-1) & x;
  z = pow(2.0,((double)logval)/pow(2.0,(double)(nbit_man)));
  if(nonz == 0) z = 0.0;
  if(sign == 1) z *= -1.0;
  return z;
}

LONG double2pgpgfloat(double a, int nbit_float, int nbit_man)
{
  LONG hi;
  int nbit_exp;
  nbit_exp = nbit_float - nbit_man - 2;
  if (a == 0.0)
    hi = 0;
  else {
    LONG _i_ = *((LONG *) (&a));
    LONG h_exp, h_man, h_sign, h_nonz;
    h_sign = (_i_ >> 63) & (0x1LL);
    h_nonz = 0x1LL;
    h_exp =  (_i_ >> 52) & ((0x1LL<<11)-1);
    h_exp -= 1023LL; // subtract bias 
    h_exp = h_exp & ((0x1LL<<nbit_exp)-1);
    h_man = (_i_&((0x1LL<<52)-1));
    h_man = h_man>>(52-nbit_man);
    hi = (h_sign << (nbit_float-1)) | (h_nonz << (nbit_float-2)) | (h_exp << nbit_man) | h_man;
  }
  return hi;
}

/* --- ROUNDING VERSION --- */
LONG double2pgpgfloat_r(double a, int nbit_float, int nbit_man, int rmode)
{
  LONG hi;
  int nbit_exp;
  nbit_exp = nbit_float - nbit_man - 2;
  if (a == 0.0)
    hi = 0;
  else {
    LONG _i_ = *((LONG *) (&a));
    LONG h_exp, h_man;
    LONG signz,nonzz;
    LONG expz,manz;
    LONG Guard,Sbit,Gbit,Ulp;

    signz = (_i_ >> 63) & (0x1LL);
    nonzz = 0x1LL;

    h_exp =  (_i_ >> 52) & ((0x1LL<<11)-1);
    h_exp -= 1023LL; // subtract bias 
    expz  = h_exp & ((0x1LL<<nbit_exp)-1);

    h_man = (_i_&((0x1LL<<52)-1));
    Guard = ((0x1ULL<<(52-nbit_man))-1)&h_man;
    Sbit  = 0x1ULL&(Guard>>(51-nbit_man));
    Gbit  = (((0x1ULL<<(51-nbit_man))-1)&Guard) == 0x0ULL ? 0 : 1;
    manz  = h_man>>(52-nbit_man);

    Ulp = 0x1ULL & manz;
    {
      LONG man_inc;
      if(rmode == 0)      man_inc = 0; /* Truncation */
      else if(rmode == 1) man_inc = signz*(1-(1-Sbit)*(1-Gbit)); /* Truncation to Zero */
      else if(rmode == 2) man_inc = Sbit; /* Rounding to Plus Infinity */
      else if(rmode == 3) man_inc = Sbit*Gbit; /* Rounding to Minus Infinity */
      else if(rmode == 4) man_inc = Sbit*(1-signz*(1-Gbit)); /* Rounding to Infinity */
      else if(rmode == 5) man_inc = Sbit*(1-(1-signz)*(1-Gbit)); /* Rounding to Zero */
      else if(rmode == 6) man_inc = Sbit*(1-(1-Ulp)*(1-Gbit)); /* Rounding to Even */
      else if(rmode == 7) man_inc = Sbit*(1-Ulp*(1-Gbit)); /* Rounding to Odd */
      else if(rmode == 8) man_inc = Sbit+Gbit; /* Force one */
      else                man_inc = Sbit*(1-(1-Ulp)*(1-Gbit)); /* Rounding to Even */
      // adder with overflow-flag
      manz = manz+man_inc;
      if ((manz>>(nbit_man)) == 1ULL) {
	manz = 0x0ULL;
	expz++;
      }
    }
    hi = (signz << (nbit_float-1)) | (nonzz << (nbit_float-2)) | (expz << nbit_man) | manz;
  }
  return hi;
}

double pgpgfloat2double(LONG x, int nbit_float, int nbit_man)
{
  LONG hi;
  double *xx;
  LONG h_exp, h_man, h_sign, h_nonz;
  int nbit_exp;
  nbit_exp = nbit_float - nbit_man - 2;
  h_sign = 0x1LL&(x>>(nbit_float-1));
  h_nonz = 0x1LL&(x>>(nbit_float-2));
  h_exp  = ((0x1LL<<nbit_exp)-1)&(x>>nbit_man);
  h_man  = ((0x1LL<<nbit_man)-1)&x;
  if((0x1LL&(h_exp>>(nbit_exp-1)))==0x1LL){
    h_exp |= ((0x1LL<<(11-nbit_exp))-1)<<(nbit_exp);  
  }
  h_exp += 1023LL; // add bias (IEEE double)
  h_exp &= (0x1LL<<11)-1;
  if (h_nonz == 0) return 0.0;
  hi = (h_sign << 63) | (h_exp << 52) | h_man << (52-nbit_man);
  xx = (double *)&hi;
  return *xx;
}

void l2bit(idata,sdata,nbit)
LONG idata;
char sdata[];
int nbit;
{
  int i;
  LONG itmp;
  strcpy(sdata,"");
  for(i=0;i<nbit;i++){
    itmp =0x1ULL&(idata>>(nbit-1-i));
    if(itmp == 0x1ULL) strcat(sdata,"1");
    if(itmp == 0x0ULL) strcat(sdata,"0");
  }
}

LONG extractbit_long(LONG in, int hi, int lo)
{
  int size;
  LONG mask, res;
  size = hi - lo + 1;
  mask = (0x1ULL<<size) - 1;
  res = (in>>lo) & mask;
  return res;
}
void putbits(LONG a)
{
    int i;
    for(i = 0; i < 64; i++) {
	if (extractbit_long(a, 63-i, 63-i) == 1ULL) {
	    printf("1");
	} else {
	    printf("0");
	}
    }
    puts("");
}

void putbits32(LONG a)
{
    int i;
    for(i = 0; i < 32; i++) {
	if (extractbit_long(a, 31-i, 31-i) == 1ULL) {
	    printf("1");
	} else {
	    printf("0");
	}
    }
    puts("");
}

void putbitsn(LONG a, int n)
{
    int i;
    for(i = 0; i < n; i++) {
	if (extractbit_long(a, n-i, n-i) == 1ULL) {
	    printf("1");
	} else {
	    printf("0");
	}
    }
    puts("");
}

double gen_rand(void)
{
  double x;
  double man,exp,sign,es;
  if((rand()/(RAND_MAX+1.0))<0.5) sign = 1.0; else sign = -1.0;
  if((rand()/(RAND_MAX+1.0))<0.5) es   = 1.0; else es   = -1.0;
  man = rand()/(RAND_MAX+1.0);
  exp = rand()/(RAND_MAX+1.0);
//  x = sign*(2.0*man) * pow(2.0,38.0*es*exp);
  x = sign*(2.0*man) * pow(2.0,20.0*es*exp);
  return (x);

}
double gen_rand_abs(void)
{
  double x;
  double man,exp,es;
  if((rand()/(RAND_MAX+1.0))<0.5) es   = 1.0; else es   = -1.0;
  man = rand()/(RAND_MAX+1.0);
  exp = rand()/(RAND_MAX+1.0);
  //  x = (2.0*man) * pow(2.0,1024.0*es*exp);
  //  x = 2.0 - man*0.0001;
  //  x = (2.0*man) * pow(2.0,39.0*es*exp);
  //  x = (1.0+man) * pow(10.0,38.0*es);      // boundary-test
  x = (1.0+man) * pow(10.0,38.0*es*exp);
  return (x);
}

double gen_rand_tamanizero(void)
{
  // 100 mankai ni 1 do zero
  if((rand()/(RAND_MAX+1.0))<1.0e-7) return 0.0; else return 1.0;
}

#include <sys/time.h>
#include <sys/resource.h>
double e_time(void)
{
  static struct timeval now;
  static struct timezone tz;
  gettimeofday(&now, &tz);
  return (double)(now.tv_sec + now.tv_usec/1000000.0);
}

