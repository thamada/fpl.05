// ---------------------------------------------------------------------- unsupport
//void b3setnj(int n, int width);
//void b3setipset(int devid, int chipsel, unsigned int *idata, int num);
//void b3getfoset(int devid, int chipsel, unsigned int *fodata, int num);
// ---------------------------------------------------------------------- unsupport.

#include "b3vhdl.h"

int b3open(int id);
void b3close(int devid);
void b3reset(int devid);

void pgr_setipset(int devid, unsigned int *idata, int num);
void pgr_setipset_ichip(int devid, unsigned int ichip, unsigned int *idata, int num);
void pgr_setjpset(int devid, unsigned int jdata[][JDIM], int nj);
int  pgr_get_writecomb_err(int devid);

void pgr_start_calc(int devid, unsigned int n);              // 2005/01/05
void pgr_set_npipe_per_chip(int devid, int n);               // 2005/01/05
void pgr_getfoset(int devid, unsigned long long int fodata[][FDIM]);  // 2005/01/05
