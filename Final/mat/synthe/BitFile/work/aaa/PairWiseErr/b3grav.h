#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void b3_init(int devid);
void b3_init_config(int devid, char* fpga_conf_file);



void b3_set_idata(unsigned int devid,      // device id
		  unsigned int chip_sel,   // chip select
                  unsigned int npipe,      // pipeline number
                  unsigned int ireg_index, // iregister index
                  unsigned int data);      // data

void b3_reset_jmem_adr();
void b3_reset_jmem_adr_n(int nchip);

void b3_set_jdata(unsigned int devid,      // device id
                  unsigned int nword,      // number of jdata
                  unsigned int jdata[] );  // 

void b3_set_jdata_n_chip(unsigned int devid,    // device id
			 unsigned int nchip,    // 0, 1, 2, 3
			 unsigned int nword,    // number of jdata
			 unsigned int jdata[]);


void b3_get_jdata(unsigned int devid,      // device id
                  unsigned int chip_sel,   // chip_sel
		  unsigned int jmem_adr,   // mem adr
                  unsigned int* data );    // data 

void b3_start_calc(unsigned int n,
		   unsigned int chip_sel);

void b3_start_calc_sepa4jM(unsigned int nrun[]);

unsigned int b3_get_calcsts(unsigned int chip_sel);


void b3_get_fodata(unsigned int devid,     // device id
		  unsigned int chip_sel,   // chip select
                  unsigned int npipe,      // pipeline number
                  unsigned int fo_index,   // iregister index
                  unsigned int* data);     // data
