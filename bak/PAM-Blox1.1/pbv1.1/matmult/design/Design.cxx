/*-----------------------------------------*/
/* RAW benchmark (derivative)              */
/*    2x2 Matrix Multiply 		   */
/*-----------------------------------------**************/ 
/*                                                      */
/* last mod 4/10/1998 by mencer                         */ 
/*      mod 2/18/1998 by hyukjunl                       */
/********************************************************/
#include "../../inc/GNUlicense.h"

/*-------------------------------------------------*/
/* Implementation:                                 */
/* 2x2 Matrix Multiplication using BUS architecture*/ 
/*   for Iterative Booth multiplier                */
/*-----------------------------------------        */

// import serial multiplier PaModules
#include "../../inc/sermult.h"

#define DATA_WIDTH 16
#define INPUT_WIDTH 8
#define ADDRESS_WIDTH 15
#define COUNT_WIDTH 4

#define NUM_MULT 4
#define NUM_ADDER 2

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

    default_clock(clkUsr);   		// set default clock
    clkUsr = Cntlr_l.Clkusr;
    clkUsr <<= GLOBAL_BUF(BUFG);
    one=~reg(ZERO);
    zero=~reg(ONE);

}
}; /* end LCA0 */


class Lca1 : public usrlca1 {
 public:
  int lcanum;

  Bool clkUsr, zero, one, start, sreset;

  WireVector<Bool, 16> addr, data_in,data_out;
  WireVector<WireVector<Bus, INPUT_WIDTH>,2>  data_out_bus;
  WireVector<WireVector<Bool, INPUT_WIDTH>,NUM_MULT> MultIn,MultOut;
  WireVector<WireVector<Bool, 2>,NUM_MULT> MPOut;
  WireVector<Bool, COUNT_WIDTH> count_out;               
  WireVector<Bool, NUM_MULT> MP_load,MP_shift,MP_last,MC_load,madder_reset;
  WireVector<Bool, 2> Pulldown, adder_reset;
  WireVector<WireVector<Bool, INPUT_WIDTH>,2>  AddIn;
  WireVector<WireVector<Bool, INPUT_WIDTH>,2>  AddOut;

  SerBoothMult8 *IBOOTHMULT[NUM_MULT];
  LAdd<INPUT_WIDTH>   *Adder[NUM_ADDER];
  RCounter<COUNT_WIDTH> *SCounter;
  Counter<16> *CR;

Lca1(char* name)
    : usrlca1(name, 30, chipnames[chiptype], chippackages[chiptype]) {

    internal(clkUsr); internal(zero); internal(one); internal(start);
    internal(addr); internal(data_in); internal(data_out);
    internal(data_out_bus); internal(count_out); internal(sreset);
    internal(MultIn); internal(MultOut); internal(MPOut);
    internal(MP_load); internal(MP_shift); internal(MP_last);internal(MC_load);
    internal(madder_reset); internal(adder_reset);
    internal(AddIn); internal(AddOut); internal(Pulldown);

    int i,j;

//  addr counter
    CR = new Counter<16>(&clkUsr,"addr_count");
    CR->out(addr);
    CR->place(Rect(19,15,1,8));

//  Multipliers
    for(i=0;i< NUM_MULT;i++){
       IBOOTHMULT[i]=new SerBoothMult8(MultIn[i],MP_load[i],
                         MP_shift[i],MC_load[i],MPOut[(i+1)%2+(i/2)*2], 
                         madder_reset[i], &clkUsr, make_name("mult"));
       IBOOTHMULT[i]->out(MultOut[i],MPOut[i]);
    }

    IBOOTHMULT[0]->place(2,13);
    IBOOTHMULT[1]->place(2,7);
    IBOOTHMULT[2]->place(8,13);
    IBOOTHMULT[3]->place(8,7);

// Adders
    W.EqualVector(data_out_bus[0],AddIn[0]);
    W.EqualVector(data_out_bus[1],AddIn[1]);

    Adder[0]=new LAdd<INPUT_WIDTH>(AddIn[0],AddOut[0],adder_reset[0],
				   &clkUsr,make_name("MMAdder"));
    Adder[0]->out(AddOut[0]);
    Adder[0]->place(Rect(15,13,1,4));

    Adder[1] = new LAdd<INPUT_WIDTH>(AddIn[1],AddOut[1],adder_reset[1],
				   &clkUsr,make_name("MMAdder"));
    Adder[1]->out(AddOut[1]);
    Adder[1]->place(Rect(15,7,1,4));

// state machine counter
    SCounter = new RCounter<COUNT_WIDTH>(sreset,&clkUsr,"state_counter");
    SCounter->out(count_out);

// Multiplier and Multiplication load signals

    MP_load[0] = reg(data_in[15] & data_in[14] & data_in[13] & data_in[12]);
    MP_load[1] = MP_load[0];    
    MP_load[2] = reg(MP_load[0]);
    MP_load[3] = MP_load[2];

    MC_load[0] = reg(MP_load[2]);
    MC_load[1] = MC_load[0];
    MC_load[2] = reg(MC_load[0]);
    MC_load[3] = MC_load[2];

    // Multiplier shift pulse generation
    MP_shift[0] = start;
    MP_shift[1] = MP_shift[0];
    MP_shift[2] = reg(MP_shift[0]);
    MP_shift[3] = MP_shift[2];

    // state machine reset
    sreset = MC_load[2]|(count_out[2] & ~count_out[1] & ~count_out[0]);

    // start
    start = reg(start | MC_load[0]);

    // reset signal for adder inside multiplier
    madder_reset[0] = reg(~count_out[2] & count_out[1] & count_out[0]);
    madder_reset[1] = madder_reset[0];
    madder_reset[2] = reg(madder_reset[0]);
    madder_reset[3] = madder_reset[2];

    // reset signal for final adder for inner product
    adder_reset[0] = reg(~(~count_out[2] & count_out[1] & count_out[0]));
    adder_reset[1] = adder_reset[0];

    // connect data input stream to multipliers
    for(j=0;j< NUM_MULT;j++){
      for (i=0;i<8;i++){
	MultIn[j][i] = data_in[(j%2)*8+i];
      }
    }

    // connect multiplier outputs to bus, which is an input to an adder
    for(j=0;j< NUM_MULT;j++){
      for (i=0;i<8;i++){
        data_out_bus[j%2][i] += tbuf(MultOut[j][i],~madder_reset[j]);
      }
    }
    
    Pulldown[0] = (madder_reset[0]|madder_reset[2]);
    Pulldown[1] = (madder_reset[1]|madder_reset[3]);

    for(j=0;j<2;j++){
      for(i=0;i<INPUT_WIDTH;i++){
        data_out_bus[j][i] += tbuf(zero,Pulldown[j]);
      }
    }

    // connect results from adders to output    
    for (i=0;i<8;i++){
      data_out[i]= AddOut[0][i];
      data_out[i+8]= AddOut[1][i];
    }

    // Output to SRAM
    for (i=0; i<DATA_WIDTH; i++)
      SRam.Data[i]=reg(data_out[i]);

    // communicating with the environment
    // connect address to SRAM address pins and bank select
    for (i = 0; i < ADDRESS_WIDTH; i++){
      SRam.Addr[i] = reg(addr[i]);
    }

    SRam._Bank[0] = ~reg(~addr[15]);
    SRam._Bank[1] = ~reg(addr[15]);

    // SBus input path
    for (i=0; i<data_in.get_n_elts(); i++){
        data_in[i] = reg(SBus.D[i]);
        data_in[i] <<= SBus.D[i]; 
    }
    SRam._Oe = one; 

    // Beware, SRAM is asynchronus.  We must generate a write pulse

    SRam._Write[0] = slow(~clkUsr);
    SRam._Write[1] = slow(~clkUsr);

    default_clock(clkUsr);   		// set default clock
    clkUsr = Cntlr_l.Clkusr;
    clkUsr <<= GLOBAL_BUF(BUFG);

    one = ~reg(ZERO);
    zero = ~reg(one);	

  }
};  // end userlca1

class LcaEmpty : public usrlca0 {
public:
  LcaEmpty(char* name)
    : usrlca0(name, 0) {}
  void logic() {}
};

////////////////////////////
// Generate the design
////////////////////////////

Design* GetUserDesign() {
  Design *design = new Design(mkname("matmult", chipnames[chiptype]+4));
  int seqn = 0;
  design->register_chip((ChipName) seqn++, new Lca0(mkname("lca0-", chipnames[chiptype]+4)));
  design->register_chip((ChipName) seqn++, new Lca1(mkname("lca1-", chipnames[chiptype]+4)));
  design->register_chip((ChipName) seqn++, new LcaEmpty(mkname("lcaem", chipnames[chiptype]+4)));
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

  } else {
    ////////////////////
    // simulate design
    ////////////////////
#define SIM_CYCLES 60

    int i, j, dat;
    int clkusr;
    int in_sim[16];

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
    FILE *dfile;
    char line[10];
    dfile=fopen("data2","r");
    
    printf("SIMULATION start\n\n");

    printf(" cnt |data_in   |st|MP|MC|PE|CE|tg|s1|s2|mr|ar|    MC   |   MP[0] | MP[2]  |  MuxOut | AddOut[0] | AddOut[2] |  AddIn[0]  |   SAdder  |  SRam.Data \n");
    printf("===================================================================================================================================================\n"); 

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

      printf("  %02d | %08x |%d |%d |%d |%d |%d |%d |%d |%d |%d |%d | %08x | %08x | %08x | %08x | %08x | %08x | %08x | %08x | %08x\n",
            intval(lca1->count_out,1,1),
            intval(lca1->data_in, 1,1),

            lca1->start.get_value(),
            lca1->IBOOTHMULT[0]->MPstart.get_value(),
            lca1->IBOOTHMULT[0]->MCstart.get_value(),
            lca1->IBOOTHMULT[0]->MPenable.get_value(),
            lca1->IBOOTHMULT[0]->MCenable.get_value(),
            lca1->IBOOTHMULT[0]->toggle.get_value(),
            lca1->IBOOTHMULT[0]->sel1.get_value(),
            lca1->IBOOTHMULT[0]->sel2.get_value(),
            lca1->madder_reset[0].get_value(),
            lca1->adder_reset[0].get_value(),
            intval(lca1->IBOOTHMULT[0]->MC,1,1),
            intval(lca1->IBOOTHMULT[0]->MP,1,1),
            intval(lca1->IBOOTHMULT[0]->MP,1,1),
            intval(lca1->IBOOTHMULT[0]->MuxOut,1,1),
            intval(lca1->IBOOTHMULT[0]->AddOut,1,1),
            intval(lca1->IBOOTHMULT[2]->AddOut,1,1),
            intval(lca1->AddIn[0],1,1),
            intval(lca1->AddOut[0],1,1),
            intval(lca1->SRam.Data,1,1));
    }
    fclose(dfile);
    printf("\nSIMULATION end.\n\n");

  }// else simulate

  return 0;
} 










