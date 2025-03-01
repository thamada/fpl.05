// Copyright(c) 2004- by PGPG
// The original source : contrib/src_h/vi/pg_util.h
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#ifndef LONG
#define LONG unsigned long long int
#endif
LONG  double2pgpglog(double x, int nbit_log, int nbit_man);
double pgpglog2double(LONG x,  int nbit_log, int nbit_man);
LONG  double2pgpgfloat(double a, int nbit_float, int nbit_man);
LONG  double2pgpgfloat_r(double a, int nbit_float, int nbit_man, int rmode);
double pgpgfloat2double(LONG x, int nbit_float, int nbit_man);
LONG extractbit_long(LONG in, int hi, int lo);
void l2bit(LONG a);
void putbits(LONG a);
void putbits32(LONG a);
void putbitsn(LONG a,int n);
double gen_rand_abs(void);
double gen_rand(void);
double gen_rand_tamanizero(void);


#include <sys/time.h>
#include <sys/resource.h>
double e_time(void);
