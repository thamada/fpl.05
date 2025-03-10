/*-----------------------------------------*/
/* RAW benchmark                           */
/*    JACOBI relaxation (8 bit, 4x4 grid)  */
/*-----------------------------------------**************/ 
/*                                                      */
/* This design can be used to test arithmetic units     */ 
/* last mod 4/10/1998 by mencer                         */ 
/********************************************************/
#include "../../inc/GNUlicense.h"

/*-----------------------------------------*/
/* Implementation:                         */
/* 4x4 grid of 2x2 active cells            */
/*
 *	     X0  X1
 *	X3  Y08 Y09  X2
 *	X4  Y10 Y11  X5
 *           X7 X6
 *
 * X are holding the boundary condition. 
 * Ys are active cells
 * Zs are diagonal adders 
 *-----------------------------------------*/

#define X_NUM 8
#define Y_NUM 4
#define Z_NUM 7

// import PamBlox
#include "../../inc/pamblox.h"

/* sets placemet. #undef OPTIPLACE lets the Xilinx tools do the job */
#define OPTIPLACE
#define DATA_WIDTH 8

#define DEBUG printf

class Lca1 : public usrlca1 {
 public:
  Bool clkUsr;
  int lcanum;
  Bool zero,one;
  Bool load;
  WireVector<Bool, 16> addr;		// SRam Address Register
  WireVector<Bool, 8> data_in;		// Input Register

  WireVector<WireVector<Bool, DATA_WIDTH>, X_NUM> X;
  WireVector<WireVector<Bool, DATA_WIDTH>, Y_NUM> Y;
  WireVector<WireVector<Bool, DATA_WIDTH>, Y_NUM> YOut;
  WireVector<WireVector<Bool, DATA_WIDTH>, Y_NUM> Yshift;
  WireVector<Bool, Y_NUM> Ycout;
  WireVector<Bool, Y_NUM> Ycin;
  WireVector<WireVector<Bool, DATA_WIDTH>, Z_NUM> Z;
  WireVector<WireVector<Bool, DATA_WIDTH>, Z_NUM> Zshift;
  WireVector<Bool, Z_NUM> Zcout;

Lca1(char* name)
    : usrlca1(name, 30, chipnames[chiptype], chippackages[chiptype]) {

    internal(clkUsr); internal(zero); internal(one);
    internal(addr); internal(data_in);
    internal(X); internal(Y);  internal(Ycout); internal(Yshift);
    internal(Ycin); internal(YOut); internal(Z); internal(Zcout);
    internal(Zshift); internal(load);

// addr counter

    Counter<16> *CR;
    CR=new Counter<16>(&clkUsr,"addr_count");
    CR->out(addr);
    CR->place();

// Jacobi
    int i,j;
// boundary conditions

    Register<DATA_WIDTH> *XReg[X_NUM];
    XReg[0]=new Register<DATA_WIDTH>(load,data_in,&clkUsr,"XReg0");

    for (i=1;i<X_NUM;i++)
    	XReg[i]=new Register<DATA_WIDTH>(load,X[i-1],&clkUsr);

    for (i=0;i<X_NUM;i++){
	XReg[i]->out(X[i]);
#ifndef OPTIPLACE
        XReg[i]->place();
#endif
    }

#ifdef OPTIPLACE
    XReg[0]->place(Rect(2,8,1,4));
    XReg[1]->place(Rect(10,14,1,4));
    XReg[2]->place(Rect(11,14,1,4));
    XReg[3]->place(Rect(3,8,1,4));
    XReg[4]->place(Rect(12,14,1,4));
    XReg[5]->place(Rect(4,8,1,4));
    XReg[6]->place(Rect(5,8,1,4));
    XReg[7]->place(Rect(13,14,1,4));
#endif

    CAdd<DATA_WIDTH> *ZAdd[Z_NUM];
    ZAdd[0]=new CAdd<DATA_WIDTH>(X[0],X[3],zero,&clkUsr,"ZAdd0");
    ZAdd[1]=new CAdd<DATA_WIDTH>(X[1],YOut[0],zero,&clkUsr,"ZAdd1");
    ZAdd[2]=new CAdd<DATA_WIDTH>(YOut[0],X[4],zero,&clkUsr,"ZAdd2");
    ZAdd[3]=new CAdd<DATA_WIDTH>(YOut[1],YOut[2],zero,&clkUsr,"ZAdd3");
    ZAdd[4]=new CAdd<DATA_WIDTH>(YOut[3],X[2],zero,&clkUsr,"ZAdd4");
    ZAdd[5]=new CAdd<DATA_WIDTH>(YOut[3],X[7],zero,&clkUsr,"ZAdd5");
    ZAdd[6]=new CAdd<DATA_WIDTH>(X[5],X[6],zero,&clkUsr,"ZAdd6");

    for(i=0;i<Z_NUM;i++){
      ZAdd[i]->out(Z[i],&Zcout[i]);
#ifndef OPTIPLACE
      ZAdd[i]->place();
#endif
      for(j=0;j<DATA_WIDTH;j++){
	if(j==(DATA_WIDTH-1))
         Zshift[i][j]=Zcout[i];
	else
         Zshift[i][j]=Z[i][j+1];
      }
    }

#ifdef OPTIPLACE
    ZAdd[0]->place(Rect(2,14,1,4));
    ZAdd[1]->place(Rect(6,8,1,4));
    ZAdd[2]->place(Rect(8,8,1,4));
    ZAdd[3]->place(Rect(3,14,1,4));
    ZAdd[4]->place(Rect(7,8,1,4));
    ZAdd[5]->place(Rect(9,8,1,4));
    ZAdd[6]->place(Rect(5,14,1,4));
#endif
// active cells
    CAdd<DATA_WIDTH> *YAdd[Y_NUM];      // combinatorial add (no register) 
    MuxReg<DATA_WIDTH> *Yselect[Y_NUM]; // load/unload cells 

    for(i=0;i<Y_NUM;i++){
      Ycin[i]=(Z[i][0]&Z[3+i][0]);

      if (i!=0)
         YAdd[i]=new CAdd<DATA_WIDTH>(Zshift[i],Zshift[3+i],Ycin[i]);
      else
         YAdd[i]=new CAdd<DATA_WIDTH>(Zshift[i],Zshift[3+i],Ycin[i]);

      YAdd[i]->out(Y[i],&Ycout[i]);
#ifdef OPTIPLACE
      YAdd[i]->place();	
#endif
      for (j=0;j<DATA_WIDTH;j++){
	if(j==(DATA_WIDTH-1))
	  alias(Yshift[i][j],Ycout[i]);
	else
          alias(Yshift[i][j],Y[i][j+1]);
      }
      if (i==0)
	Yselect[i]=new MuxReg<DATA_WIDTH>(load,X[X_NUM-1],Yshift[i]);
      else
        Yselect[i]=new MuxReg<DATA_WIDTH>(load,YOut[i-1],Yshift[i]);

      Yselect[i]->out(YOut[i]);
#ifndef OPTIPLACE
      Yselect[i]->place();
#endif
    }

#ifdef OPTIPLACE
    YAdd[0]->place(Rect(6,14,1,4));
    YAdd[1]->place(Rect(10,8,1,4));
    YAdd[2]->place(Rect(12,8,1,4));
    YAdd[3]->place(Rect(8,14,1,4));
    Yselect[0]->place(Rect(7,14,1,4));
    Yselect[1]->place(Rect(11,8,1,4));
    Yselect[2]->place(Rect(13,8,1,4));
    Yselect[3]->place(Rect(9,14,1,4));
#endif
 
    default_clock(clkUsr);   		// set default clock
    clkUsr = Cntlr_l.Clkusr;
    clkUsr <<= GLOBAL_BUF(BUFG);
    zero=reg(~ONE);
    one=reg(~ZERO);

    load=data_in[7];  /* for test only */

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

    // Beware, SRAM is asynchronus.  We must generate a write pulse

    SRam._Write[0] = slow(~clkUsr);
    SRam._Write[1] = slow(~clkUsr);

    for (i=0; i<DATA_WIDTH; i++){
	SRam.Data[i]=reg(YOut[3][i]);
    }

  }// end logic

};  // end userlca1

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

// standard empty LCA
class LcaEmpty : public usrlca0 {
public:
  LcaEmpty(char* name)
    : usrlca0(name, 0, chipnames[chiptype], chippackages[chiptype]) {
  }
  void logic(){}
};

////////////////////////////
// Generate the design
////////////////////////////

Design* GetUserDesign() {
  Design *design = new Design(mkname("jacobi", chipnames[chiptype]+4));
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

    //  } else {
    ////////////////////
    // simulate design
    ////////////////////
  }
     return 0;
}



