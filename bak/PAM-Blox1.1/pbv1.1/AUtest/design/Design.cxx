/*----------------------------*/ 
/* Arithmetic Unit Test Bench */ 
/*----------------------------***************************/ 
/*                                                      */
/* This design can be used to test arithmetic units     */ 
/* last mod 4/10/1998 by mencer                         */ 
/********************************************************/
#include "../../inc/GNUlicense.h"

// import PaModules
#include "../../inc/kcm16.h" 
 
#define SERMULT 
#undef NIBBLEMULT 
#undef PARMULT 
#undef TP16P1MULT  
 
#define DATA_WIDTH 16 
#define ADDRESS_WIDTH 15 
 
class Lca0 : public usrlca0 {
 public:
  Bool clkUsr;
  WireVector<Bool, 16> addr;
  WireVector<Bool, 16> data;
  Bool one,zero,RamWrite;

  Lca0(char* name)
    : usrlca0(name, 30, chipnames[chiptype], chippackages[chiptype]) {

    internal(clkUsr); internal(addr); internal(zero); internal(one);
    internal(data); internal(RamWrite);

    int i;

    default_clock(clkUsr);   		// set default clock
    clkUsr = Cntlr_l.Clkusr;
    clkUsr <<= GLOBAL_BUF(BUFG);
    one=~reg(ZERO);
    zero=~reg(ONE);

    // SRAM address counter
    Counter<16> *CR;
    CR=new Counter<16>(&clkUsr,"addr_count");
    CR->out(addr);
    CR->place();

    // Beware, SRAM is asynchronus.  We must generate a write pulse
    RamWrite = reg(~RamWrite,~clkUsr); 

    SRam._Write[0] = slow(one);
    SRam._Write[1] = slow(one);

    for (i = 0; i < 15; i++)
      SRam.Addr[i] = reg(addr[i]);
    
    SRam._Bank[0] = ~reg(~addr[15]);
    SRam._Bank[1] = ~reg(addr[15]);

    // SRAM -> SBus
    for (i=0; i<16; i++){
      data[i]=reg(SRam.Data[i]);
      SBus.D[i]=reg(data[i]);
    }

    SRam._Oe = zero; 
}
}; /* end LCA0 */


class Lca1 : public usrlca1 { 
 public: 
  Bool clkUsr; 
  int lcanum; 
  Bool zero,one; 
  WireVector<Bool, 16> addr;		// SRam Address Register 
  WireVector<Bool, 16> data_in;		// Input Register 
  WireVector<Bool, 32> pmultOut;			 
 
  WireVector<Bool, 4> MultIn;	 
  WireVector<Bool, 16> msb; 
  WireVector<Bool, 4> MultOut,NMultOut,A,B; 
  WireVector<Bool, 4> dataOut;	 
  WireVector<Bool, 4> constant;	 
  Bool start,modStart; 
  Bool dummy; 
  Bool smultOut; 
  Bool cout; 
 
// create pointers to PaModules here in order to make internal symbols 
// readable from simulation 
  Mod2P16P1 *MOD; 
  ParKCM16 *PMULT; 
  SerKCM16 *SMULT; 
  NibbleKCM16 *NMULT; 
 
Lca1(char* name) 
    : usrlca1(name, 30, chipnames[chiptype], chippackages[chiptype]) { 
 
    internal(clkUsr); internal(zero); internal(one); 
    internal(addr); internal(data_in); internal(modStart); 
    internal(MultOut); internal(MultIn); internal(dummy); 
    internal(dataOut); internal(constant); internal(smultOut); 
    internal(pmultOut); internal(cout); internal(A); internal(B); 
    internal(msb); internal(NMultOut); internal(start); 
 
// addr counter 
 
    Counter<16> *CR; 
    CR=new Counter<16>(&clkUsr,"addr_count"); 
    CR->out(addr); 
    CR->place(Rect(8,18,1,8)); 
 
// KCMs 
 
#ifdef SERMULT 
    SMULT=new SerKCM16(MultIn[0],addr[4],(int)11,&clkUsr,"smult"); 
    SMULT->out(smultOut); 
    SMULT->place(10,15); 
#endif 
 
#ifdef NIBBLEMULT 
    NMULT=new NibbleKCM16(MultIn,start,(int)11,&clkUsr,"nmult"); 
    NMULT->out(NMultOut,&msb); 
    NMULT->place(10,15); 
#endif 
 
#ifdef PARMULT 
    PMULT=new ParKCM16(data_in,(int)0xabc,&clkUsr,"pmult"); 
    PMULT->out(pmultOut); 
    PMULT->place(10,19); 
#endif 
 
modStart=reg(reg(start)); 
 
#ifdef TP16P1MULT  
    MOD=new Mod2P16P1(NMultOut,msb,modStart,&clkUsr,"mod"); 
    MOD->out(MultOut); 
//    MOD->place(10,15); 
#else 
for(int i=0;i<NMultOut.get_n_elts();i++) 
   alias(NMultOut[i],MultOut[i]); 
#endif 
 
   default_clock(clkUsr);   		// set default clock 
   clkUsr = Cntlr_l.Clkusr; 
   clkUsr <<= GLOBAL_BUF(BUFG); 
 
   start= reg(addr[2]^reg(addr[2])); 
 
   zero=reg(~ONE); 
   one=reg(~ZERO); 
 
   for (i=0; i<DATA_WIDTH; i++){ 
#ifdef NIBBLEMULT 
       if (i<4){ 
	   A[i]=MultIn[i]; 
	   if(i%2) 
	     B[i]=zero; 
	   else 
	     B[i]=one; 
	   SRam.Data[i]=reg(MultOut[i]); 
	   MultIn[i]=reg(data_in[i]); 
	 }else if (i>12){ 
	   SRam.Data[i]=reg(data_in[i-12]); 
	 }else{ 
	   SRam.Data[i]=zero; 
         } 
#endif 
#ifdef SERMULT 
	if (i==0) SRam.Data[i]=reg(smultOut); 
	else SRam.Data[i]=zero; 
#endif 
#ifdef PARMULT 
	SRam.Data[i]=reg(pmultOut[i]); 
#endif 
 
    } 
 
    // connect address to SRAM address pins and bank select 
    for (i = 0; i < ADDRESS_WIDTH; i++){ 
      SRam.Addr[i] = reg(addr[i]); 
    } 
 
    SRam._Bank[0] = ~reg(~addr[15]); 
    SRam._Bank[1] = ~reg(addr[15]); 
 
    // SBus input path 
    for (i=0; i<data_in.get_n_elts(); i++) 
    { 
      // data in from SBus 
      data_in[i] = reg(SBus.D[i]); 
      data_in[i] <<= SBus.D[i]; // placement 
    } 
    SRam._Oe = one;  
 
    // Beware, SRAM is asynchronus.  We must generate a write pulse 
 
    SRam._Write[0] = slow(~clkUsr); 
    SRam._Write[1] = slow(~clkUsr); 
 

}
};  // end userlca1 

class LcaEmpty : public usrlca0 { 
public: 
  LcaEmpty(char* name) 
    : usrlca0(name, 0, chipnames[chiptype], chippackages[chiptype]) { 
  } 
  void logic() { 
  } 
}; 
 
//////////////////////////// 
// Generate the design 
//////////////////////////// 
 
Design* GetUserDesign() { 
  Design *design = new Design(mkname("autest", chipnames[chiptype]+4)); 
  int seqn = 0; 
 
  design->register_chip((ChipName) seqn++, new Lca0(mkname("lca0-", chipnames[chiptype]+4))); 
  design->register_chip((ChipName) seqn++, new Lca1(mkname("lca1-", chipnames[chiptype]+4))); 
  design->register_chip((ChipName) seqn++, new LcaEmpty(mkname("lcaem", chipnames[chiptype]+4))); 
   
  return design; 
} 
 
 
main(int argc, char **argv) { 
 
  if ((argc == 1) || (argv[1][0] != 's')) { 
    //////////////////// 
    // generate design 
    //////////////////// 
     chiptype = XC4010E; 
     { 
        Design* design = GetUserDesign(); 
        design->write(); 
     } 
     chiptype = XC4020E; 
     { 
        Design* design = GetUserDesign(); 
        design->write(); 
     } 
     return 0; 
 
  } else { 
    //////////////////// 
    // simulate design 
    //////////////////// 
#define SIM_CYCLES 40 
 
    int i, j, dat; 
    int clkusr; 
    int in_sim[16]; 
    FILE *dfile; 
    char line[10]; 
 
    Lca1* lca1 = new Lca1("lca1"); 
 
    // bind inputs for simulation 
 
    lca1->Cntlr_l.Clkusr.bind_input(clkusr); 
    for (i = 0; i < 16; i++) { 
      lca1->SBus.D[i].bind_input(in_sim[i]); 
    } 
 
    // create and initialize simulation 
    lca1->logic(); 
    lca1->simul_setup(); 
    lca1->reset(); 
    clkusr = 0; 
 
    // open data file 
    dfile=fopen("dat","r"); 
     
    printf("SIMULATION start\n\n"); 
 
#ifdef PARMULT 
    printf(" Bit-Parallel Constant (K=0xabc) Coefficient Multiplier\n"); 
    printf(" Latency = 5 clock cycles\n\n"); 
#endif 
#ifdef NIBBLEMULT 
#ifndef TP16P1MULT 
    printf(" Nibble-Parallel Constant (K=0xb) Coefficient Multiplier\n"); 
    printf(" Latency = X clock cycles\n\n"); 
#endif 
#endif 
#ifdef SERMULT 
    printf(" Bit-Serial Constant (K=0xb) Coefficient Multiplier\n"); 
    printf(" Latency = 16 clock cycles\n\n"); 
#endif 
#ifdef TP16P1MULT 
    printf(" Nibble-Serial Constant (K=0xb) Coefficient Multiplier MOD 2^16+1\n"); 
    printf(" Latency = X+Y clock cycles\n\n"); 
#endif 
 
    printf(" cyc |  input  | result | start |  lsb   |   msb    |   diff   | sign  | diff4 | PSum\n"); 
    printf("======================================================================\n");	 
    // simulate 
    for (i = 0; i < SIM_CYCLES; i++) { 
      // set inputs 
      fgets(line,10,dfile); 
      dat=atoi(line); 
      for (j=0;j<16;j++) 
 	in_sim[j]=(dat >> j) & 1; 
 
      // compute logic and step the clock 
      lca1->compute_outputs(); 
      lca1->tick(); 
      // display signal values 
 
      printf("  %02d | %08x| %08x | %d | %08x | %08x | %08x | %1d | %08x | %08x\n", 
	    i, 
	    intval(lca1->SBus.D, 1,1), 
	    intval(lca1->SRam.Data, 1,1), 
	    lca1->start.get_value(), 
	    intval(lca1->NMultOut,1,1), 
	    intval(lca1->msb,1,1), 
	    intval(lca1->MOD->diff,1,1), 
	    lca1->MOD->sign.get_value(), 
	    intval(lca1->MOD->diff4,1,1), 
	    intval(lca1->NMULT->PSum,1,1));  

	}
 
    fclose(dfile); 
    printf("\nSIMULATION end.\n\n"); 
  } 
 
return 0; 
 
} 




