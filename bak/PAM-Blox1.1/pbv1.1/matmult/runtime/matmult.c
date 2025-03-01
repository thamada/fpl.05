/* Copyright 1996-1997 Digital Equipment Corporation.           */
/* Distributed only by permission.                              */
/*
 * last mod 6/6/98 by mencer
 */
/*
 * matmult test
 */

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>

#include <PamRT.h>
#include <PamFriend.h>

// how many times to repeat the test
#define LOOP 10

// range for CCT is 8.334 ns (120MHz) - 2782.6 ns (359.4 kHz)
#define CCT 1000

static void Usage(const char *progname)
{
    fprintf(stderr, "Usage: %s [ -dev device ] [-loop]\n", progname);
    exit(1);
}

static void
SetLinkMode (Pam pam, int mode) {
  PAMREGS(pam)->decode = mode;	/* High address care / mode register */
  PamFlush();
}

static int oe;

extern struct PamBitstream matmult;

main(int argc, char **argv)
{
    Pam pam;
    int i,j=0;
    volatile int *userarea;
    char *device = NULL;
    int loop = LOOP;
    double realClock;
    unsigned int read;

    while (argc >= 2 && argv[1][0] == '-') {
	if (strcmp(argv[1], "-dev") == 0 && argc >= 3) {
	    device = argv[2];
	    argc -= 2; argv += 2;
	}
	else if (strcmp(argv[1], "-loop") == 0) {
	    loop = 1;
	    argc -= 1; argv += 1;
	}

    }

    pam = PamOpen(device, PamNoWait);
    
    PamDownloadBitstream(pam, &matmult, CCT);
    sleep(1);
    PamClockOn(pam,0);
    sleep(1);
    printf("MATMULT done!\n");
    PamClose(pam);
    return 0;
}
