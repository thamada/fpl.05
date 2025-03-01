/*---------------------------------------------------------*/
/*  sermult.h: Serial Booth Multipliers                    */
/*---------------------------------------------------------*/
/* PAM-Blox version 1.1:                                   */
/* object-oriented circuit generators for custom computing */
/*                     Oskar Mencer                        */ 
/*      Computer Architecture and Arithmetic Group         */
/*                  Stanford University                    */
/*                                                         */
/* last mod 6/6/1998 by mencer                             */
/*      mod 2/18/1998 by hyukjunl                          */
/***********************************************************/
#include "GNUlicense.h"

#ifndef SERMULT_H
#define SERMULT_H

#include "pamblox.h"

#define INPUT_WIDTH 8

// SerBooth8: serial radix 2 booth multiplier  <BR>
//      THROUGHPUT: 1 mult / 5 cycles          <BR>
//            AREA: about 4 columns 5 rows (20 CLBs)  <BR>
//
//      remark: Multiplier is loaded in two ways      <BR>
//              parallel (8 bit) & serial (4bits)     <BR>

class SerBoothMult8 : public PMtop {
 public:

  WireVector<Bool, INPUT_WIDTH> data_in;
  WireVector<Bool, 2> MPSerialIn;
  WireVector<Bool, INPUT_WIDTH> MC,MCI;
  WireVector<Bool, INPUT_WIDTH+2> MP,MPI;
  WireVector<Bool, INPUT_WIDTH+1>  MC2,and,imux,MuxOut,AddOut, AddIn;
  Bool MPstart,MPshift,MPenable,MCstart,MCenable,toggle,sel1,sel2,MP_3;
  Bool AddReset, AddCarryIn;

  RAddCin<INPUT_WIDTH+1> *RADD;

  SerBoothMult8(
	     WireVector<Bool, INPUT_WIDTH>& In,
	     Bool& MP_load,
	     Bool& MP_shift,
	     Bool& MC_load,
             WireVector<Bool,2>& MPSerIn,
             Bool& AdderReset,
	     Bool *clock=NULL,                      
	     const char *name=NULL): 
	       PMtop(clock,name){

        NAME(data_in);	NAME(MC);	NAME(MCI);	NAME(MP);
	NAME(MPI);	NAME(MC2);	NAME(MPstart);	NAME(MPshift);
	NAME(MPenable);	NAME(MCstart);	NAME(MCenable);	NAME(toggle);
	NAME(sel1);	NAME(sel2);     NAME(MP_3);     NAME(and);
  	NAME(imux);   	NAME(MuxOut);  	NAME(AddOut); NAME(AddCarryIn);
        NAME(AddReset);	NAME(MPSerialIn); NAME(AddIn);

	int i;

	MPstart=MP_load;
	MPshift=MP_shift;
        MCstart=MC_load;

	// Multiplier Serial Input from neighbor multiplier
        MPSerialIn[1] = MPSerIn[1];
        MPSerialIn[0] = MPSerIn[0];

        // Rippple Adder Reset
        AddReset = AdderReset;

	// Parallel input for multiplicand and multiplier
	for(i=0;i<INPUT_WIDTH;i++){
	  data_in[i]=In[i];
	}
}

void out(WireVector<Bool, INPUT_WIDTH>& Out, 
	 WireVector<Bool, 2>& MPOut){

        int i;		
 
	// Multiplicand or Multiplicand_bar
	toggle = MP[INPUT_WIDTH-1]^MP[INPUT_WIDTH-3];

	//toggle = reg(MP[INPUT_WIDTH-1]^MP[INPUT_WIDTH-3],clk);
	MCenable = MCstart | toggle;

	for(i=0; i<INPUT_WIDTH; i++){
		MCI[i] = (MCstart & ~toggle & data_in[i]) |
			 (MCstart & toggle  & ~data_in[i]) |
			 (~MCstart & toggle & ~MC[i]);
	        MC[i]  = reg(mux(MCenable,MCI[i],MC[i]),clk);
		MC[i]  <<= CLB_INPUT(EC,MCenable);
	}

	// Multiplicand * 2 => shifted to the left by 1
	for(i=0; i<INPUT_WIDTH+1 ;i++){
                if(i==0){
                  //MC2[i] = reg(MP[INPUT_WIDTH-1],clk);   // or reg(MP[])
		  MC2[i] = MP[INPUT_WIDTH-1];
		}
		else{
		  MC2[i] = MC[i-1];
		}
	}

        MPenable = MPstart | MPshift;

	// Multiplier => shifted to the right by 2
	for(i=0;i<INPUT_WIDTH+2;i++){
	  if(i<2){
	    MPI[i] = mux(MPstart,data_in[i],MPSerialIn[i]);
	    MP[i]  = reg(mux(MPenable,MPI[i],MP[i]),clk);
	    MP[i]  <<= CLB_INPUT(EC,MPenable); 
	  }else if(i<INPUT_WIDTH){
	    MPI[i] = mux(MPstart,data_in[i],MP[i-2]);
	    MP[i]  = reg(mux(MPenable,MPI[i],MP[i]),clk);
	    MP[i]  <<= CLB_INPUT(EC,MPenable); 
	  }else{
	    MPI[i] = mux(MPstart,zero,MP[i-2]);
	    MP[i]  = reg(mux(MPenable,MPI[i],MP[i]),clk);
	    MP[i]  <<= CLB_INPUT(EC,MPenable); 	    
	  }
	}

	// Shift two MSBs out
	MPOut[1] = MP[INPUT_WIDTH+1]; 
	MPOut[0] = MP[INPUT_WIDTH];

	// Implicit 3 to 1 multiplexer : (+,-) 0,MC,MC*2
	sel1=MP[INPUT_WIDTH-3]^MP[INPUT_WIDTH-2];
	sel2=MP[INPUT_WIDTH-2]^MP[INPUT_WIDTH-1];

	for(i=0; i< INPUT_WIDTH+1;i++){

          if(i!= INPUT_WIDTH){
	    and[i] = sel1&MC[i];
	    imux[i] = mux(sel1,MC[i],MC2[i]);
          }else{
	    and[i] = sel1&MC[i-1];
	    imux[i] = MC[i-1];		// sign extended
          }	
	  MuxOut[i] = reg(mux(sel2,imux[i],and[i]),clk); 
	  imux[i] <<= MuxOut[i];
	  and[i] <<= MuxOut[i];
	}

        W.ShiftLeft(AddOut,AddIn,2);
	AddCarryIn = MuxOut[INPUT_WIDTH];
        RADD=new RAddCin<INPUT_WIDTH+1>(MuxOut,AddIn,AddCarryIn,AddReset,
				    &clk,make_name("Adder"));
        RADD->out(AddOut);
        RADD->place();	
        AddOut[0]<<= MP[0] + OFFSET(3,0);  

	for(i=0;i<INPUT_WIDTH;i++){
	  Out[i] = AddOut[i];
	}

}

void place(){

  int i;

  for (i=1;i<INPUT_WIDTH+2;i++){
    MP[i] <<= MP[0]+OFFSET(0,-(i/2)); 
  }
  toggle <<= MP[0]+OFFSET(0,-(INPUT_WIDTH+2)/2); 

  for (i=0;i<INPUT_WIDTH;i++){
    MC[i] <<= MP[0]+OFFSET(1,-(i/2)); 
    MCI[i] <<= MP[0]+OFFSET(1,-(i/2)); 
  }
  MCenable <<= MP[0]+OFFSET(1,-(INPUT_WIDTH/2));
  sel1 <<= MP[0]+OFFSET(1,-(INPUT_WIDTH/2));

  for (i=0;i<INPUT_WIDTH+1;i++){
    MuxOut[i] <<= MP[0] + OFFSET(2,-(i/2));
    imux[i] <<= MuxOut[i];
    and[i] <<= MuxOut[i];
  }
  sel2  <<= MP[0] + OFFSET(2,-(INPUT_WIDTH+1)/2);   

}

void place(int x, int y){

  MP[0] <<= LOC(x,y);
  place();
}
};


// ModBoothMult8:  modified serial radix 2 booth multiplier   <BR>
//       THROUGHPUT: 1 mult / 2 cycles        <BR>
//             AREA: about 7 columns 5 rows (35 clbs)  <BR>
//
//  remark: Multiplier is loaded in two ways   <BR>
//          parallel(8bits) & serial(4 bits)   <BR>
     
class ModBoothMult8: public PMtop {
 public:
  WireVector<Bool,INPUT_WIDTH+1> MC, MCF, MCG, MCH,LUT1;
  WireVector<Bool,INPUT_WIDTH>MP,MPI,data_in,AddIn,AddOut1,AddIn2,AddOut2,LUT2;
  WireVector<Bus,3>              lut_addr_bus1, lut_addr_bus2;
  WireVector<Bool,4>             MPshiftIn,lut_addr1, lut_addr2;
  WireVector<Bool, INPUT_WIDTH+1>AddIn1;
  Bool AddReset, cin1, cin2, MPenable, MPshift;
  Bool MPstart,MCstart,NMCstart,toggle,we,del_we,we2,xor1,xor2;

  Add<INPUT_WIDTH> *ADD1;
  LAddCin<INPUT_WIDTH> *ADD2;

  ModBoothMult8(
	     WireVector<Bool, INPUT_WIDTH>& In,
             WireVector<Bool, 4>& MPshift_In,
	     Bool& MP_load, Bool& MP_shift,                           
	     Bool& MC_load,
             Bool& write_enable, Bool& del_write_enable,
	     Bool& load,
             WireVector<Bus, 3> &addr1, WireVector<Bus, 3> &addr2,
	     Bool *clock=NULL, const char *name=NULL): 
    PMtop(clock,name){

	NAME(MC); NAME(MCF); NAME(MCG);	NAME(MCH); NAME(AddIn);
	NAME(MP); NAME(MPI); NAME(MPshiftIn); NAME(data_in);
	NAME(MPstart); NAME(MCstart); NAME(NMCstart); NAME(toggle);
	NAME(we); NAME(del_we); NAME(we2); NAME(xor1); NAME(xor2);
        NAME(MPenable);	NAME(MPshift);
        NAME(lut_addr_bus1); NAME(lut_addr_bus2); NAME(lut_addr1);
	NAME(lut_addr2); NAME(LUT1); NAME(LUT2); NAME(AddIn);
  	NAME(AddIn1); NAME(AddIn2); NAME(AddOut1); NAME(AddOut2);
  	NAME(AddReset); NAME(cin1); NAME(cin2);

	int i;

	MPstart = MP_load;
        MCstart = MC_load;
        MPshift = MP_shift;
	we = write_enable;
        del_we = del_write_enable;

        for(i=0;i<3;i++){
	  lut_addr_bus1[i] = addr1[i]; 
	  lut_addr_bus2[i] = addr2[i]; 
	}
	for(i=0;i<4;i++){
	  MPshiftIn[i] = MPshift_In[i];
	}

        // Result of 1st add is loaded into Second Adder latch without feedback
        AddReset = load;

	// Parallel input for multiplicand and multiplier
	for(i=0;i<INPUT_WIDTH;i++){
	  data_in[i]=In[i];
	}
}

void out(WireVector<Bool, INPUT_WIDTH>& Out, WireVector<Bool, 4>& MPshiftOut) 
{
        int i;		
 
        // shifting out 4 MSBs
	for(i=0;i<4;i++){
	  MPshiftOut[i] = MP[4+i];
	}

        NMCstart = reg(MCstart,clk);
        we2  = NMCstart | MCstart;
        toggle = reg(we & ~toggle,clk);

	// Multiplicand or Multiplicand_bar
        MCF[0] = (~toggle & data_in[0])|(toggle  & ~MC[0]);
	MCG[0] = ~toggle;
        MCH[0] = mux(we2,MCF[0],MCG[0]);
        MC[0]  = reg(MCH[0],clk);
	MCF[0] <<= CLB_OUTPUT(F);
	MCG[0] <<= CLB_OUTPUT(G);
	MCH[0] <<= CLB_OUTPUT(H);
	MCG[0] <<= MCF[0];
	MCG[0] <<= MCH[0];

	for(i=1; i<INPUT_WIDTH; i++){
	  MCF[i] = (~toggle & data_in[i])|
		   ( toggle & ~MC[i]);
          MCG[i] = (~toggle & MC[i-1])|
		   (toggle & ~MC[i]);
	  MCH[i] = mux(we2,MCF[i],MCG[i]);
	  MC[i]  = reg(MCH[i],clk);
	  MCF[i] <<= CLB_OUTPUT(F);
	  MCG[i] <<= CLB_OUTPUT(G);
	  MCH[i] <<= CLB_OUTPUT(H);
	  MCG[i] <<= MCF[i];
	  MCG[i] <<= MCH[i];
	}

        MCF[INPUT_WIDTH] = toggle;
	MCG[INPUT_WIDTH] = (~toggle & MC[INPUT_WIDTH-1])|
			   (toggle & ~MC[INPUT_WIDTH]);
	MCH[INPUT_WIDTH] = mux(we2,MCF[INPUT_WIDTH],MCG[INPUT_WIDTH]);
	MC[INPUT_WIDTH]  = reg(MCH[INPUT_WIDTH],clk);
	MCF[INPUT_WIDTH] <<= CLB_OUTPUT(F);
	MCG[INPUT_WIDTH] <<= CLB_OUTPUT(G);
	MCH[INPUT_WIDTH] <<= CLB_OUTPUT(H);
	MCG[INPUT_WIDTH] <<= MCF[INPUT_WIDTH];
	MCG[INPUT_WIDTH] <<= MCH[INPUT_WIDTH];

	// Multiplier => shifted to the right by 4
        MPenable = MPstart | MPshift;
        for(i=0;i<INPUT_WIDTH;i++){
          if(i<4){
            MPI[i] = mux(MPstart,data_in[i],MPshiftIn[i]);
            MP[i]  = reg(mux(MPenable,MPI[i],MP[i]),clk);
            MP[i]  <<= CLB_INPUT(EC,MPenable); 
          }else if(i<INPUT_WIDTH){
            MPI[i] = mux(MPstart,data_in[i],MP[i-4]);
            MP[i]  = reg(mux(MPenable,MPI[i],MP[i]),clk);
            MP[i]  <<= CLB_INPUT(EC,MPenable); 
          }
        }

        // The booth encoding table is:
	// 001 : MC
	// 011 : 2MC
	// 100 : -2MC
	// 101 : -MC
       
// Table 1
        xor1 = MP[INPUT_WIDTH-2]^MP[INPUT_WIDTH-3];
 
        lut_addr_bus1[2] += tbuf(MP[INPUT_WIDTH-1],del_we);
        lut_addr_bus1[1] += tbuf(xor1 | ~xor1 & MP[INPUT_WIDTH-2],del_we);
        lut_addr_bus1[0] += tbuf(~xor1 & MP[INPUT_WIDTH-3] ,del_we);

        lut_addr1[3] = zero;
	lut_addr1[2] = lut_addr_bus1[2];
        lut_addr1[1] = lut_addr_bus1[1];
        lut_addr1[0] = lut_addr_bus1[0];

// Table 2
        xor2 = MP[INPUT_WIDTH-4]^MP[INPUT_WIDTH-5];
 
        lut_addr_bus2[2] += tbuf(MP[INPUT_WIDTH-3],del_we);
        lut_addr_bus2[1] += tbuf(xor2 | ~xor2 & MP[INPUT_WIDTH-4],del_we);
        lut_addr_bus2[0] += tbuf(~xor2 & MP[INPUT_WIDTH-5] ,del_we);

        lut_addr2[3] = zero;
	lut_addr2[2] = lut_addr_bus2[2];
        lut_addr2[1] = lut_addr_bus2[1];
        lut_addr2[0] = lut_addr_bus2[0];
   
        // Lookup table
	for(i=0; i< INPUT_WIDTH+1;i++){
	  LUT1[i] = reg(rams(lut_addr1,del_we,MC[i],~clk,0),clk);
	  LUT2[i] = reg(rams(lut_addr2,del_we,MC[i],~clk,0),clk);
	}
	
        cin1 = reg(MP[INPUT_WIDTH-3],clk);
        cin1 <<=  MC[0] + OFFSET(5,0); 
 
        W.ShiftLeft(LUT1,AddIn,2);
        ADD1=new Add<INPUT_WIDTH>(LUT2,AddIn,cin1,&clk,make_name("firstAdder"));
        ADD1->out(AddOut1);
        ADD1->place();	
	AddOut1[0]<<= MC[0] + OFFSET(5,-1);  

// weird addition
        cin2 = reg(MP[INPUT_WIDTH-1],clk);
        cin2 <<=  MC[0] + OFFSET(6,0);             

        AddIn2[0]= cin2;
	AddIn2[1]= cin2;	
        AddIn2[2]= zero;
	AddIn2[3]= zero;	
	for(i=4;i<INPUT_WIDTH;i++)
	  AddIn2[i]=AddOut2[i-4];

        ADD2=new LAddCin<INPUT_WIDTH>(AddIn2,AddOut1,cin2,AddReset,
				      &clk,make_name("2ndAdder"));
        ADD2->out(AddOut1);
        ADD2->place();	
	AddOut2[0]<<= MC[0] + OFFSET(6,-1);  

	for(i=0;i<INPUT_WIDTH;i++){
	  Out[i] = AddOut2[i];
	}

}

void place(){
  int i;

  for (i=0;i<INPUT_WIDTH;i++){
    MP[i] <<= MC[0]+OFFSET(2,-(i/2)); 
  }
  
  for (i=1;i<INPUT_WIDTH+1;i+=2){
    MC[i] <<= MC[0]+OFFSET(1,-(i/2));
  }
  for (i=2;i<INPUT_WIDTH;i+=2){
    MC[i] <<= MC[0]+OFFSET(0,-(i/2));
  }

  for (i=0;i<INPUT_WIDTH+1;i++){
    LUT1[i] <<= MC[0]+OFFSET(3,-(i/2));
    LUT2[i] <<= MC[0]+OFFSET(4,-(i/2));
  }
 
}	// end placement

void place(int x, int y){

  MC[0] <<= LOC(x,y);
  place();

}	// end placement
};  // end 



#endif


