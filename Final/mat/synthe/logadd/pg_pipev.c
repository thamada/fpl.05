#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "pg_util.h"

#include "pgrapi.h"

#define DEBUG

#define   MAX(x,y)     (((x) > (y)) ?  (x) : (y))
#define   MIN(x,y)     (((x) < (y)) ?  (x) : (y))

#define NJMAX 8192

#define NPIPE_PER_CHIP  1
#define NCHIP_PER_BOARD 4

#define NFLO 26
#define NMAN 16
#define RMODE 6

static int      devid = 0;
static int      __first = 0;

static unsigned int idata[NJMAX];
static unsigned long long int fdata[NJMAX][FDIM];

void
force(int ni, int nj)
{
    int             i, j;
    unsigned int    npipe, npipe_per_chip;
    unsigned int    nchip;
    unsigned int    jdata[JDIM];
#ifdef DEBUG
    double          _t[10], dum;
#endif

    if (__first == 0) {
	b3open(devid);
	pgr_reset(devid);
	pgr_set_npipe_per_chip(devid, NPIPE_PER_CHIP);
	__first = 1;
    }

    npipe_per_chip = NPIPE_PER_CHIP;
    nchip = NCHIP_PER_BOARD;
    npipe = nchip * npipe_per_chip;

#ifdef DEBUG
    _t[0] = e_time();
    _t[1] = _t[2] = _t[3] = _t[4] = 0.0;
    dum = e_time();
#endif
    for (j = 0; j < n; j++) {
	unsigned int    xj[0];

	for (i = 0; i < JDIM; i++)
	    jdata[i] = 0x0;

	// setup jdata


	pgr_setjpset_one(devid, j, jdata);
    }
    // pgr_setjpset(devid, jdata, n);
#ifdef DEBUG
    _t[1] = e_time() - dum;
#endif

    for (i = 0; i < n; i += npipe) {
	int             nn, ii, ichip;
	nn = MIN(npipe, n - i);

#ifdef DEBUG
	dum = e_time();
#endif

	for (ii = 0; ii < nn; ii += npipe_per_chip) {
	    int             nnn, iii;
	    unsigned int    mask;
	    ichip = ii / npipe_per_chip;

	    nnn = MIN(npipe_per_chip, nn - ii);
	    for (iii = 0; iii < nnn; iii++) {
		mask = (iii << XI_AWIDTH);
	    }
	    pgr_setipset_ichip(devid, ichip, idata, nnn);
	}
#ifdef DEBUG
	_t[2] += e_time() - dum;
	dum = e_time();
#endif

	pgr_start_calc(devid, n);
#ifdef DEBUG
	_t[3] += e_time() - dum;
	dum = e_time();
#endif

	pgr_getfoset(devid, fdata);
	for (ii = 0; ii < nn; ii++) {
	}
#ifdef DEBUG
	_t[4] += e_time() - dum;
#endif

    }
#ifdef DEBUG
    _t[0] = e_time() - _t[0];
    fprintf(stderr, "total %g sec (jp %g, ip %g, c %g, fo %g %%)\n", _t[0],
	    100.0 * _t[1] / _t[0], 100.0 * _t[2] / _t[0],
	    100.0 * _t[3] / _t[0], 100.0 * _t[4] / _t[0]);
#endif
}
