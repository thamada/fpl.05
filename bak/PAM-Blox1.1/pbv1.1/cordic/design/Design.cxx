/*----------------------------*/ 
/*    CORDIC Test Bench       */ 
/*----------------------------****************/ 
/*                                           */
/* This design can be used to test CORDICs   */ 
/* last mod 4/10/1998 by mencer              */ 
/*********************************************/
#include "../../inc/GNUlicense.h"

// import PaModules
#include "../../inc/cordic.h"

#define DEBUG printf
#define DATA_WIDTH 8

#define ADDRESS_WIDTH 15
#define STAGES 8

class Lca1 : public usrlca1 {
 public:
  Bool clkUsr;
  int lcanum;

  Bool zero,one,start;
  WireVector<Bool, 16> addr;			// SRam Address Register
  WireVector<Bool, (3*DATA_WIDTH)> data_in;	// Input Register

  WireVector<Bool, DATA_WIDTH>  XOut,YOut, XIn,YIn,PhiIn;     

  PPcordic<DATA_WIDTH, STAGES> *PP;
  
  Lca1(char* name)
    : usrlca1(name, 30, chipnames[chiptype], chippackages[chiptype]) {

    internal(clkUsr); internal(zero); internal(one);
    internal(addr); internal(data_in); internal(XOut); internal(YOut);
    internal(XIn);    internal(YIn);    internal(PhiIn); internal(start);
    int i,j;

// addr counter

    Counter<16> *CR;
    CR=new Counter<16>(&clkUsr,"addr_count");
    CR->out(addr);
    CR->place(Rect(2,18,1,8));

    for(i=0;i<DATA_WIDTH;i++){
      XIn[i]=data_in[i];
      YIn[i]=data_in[i+DATA_WIDTH];
      PhiIn[i]=data_in[i+2*DATA_WIDTH];
    }

    PP=new PPcordic<DATA_WIDTH, STAGES>(XIn, YIn, PhiIn ,&clkUsr,"ppcordic");
    PP->out(XOut,YOut);
    PP->place(8,15);

    default_clock(clkUsr);   		// set default clock
    clkUsr <<= GLOBAL_BUF(BUFG);
    clkUsr = Cntlr_l.Clkusr;

    zero=reg(~ONE);
    one=reg(~ZERO);

    for (i=0; i<(2*DATA_WIDTH); i++){

	if (i<DATA_WIDTH)
	  SRam.Data[i]=reg(XOut[i]);
	else
	  SRam.Data[i]=reg(YOut[i-DATA_WIDTH]);

	SRam.Data[i]+=PULLDOWN;
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

class Lca0 : public usrlca0 {
 public:
  Bool clkUsr;
  WireVector<Bool, 16> addr;
  WireVector<Bool, 16> data;
  WireVector<Bool, 16> carry;
  Bool one,zero,RamWrite;

  Lca0(char* name)
    : usrlca0(name, 30, chipnames[chiptype], chippackages[chiptype]) {
    internal(clkUsr);
    internal(addr);    internal(carry);    internal(zero);
    internal(one);    internal(data);      internal(RamWrite);
  }

  void logic(){
    int i;
    default_clock(clkUsr);   		// set default clock
    clkUsr = Cntlr_l.Clkusr;
    clkUsr <<= GLOBAL_BUF(BUFG);
    one=~reg(ZERO);
    zero=~reg(ONE);

    // SRAM address counter
    carry[0] = one;
    for (i=0; i<addr.get_n_elts(); i++) {
      addr[i] = reg(addr[i] ^ carry[i]);
      if (i < addr.get_n_elts()-1)
	carry[i+1] = carry[i] & addr[i];
    }
    // Beware, SRAM is asynchronus.  We must generate a write pulse
    RamWrite = reg(~RamWrite,~clkUsr); 

    SRam._Write[0] = slow(one);
    SRam._Write[1] = slow(one);

    for (i = 0; i < 15; i++)
      SRam.Addr[i] = reg(addr[i]);
    
    SRam._Bank[0] = ~reg(~addr[15]);
    SRam._Bank[1] = ~reg(addr[15]);


    // SRAM -> SBus
    for (i=0; i<16; i++)
    {
      data[i]=reg(SRam.Data[i]);
      data[i]<<=SRam.Data[i]; 
      SBus.D[i]=reg(data[i]);
    }

    SRam._Oe = zero; 

  }// end logic

  void placement(){
  int i;

    for (i=0; i<addr.get_n_elts(); i++) {
		addr[i] <<= LOC(10, 17-i/2);
		carry[i] <<= addr[i] + OFFSET(0, (i&1)^1);
		 if (i%2)
			carry[i] <<= CLB_OUTPUT(COUT0);
		 else
			carry[i] <<= CLB_OUTPUT(COUT);
    }
  } // end placement
 

}; /* end LCA0 */


// standard empty LCA
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
  Design *design = new Design(mkname("cordic", chipnames[chiptype]+4)); 
  int seqn = 0; 
  design->register_chip((ChipName) seqn++, new Lca0(mkname("lca0-", chipnames[chiptype]+4))); 
  design->register_chip((ChipName) seqn++, new Lca1(mkname("lca1-", chipnames[chiptype]+4))); 
  design->register_chip((ChipName) seqn++, new LcaEmpty(mkname("lcaem", chipnames[chiptype]+4))); 
  design->register_chip((ChipName) seqn++, new LcaEmpty(mkname("lcaem", chipnames[chiptype]+4))); 

  return design; 
} 

int intSign(double x){
  
  if (x>=0) return 1;
  else return -1;
}

double doubleSign(double x){
 
  if (x>=0.0) return (double)1.0;
  else return (double)-1.0;
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
#define SIM_CYCLES 15

    int i, j, datx, daty, datz;
    int clkusr;
    int in_sim[32];
    char line[10];

    int x[DATA_WIDTH];
    int y[DATA_WIDTH];
    double z[DATA_WIDTH];
    int start=0,atangens,stage=1;

    Lca1* lca1 = new Lca1("lca1");

    // bind inputs for simulation

    lca1->Cntlr_l.Clkusr.bind_input(clkusr);
    for (i = 0; i < 32; i++) {
      lca1->SBus.D[i].bind_input(in_sim[i]);
    }

    // create and initialize simulation
    lca1->logic();
    lca1->simul_setup();
    lca1->reset();
    clkusr = 0;

    // open data file 
    ifstream dfile("dat",ios::in); 
    
    printf("SIMULATION start\n\n");

    printf(" Parallel-Parallel CORDIC\n");
    printf(" Stages = S \n\n");

    printf("          cyc |  XIn   |  YIn   | PhiIn  |   X    |   Y    |   Z \n");
    printf("=======================================================================\n");	
    // simulate
    for (i = 0; i < SIM_CYCLES; i++) {
      // set inputs
      dfile >> datx;   
      dfile >> daty;   
      dfile >> datz;   

      if ((datx!=0)&&(start==0)){
	x[0]=datx;
	y[0]=daty;
	z[0]=((double)datz / 64.0);  // shift right by 6
	if (z[0]>=2.0) z[0]=z[0]-4.0;
	start=1;
      }
      if (datx==0){start=0;}

      for (j=0;j<8;j++){
 	in_sim[j]=(datx >> j) & 1L;
	in_sim[j+8]=(daty >> j) & 1L;
	in_sim[j+16]=(datz >> j) & 1L;
	in_sim[j+24]=0;
      }
      // compute logic and step the clock
      lca1->compute_outputs();
      lca1->tick();
      // display signal values

      printf("HARDWARE:  %02d | %06x | %06x | %06x | %c%06x | %c%06x | %06x\n",
	    i,
	    intval(lca1->XIn, 1,1),
	    intval(lca1->YIn, 1,1),
	    intval(lca1->PhiIn, 1,1),
	    intval(lca1->PP->X[abs(stage-2)], 1,1),
	    intval(lca1->PP->Y[abs(stage-2)],1,1),
	    intval(lca1->PP->Z[abs(stage-2)],1,1));

// Software CORDIC

     if ((start==1)||(stage>1)){
       printf("\nSOFTWARE: stage:%d \t\t X= %c%xH   Y= %c%xH   Z= %.4f \n",
	stage-1,
	((x[stage-1]>=0)?' ':'-'),abs(x[stage-1]),
	((y[stage-1]>=0)?' ':'-'),abs(y[stage-1]),
	z[stage-1]);

         x[stage]=x[stage-1]-y[stage-1]*intSign(z[stage-1])*pow((double)2,(double)(1-stage));
         y[stage]=y[stage-1]+x[stage-1]*intSign(z[stage-1])*pow((double)2,(double)(1-stage));
	 atangens=(int)(pow(2.0,STAGES-2.0)*atan(pow((double)2,(double)(1-stage))));
         z[stage]=z[stage-1]-doubleSign(z[stage-1])*((double)atangens/pow(2.0,STAGES-2));
	 if (stage<(STAGES+2)) stage++;
     }
    }

    printf("\nSIMULATION end.\n\n");
  }

return 0;
}



