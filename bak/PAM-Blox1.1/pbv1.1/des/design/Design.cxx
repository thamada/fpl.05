/*-----------------------------------------*/
/* DES Fixed Key Encryption Implementation */
/*-----------------------------------------*/
/*                                         */
/* This design implements fixed key DES    */
/* Encryption.                             */
/* last mod 6/6/1998 by mencer             */
/*  created 4/27/1998 by hcleung           */
/*******************************************/
#include "../../inc/pamblox.h"
#include "./des.h"

// If DECRYPT is defined, the design would be compiled for decryption.
// It uses the same fixed key as for encryption.  This is one way to
// verify that the design decrypts correctly what it encrypts        
#undef DECRYPT

class Lca1 : public usrlca1 {
 public:

  // Standard stuff plus interface to SRAM
  Bool clkUsr;                          // Clock
  int lcanum;                           // LCA Number, not really used
  int pegX, pegY;                       // lower left corner of placement peg
  Bool zero,one;                        // Constants 1 and 0
  Bool load;                            // Enables load of input data
  WireVector<Bool, COUNT_WIDTH> state;	// State machine counter
  WireVector<Bool, INPUT> addr;	        // SRAM address register
  WireVector<Bool, INPUT> data_in;	// Input Register

  // Input / Output of chip
  WireVector<Bool, DATA> X;             // 64 bit data
  WireVector<Bool, INPUT> X1;           // 16 bit data segment
  WireVector<Bool, INPUT> X2;           // 16 bit data segment
  WireVector<Bool, INPUT> X3;           // 16 bit data segment
  WireVector<Bool, INPUT> X4;           // 16 bit data segment
  WireVector<Bool, DATA> Out;           // 64 bit output
  WireVector<Bool, DATA> Out1;          // 64 bit output, latched
  WireVector<Bool, DATA> SBusprep;      // 64 bit output, prep for IOB
  WireVector<Bool, DATA> SBusprep1;     // 64 bit output, prep for IOB
  WireVector<Bool, DATA> SBusprep2;     // 64 bit output, prep for IOB
  WireVector<Bool, COUNT_WIDTH> val;    // 4 bit load value to counter
  WireVector<Bool, COUNT_WIDTH> Ready;     // 4 bit ready shifted indicator

  // Internal signals - refer to block diagram
  WireVector<Bool, INPUT> A;            // Input 16 bit data streams 
  WireVector<Bool, SHIFT_IN> loadShift; // Shifted version of load signal
  WireVector<Bool, DATA> Data; 
  WireVector<Bool, HALFDATA> L; 
  WireVector<Bool, HALFDATA> R; 
  WireVector<Bool, HALFDATA> RStage; 
  WireVector<Bool, DATA3Q> E; 
  WireVector<Bool, DATA3Q> InRom; 
  WireVector<Bool, DATA3Q> RomStage1;
  WireVector<WireVector<Bool, SHIFT_IN>, SWIDTH> TRom;
  WireVector<WireVector<Bool, SHIFT_IN>, SWIDTH> TRomStage1;
  WireVector<WireVector<Bool, SHIFT_IN>, SWIDTH> TRomStage2;
  WireVector<WireVector<Bool, SHIFT_IN>, SWIDTH> TRomStage3;
  WireVector<WireVector<Bool, SHIFT_IN>, SWIDTH> TRomStage4;
  WireVector<Bool, HALFDATA> Sub; 
  WireVector<Bool, HALFDATA> Perm; 
  WireVector<Bool, HALFDATA> Xor; 
  WireVector<Bool, DATA> FF; 
  WireVector<Bool, DATA> Merge; 
  Bool count_0;                         // indicates counter value = 0
  Bool Enable;                          // Enable counter

  Lca1(char* name)
    : usrlca1(name, 30, chipnames[chiptype], chippackages[chiptype]) {
    internal(clkUsr); internal(zero); internal(one); internal(state);
    internal(data_in); internal(load); internal(X); internal(X1);
    internal(X2); internal(X3); internal(X4); internal(Out);
    internal(Out1); internal(SBusprep); internal(SBusprep1);
    internal(SBusprep2); internal(val); internal(Ready); 
    internal(A); internal(loadShift); internal(Data); internal(L);
    internal(R); internal(RStage); internal(E); internal(InRom);
    internal(RomStage1); internal(TRom); internal(TRomStage1);
    internal(TRomStage2); internal(TRomStage3); internal(TRomStage4);
    internal(Sub); internal(Perm); internal(Xor); internal(FF);
    internal(Merge); internal(count_0); internal(Enable); internal(addr);

    int i,j;

    // set corner peg of placement
    pegX = 0;
    pegY = 19;

    // state counter
    LECounter<COUNT_WIDTH> *CR;
    CR=new LECounter<COUNT_WIDTH>(load, val, Enable, &clkUsr,"state_count");
    CR->out(state);
    CR->place();

    // SRAM address counter
    Counter<INPUT> *CR2;
    CR2=new Counter<INPUT>(&clkUsr,"addr_count");
    CR2->out(addr);
    CR2->place();

    // Register inputs
    Register<INPUT> *AReg;
    AReg = new Register<INPUT>(loadShift[0], data_in, &clkUsr, "AReg");
    AReg->out(X1);
    AReg->place(Rect(pegX+1, pegY, SWIDTH, 1));
    Register<INPUT> *BReg;
    BReg = new Register<INPUT>(loadShift[1], data_in, &clkUsr, "BReg");
    BReg->out(X2);
    BReg->place(Rect(pegX+SWIDTH+1, pegY, SWIDTH, 1));
    Register<INPUT> *CReg;
    CReg = new Register<INPUT>(loadShift[2], data_in, &clkUsr, "CReg");
    CReg->out(X3);
    CReg->place(Rect(pegX+1, pegY-1, SWIDTH, 1));
    Register<INPUT> *DReg;
    DReg = new Register<INPUT>(loadShift[3], data_in, &clkUsr, "DReg");
    DReg->out(X4);
    DReg->place(Rect(pegX+SWIDTH+1, pegY-1, SWIDTH, 1));

    Register<DATA> *DataReg;
    DataReg = new Register<DATA>(Ready[0], Out, &clkUsr, "DataReg");
    DataReg->out(Out1);
    DataReg->place(Rect(pegX+1, pegY-17, INPUT,2));

    // Control counter
    count_0 = ~(state[1] | state[2] | state[3] | state[4]);

    // Interface stuff...Merge 16 bit input streams into 64bit data
    for (i=0; i<INPUT; i++) {
        alias(X[i], X1[i]);
        alias(X[i+INPUT], X2[i]);
        alias(X[i+HALFDATA], X3[i]);
        alias(X[i+DATA3Q], X4[i]);
    }

    // connect address to SRAM address pins and bank select
    for (i = 0; i < 15; i++)
      SRam.Addr[i] = reg(addr[i]);

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

    /* For testing only, valid data is such that bit 15 of the first 16
       bit chunk had a '1' */
    loadShift[0] = data_in[15] & (~reg(data_in[15])) &
        (~reg(reg(data_in[15]))) & (~reg(reg(reg(data_in[15]))));  
    for (i=1; i<SHIFT_IN; i++) 
        loadShift[i] = reg(loadShift[i-1]);
    loadShift[2] <<= loadShift[1];
  
    load = ~reg(~loadShift[3]);
    load <<= loadShift[3];

    // make load value 0
    for (i=0; i<COUNT_WIDTH; i++)
        val[i] = ~reg(~ZERO);    
   
    Enable = ~(state[4] & state[3] & state[2] & state[1] & state[0]);
    Enable <<= Enable; 

    // IP Stage
    for (i=0; i<DATA; i++)
        alias(X[IP[i]-1], Data[i]);
    
    // 2 to 1 mux Stage
    for (i=0; i<HALFDATA; i++) {
        L[i] = reg(mux(count_0, Data[i], FF[i]));
        R[i] = mux(count_0, Data[i+HALFDATA], FF[i+HALFDATA]);
        L[i] <<= L[i];
        L[i] <<= LOC(pegX+i/2, pegY-2);
        R[i] <<= R[i];
        R[i] <<= LOC(pegX+i/2, pegY-3);
        if (i%2) {
            L[i] <<= L[i-1];
            R[i] <<= R[i-1];
        }
    }

    // Expand Stage
    for (i=0; i<DATA3Q; i++) 
        alias(E[i], R[Exp[i]-1]);

    // Clock RStage
    for (i=0; i<HALFDATA; i++) {
        RStage[i] = reg(R[i]);
        if (i%2)
            RStage[i] <<= RStage[i-1];
        RStage[i] <<= LOC(pegX+i/2, pegY-16);
    }

    // 48 XOR2 Stage, at the same time "process" key
#ifdef DECRYPT
    const int ord[INPUT]={15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};
#else
    const int ord[INPUT]={0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
#endif
    
    for (i=0; i<DATA3Q; i++) {
     RomStage1[i] = mux(state[4], mux(state[3], mux(state[2], 
      mux(state[1], retEH(fixK[genK[ord[15]][i]]), retEH(fixK[genK[ord[14]][i]])),
      mux(state[1], retEH(fixK[genK[ord[13]][i]]),retEH(fixK[genK[ord[12]][i]]))),
      mux(state[2], 
      mux(state[1], retEH(fixK[genK[ord[11]][i]]), retEH(fixK[genK[ord[10]][i]])),
      mux(state[1], retEH(fixK[genK[ord[9]][i]]), retEH(fixK[genK[ord[8]][i]])))),
      mux(state[3], mux(state[2], 
      mux(state[1], retEH(fixK[genK[ord[7]][i]]), retEH(fixK[genK[ord[6]][i]])),
      mux(state[1], retEH(fixK[genK[ord[5]][i]]), retEH(fixK[genK[ord[4]][i]]))),
      mux(state[2], 
      mux(state[1], retEH(fixK[genK[ord[3]][i]]), retEH(fixK[genK[ord[2]][i]])),
      mux(state[1],retEH(fixK[genK[ord[1]][i]]),retEH(fixK[genK[ord[0]][i]])))));
      RomStage1[i] <<= RomStage1[i];
      if (i%2) 
         RomStage1[i] <<= RomStage1[i-1];
      if (i < (2*CLB_ROW))
         RomStage1[i] <<= LOC(pegX+i/2, pegY-4);
      
      InRom[i] = reg(RomStage1[i] ^ E[i]);
      InRom[i] <<= LOC(pegX+i%INPUT, pegY-5-i/INPUT);
    }
                    
    // ROM Stage
    for (i=0; i<SWIDTH; i++) {
        for(j=0; j<SHIFT_IN; j++) 
            alias(TRom[i][j], InRom[i*6+rommap[j]]);
        for(j=0; j<SHIFT_IN; j++) {
            TRomStage1[i][j] = rom(TRom[i], S[i][3][j]);
            TRomStage2[i][j] = rom(TRom[i], S[i][2][j]);
            TRomStage2[i][j] <<= TRomStage1[i][j];
            TRomStage2[i][j] <<= LOC(pegX+(i*SHIFT_IN+j)%INPUT, 
                                      pegY-8-(i*SHIFT_IN+j)/INPUT);
            TRomStage3[i][j] = rom(TRom[i], S[i][1][j]);
            TRomStage4[i][j] = rom(TRom[i], S[i][0][j]);
            TRomStage3[i][j] <<= TRomStage4[i][j];
            TRomStage3[i][j] <<= LOC(pegX+(i*SHIFT_IN+j)%INPUT, 
                                      pegY-10-(i*SHIFT_IN+j)/INPUT);
            Sub[i*SHIFT_IN+j] = mux(InRom[i*6], 
                         mux(InRom[i*6+5], TRomStage1[i][j], TRomStage2[i][j]),
                         mux(InRom[i*6+5], TRomStage3[i][j], TRomStage4[i][j]));
            Sub[i*SHIFT_IN+j] <<= Sub[i*SHIFT_IN+j]; 
            Sub[i*SHIFT_IN+j] <<= LOC(pegX+(i*SHIFT_IN+j)%INPUT, 
                                      pegY-12-(i*SHIFT_IN+j)/INPUT);
        }
    }

    // PermP Stage
    for (i=0; i<HALFDATA; i++)
        alias(Perm[i], Sub[PermP[i]-1]);

    // 32 XOR2 Stage
    for (i=0; i<HALFDATA; i++) {
        Xor[i] = L[i] ^ Perm[i];
        if (i % 2)
           Xor[i] <<= Xor[i-1];
        Xor[i] <<= LOC(pegX+i/2, pegY-14);
   }

    // Swap and Register Stage
    for (i=0; i<HALFDATA; i++) {
          Merge[i] = reg(Xor[i]);
          Merge[i+HALFDATA] = reg(RStage[i]);
          alias(FF[i], Merge[i+HALFDATA]);
          alias(FF[i+HALFDATA], Merge[i]);
          Merge[i] <<= Xor[i];
          if (i%2)  
              Merge[i+HALFDATA] <<= Merge[i+HALFDATA-1];
          Merge[i+HALFDATA] <<= LOC(pegX+i/2, pegY-15);
    }

    // Final Permutation (IIP) Stage 
    for (i=0; i<DATA; i++) 
        alias(Merge[IIP[i]-1], Out[i]);

    // Ready signals
    Ready[0] = reg(reg(state[4] & state[3] & state[2] & state[1] &(~state[0])));
    Ready[0] <<= Ready[0];
    for (i=1; i<SHIFT_IN; i++) 
        Ready[i] = reg(Ready[i-1]);
    Ready[4] = (Ready[0] | Ready[1] | Ready[2] | Ready[3]);
    Ready[4] <<= Ready[3];
    Ready[2] <<= Ready[1];
  
    // Divide output into 16bit chunks for now --- CHEONG
    for (i=0; i<INPUT; i++){
     SBusprep1[i] = (Ready[0] & Out[i]) | (Ready[1] & Out1[i+INPUT]);
     SBusprep2[i] = (Ready[2] & Out1[i+HALFDATA]) | (Ready[3] & Out1[i+DATA3Q]);
     SBusprep[i] = SBusprep1[i] | SBusprep2[i];
     SBusprep[i] <<= SBusprep1[i];
     SBusprep[i] <<= SBusprep2[i];
     SBusprep[i] <<= LOC(pegX+i, pegY-19);
     SRam.Data[i] = reg(SBusprep[i]);
    }

    // Beware, SRAM is asynchronus.  We must generate a write pulse
    SRam._Write[0] = slow(~clkUsr);
    SRam._Write[1] = slow(~clkUsr);

    // Associated data ready signal on SBus.D[16] - temporary snuffed out
    SBus.X[0][0] = reg(Ready[4]);
    
    default_clock(clkUsr);   		// set default clock
    clkUsr = Cntlr_l.Clkusr;
    clkUsr <<= GLOBAL_BUF(BUFG);
    zero=reg(~ONE);
    one=reg(~ZERO);
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
    internal(clkUsr);    internal(addr);
    internal(carry);    internal(zero);    internal(one);
    internal(data);      internal(RamWrite);

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
    for (i=0; i<16; i++)
    {
      data[i]=reg(SRam.Data[i]);
      data[i]<<=SRam.Data[i]; 
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


// Standard empty LCA
class LcaEmpty : public usrlca0 {
public:
  LcaEmpty(char* name)
    : usrlca0(name, 0, chipnames[chiptype], chippackages[chiptype]) {
  }
  void logic() {}
};

////////////////////////////
// Generate the design
////////////////////////////
Design* GetUserDesign() {
  Design *design = new Design(mkname("des", chipnames[chiptype]+4));
  int seqn = 0;
  design->register_chip((ChipName) seqn++, new Lca0(mkname("lca0-",
                        chipnames[chiptype]+4)));
  design->register_chip((ChipName) seqn++, new Lca1(mkname("lca1-",
                        chipnames[chiptype]+4)));
  design->register_chip((ChipName) seqn++, new LcaEmpty(mkname("lcaem",
                        chipnames[chiptype]+4)));
  design->register_chip((ChipName) seqn++, new LcaEmpty(mkname("lcaem",
                        chipnames[chiptype]+4)));
  
  return design;

}


////////////////////////////
// Simulation support
////////////////////////////
/*
 convert wire vector 'a' into integer value, provided that
 'a[i]' matches 'wanting'. 'allowFloating' allows for floating
 values on 'a[i]'
*/
static long intval32bits(Wire& a, int wanting, int allowFloating, int upper32)
{
  unsigned long v = 0, i;
  assert((a.is_vector() == 1) && (a.get_n_elts() > 0) &&
         (a.get_elt(0)->get_bool()));
  int add = upper32 ? 32 : 0;
  unsigned int num = ((a.get_n_elts()-add) > 32) ? 32 : (a.get_n_elts()-add);
  for (i = 0; i < num; i++) {
    assert(allowFloating ||
           (a.get_elt(i+add)->get_bool()->get_value() != 2));
    if (a.get_elt(i+add)->get_bool()->get_value() == wanting) {
        v |= 1L<<(num-i-1);
    }
  }
  return v;
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
#define SIM_CYCLES 60

    // with "s" option, simulate design
#define DATA1 "10010110"
#define DATA2 "00010101"
#define DATA3 "01001010"
#define DATA4 "11011100"
#define DATA5 "10111011"
#define DATA6 "10100000"
#define DATA7 "01000100"
#define DATA8 "10011010"

#define ENC1 "11000000" 
#define ENC2 "11000111"
#define ENC3 "01011000"
#define ENC4 "11101111"
#define ENC5 "10001000"
#define ENC6 "00100101"
#define ENC7 "01011100"
#define ENC8 "00001100"

#define SIM_CYCLES 60
    int i, j;
    int clkusr;
    const char input1[65] = DATA1 DATA2 DATA3 DATA4 DATA5 DATA6 DATA7 DATA8;
    const char input2[65] = ENC1 ENC2 ENC3 ENC4 ENC5 ENC6 ENC7 ENC8;
    int in_sim_X[64]; 
    Lca1* lca1 = new Lca1("lca1");
    lca1->Cntlr_l.Clkusr.bind_input(clkusr);
    for (i=0; i<16; i++)  
       lca1->SBus.D[i].bind_input(in_sim_X[i]); 

    // Create and initialize simulation
    lca1->logic();
    lca1->simul_setup();
    lca1->reset();
    clkusr = 0;

    printf("Simulation begin\n");
    // Compute logic and step the clock
    for (i=0; i<SIM_CYCLES; i++) {
        if (i < 4) {
            for (j=0; j<16; j++) 
#ifdef DECRYPT
                in_sim_X[j] = input2[(i%4)*16+j] - '0';
#else
                in_sim_X[j] = input1[(i%4)*16+j] - '0';
#endif
        } else {
            for (j=0; j<16; j++) 
                in_sim_X[j] = 0;
        }
   
        lca1->compute_outputs();
        lca1->tick();
  
        //display values
        printf("%d: X:%8x%8x | In:%4x |Rdy:%4x |c:%d |Ram:%4x |Out:%8x%8x\n",
                                       i,
                                       intval32bits(lca1->X,1,1,0),
                                       intval32bits(lca1->X,1,1,1),
                                       intval32bits(lca1->data_in,1,1,0),
                                       intval32bits(lca1->Ready,1,1,0),
                                       lca1->count_0.get_value(),
                                       intval32bits(lca1->SRam.Data,1,1,0),
                                       intval32bits(lca1->Out,1,1,0),
                                       intval32bits(lca1->Out,1,1,1));
    }
    printf("Simulation end.\n\n");
  }
  
  return 0;
}
