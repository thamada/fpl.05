// This file includes some parameters which are dependent on a VHDL design.

// depend on NBIT_L_UADR (@ ifpga.vhd)
#define FDIM 8
//#define FDIM 4 // mada dame desu. jitsuha 66MHz de mawarimasen desita... to ho ho....
#define NCHIP 4

// depend on dpram adr width (@ pgpg_mem.vhd)
//#define JDIM 4  // mada desu.
#define JDIM 16

// depend on l_adri width   (@ pgpg_mem.vhd)
#define XI_AWIDTH 4


