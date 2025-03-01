/*---------------------------------------------------------*/
/*  kcm16.h: 16 bit Constant(K) Coefficient Multipliers    */
/*---------------------------------------------------------*/
/* PAM-Blox version 1.1:                                   */
/* object-oriented circuit generators for custom computing */
/*                     Oskar Mencer                        */ 
/*      Computer Architecture and Arithmetic Group         */
/*                  Stanford University                    */
/*                                                         */
/* last mod 4/10/1998 by mencer                            */
/***********************************************************/
#include "GNUlicense.h"

#ifndef KCM16_H
#define KCM16_H

#include "pamblox.h"

// <B>Constant(K) Coefficient Multiplier</B> (nibble serial) <BR>
//       technique: Distributed Arithmetic         <BR>
//       16 bit x 16 bit -> 32 bit (16 bit serial + last 16 bit parallel) <BR> 
// AREA: width=3 height=12(4.5) => 12+12+4.5 = 28.5 CLBs 

class NibbleKCM16:public PMtop{
 public:

#define NM_INPUT_WIDTH   (4)
#define NM_MULT_WIDTH   (16)
#define NM_ADD_WIDTH    (20)

  WireVector<Bool, NM_ADD_WIDTH>RSum;
  WireVector<Bool, NM_ADD_WIDTH>PSum;
  WireVector<Bool, NM_ADD_WIDTH>result;
  Bool cout2,cout3,cin3;

  WireVector<Bool, NM_INPUT_WIDTH> NIn;
  Bool Nstart;   
  int factor;

NibbleKCM16(
	     WireVector<Bool, NM_INPUT_WIDTH>& In,  // Input nibble <BR>       
	     Bool& start,                           // 1 if first nibble of<BR>
	                                            // word, 0 otherwise <BR>
	     const int& mult,                       // constant factor <BR>   
	     Bool *clock=NULL,                      
	     const char *name=NULL):
    PMtop(clock,name){

      NAME(RSum); NAME(PSum);
      NAME(cout2); NAME(cout3);
      NAME(cin3); NAME(result);
      NAME(NIn); NAME(Nstart);

      int i;

      if (mult>65535) {
	printf("ERROR: Constant Multiplier value to large !\n");
	exit(-1);
      }
      factor=mult;

      Nstart=reg(start,clk);
      for(i=0;i<NM_INPUT_WIDTH;i++){
	NIn[i]=In[i];
      }
      
}

void out(WireVector<Bool, NM_INPUT_WIDTH>&Out,       // Output nibble  <BR>
	 WireVector<Bool, NM_MULT_WIDTH> *SOut=NULL) // res bits [16..32] <BR>
{

      int n,i;
      unsigned short romval[NM_ADD_WIDTH];

      // values for 20 LUTs
      for(n=0;n<NM_ADD_WIDTH;n++){
	// 16 bits per LUT
	romval[n]=0;
	for (i=0;i<NM_MULT_WIDTH;i++){
	  if ((((factor*i)>>n)&1)==1)
	    romval[n]=romval[n] | (((unsigned short)1)<<i);	 
	}
      }

      //create LUTs
      for(i=0;i<NM_ADD_WIDTH;i++){
	  PSum[i]=reg(rom(NIn,romval[i]),clk);
      //  DEBUG("romval[%d]=%x\n",i,romval[i]);
      }
      
      //3rd stage: shift and add

      char *addname=NULL;
      if (myName!=NULL) 
	addname = strcat(myName,"/add0");
      Add<NM_ADD_WIDTH> *ADD3;
      ADD3=new Add<NM_ADD_WIDTH>(PSum,RSum,zero,&clk,addname);
      ADD3->out(result,&cout3);
      ADD3->place();
	
      // outputs
      for(i=0;i<NM_INPUT_WIDTH;i++){
	alias(Out[i],result[i]);
      }

      if (SOut!=NULL){
	output(*SOut);
	for(i=0;i<NM_MULT_WIDTH;i++){
	  alias((*SOut)[i],result[i+NM_INPUT_WIDTH]);
	}
      }

      // feedback
      for(i=0;i<NM_ADD_WIDTH;i++){
	if (i<16){
	  RSum[i]=mux(Nstart,ZERO,result[NM_INPUT_WIDTH+i]);
	}else if (i==17){
	  RSum[i]=mux(Nstart,ZERO,cout3);
	}else{
	  RSum[i]=ZERO;
	}
      }

}


void place(){
  int i;
  result[0]<<=PSum[0]+OFFSET(1,0);


  RSum[0]<<=PSum[0]+OFFSET(1,1);
  RSum[1]<<=PSum[0]+OFFSET(1,1);
  RSum[2]<<=PSum[0]+OFFSET(2,1);
  RSum[3]<<=PSum[0]+OFFSET(2,1);
  RSum[13]<<=PSum[0]+OFFSET(2,-10);
  RSum[14]<<=PSum[0]+OFFSET(2,-10);
  RSum[15]<<=PSum[0]+OFFSET(0,-10);
  RSum[16]<<=PSum[0]+OFFSET(0,-10);
  RSum[17]<<=PSum[0]+OFFSET(1,-10);
  
  for(i=0;i<9;i++){
    RSum[i+4]<<=PSum[0]+OFFSET(2,-(i/2));
  }

  for(i=1;i<NM_ADD_WIDTH;i++){
    PSum[i]<<=PSum[0]+OFFSET(0,-(i/2));
  }

}


void place(int x,int y){
  PSum[0]<<=LOC(x,y);
  place();
}

};


//<B> Constant(K) Coefficient Multiplier</B> (nibble serial)<BR>
//       technique: adder tree<BR>
//       16 bit x 16 bit -> 32 bit<BR> 
// AREA: width=3 height=16 => 48 CLBs<BR>

class NibbleKCM16b:public PMtop{
 public:

#define NM_INPUT_WIDTH   (4)
#define NM_MULT_WIDTH   (16)
#define NM_ADD_WIDTH    (20)

  WireVector<Bool, NM_ADD_WIDTH>A;
  WireVector<Bool, NM_ADD_WIDTH>B;
  WireVector<Bool, NM_ADD_WIDTH>PSum;
  WireVector<Bool, NM_ADD_WIDTH>RSum;
  WireVector<Bool, NM_ADD_WIDTH>result;
  Bool cout2,cout3,cin3;

  WireVector<Bool, NM_INPUT_WIDTH> NIn;
  Bool Nstart;   
  int factor;
	      
NibbleKCM16b(WireVector<Bool, NM_INPUT_WIDTH>& In,// Input nibble        <BR>
	   Bool& start,                           // 1 if first nibble of<BR>
	                                          // word, 0 otherwise   <BR>
	   const int& mult,                       // constant factor     <BR>
	   Bool *clock=NULL,                      
	   const char *name=NULL):
    PMtop(clock,name){

      NAME(A); NAME(B);
      NAME(PSum); NAME(RSum);
      NAME(result); NAME(cout2); NAME(cout3);
      NAME(cin3);
      NAME(NIn); NAME(Nstart);

      int i;

      if (mult>65535) {
	printf("ERROR: Constant Multiplier value to large (>2^16)!\n");
	exit(-1);
      }
      factor=mult;

      Nstart=reg(reg(start,clk),clk);
      for(i=0;i<NM_INPUT_WIDTH;i++){
	NIn[i]=In[i];
      }
}

void out(WireVector<Bool, NM_INPUT_WIDTH>&Out,  // Output nibble          
	 WireVector<Bool, NM_MULT_WIDTH> *SOut=NULL) // res bits [16..32] 
{
      int n,i,j,rval;
      char nmult[4];
      unsigned short romval[4][8];

      // calculate values of LUTs
      for(i=0;i<(NM_MULT_WIDTH/NM_INPUT_WIDTH);i++){
	nmult[i]=(factor&(0xf<<(4*i)))>>(4*i);
      }
      // nibbles
      for(n=0;n<(NM_MULT_WIDTH/NM_INPUT_WIDTH);n++){
	// 16 bits per LUT
	for (i=0;i<NM_MULT_WIDTH;i++){
	  rval=i*nmult[n];
	  // 8 result bits per nibble
	  for(j=0;j<(2*NM_INPUT_WIDTH);j++){
	    if (rval&(1<<j)){
	      romval[n][j]=romval[n][j] | (1<<i);
	    }else{
	      romval[n][j]=romval[n][j] & (~(short)(1<<i));
	    }
	  }
	}
      }

      //create LUTs
      for(i=0;i<NM_MULT_WIDTH;i++){
	if (i<(NM_MULT_WIDTH/2)){
	  A[i]=reg(rom(NIn,romval[0][i]),clk);
	  B[i+4]=reg(rom(NIn,romval[1][i]),clk);
	}else{
	  A[i]=reg(rom(NIn,romval[2][i%8]),clk);
	  B[i+4]=reg(rom(NIn,romval[3][i%8]),clk);
	}
      }
      
      for (i=0;i<4;i++){
	A[16+i]=ZERO;
	B[i]=ZERO;
      }

      //2nd stage: adder

      Add<NM_ADD_WIDTH> *ADD2;
      ADD2=new Add<NM_ADD_WIDTH>(A,B,zero,&clk);
      ADD2->out(PSum,&cout2);
      ADD2->place();
      
      //3rd stage: shift and add

      Add<NM_ADD_WIDTH> *ADD3;
      ADD3=new Add<NM_ADD_WIDTH>(PSum,RSum,cout2,&clk);
      ADD3->out(result,&cout3);
      ADD3->place();
	
      // outputs
      for(i=0;i<NM_INPUT_WIDTH;i++){
	alias(Out[i],result[i]);
      }

      if (SOut!=NULL){
	for(i=0;i<NM_MULT_WIDTH;i++){
	  alias((*SOut)[i],result[i+NM_INPUT_WIDTH]);
	}
      }

      // feedback
      for(i=0;i<NM_ADD_WIDTH;i++){
	if (i<16){
	  RSum[i]=mux(Nstart,ZERO,result[NM_INPUT_WIDTH+i]);
	}else if (i==17){
	  RSum[i]=mux(Nstart,ZERO,cout3);
	}else{
	  RSum[i]=ZERO;
	}
      }
      DEBUG("NMULT finished \n");

} // end nibble mult out


void place(){
  int i;
  PSum[0]<<=A[0]+OFFSET(1,-5); 
  result[0]<<=A[0]+OFFSET(2,-5);

  for(i=1;i<8;i++)
    A[i]<<=A[0]+OFFSET(0,-(i/2));

  for(i=4;i<12;i++)
    B[i]<<=A[0]+OFFSET(0,-4-((i-4)/2));

  for(i=8;i<16;i++)
    A[i]<<=A[0]+OFFSET(0,-8-((i-8)/2));

  for(i=12;i<20;i++)
    B[i]<<=A[0]+OFFSET(0,-12-((i-12)/2));

  for(i=0;i<8;i++){
    RSum[i]<<=A[0]+OFFSET(1,-(i/2));
    RSum[i+8]<<=A[0]+OFFSET(2,-(i/2));
  }
  RSum[17]<<=A[0]+OFFSET(2,-15);
}

void place(int x,int y){
  A[0]<<=LOC(x,y);
  place();
}

};

// <B>Modulo 2^16+1 </B>(nibble serial) <BR>
//     e.g. for IDEA encryption <BR>
 
class Mod2P16P1:public PMtop{
 public:

#define MM_DATA_WIDTH (16)
#define MM_INPUT_WIDTH (4)

  WireVector<WireVector<Bool, MM_INPUT_WIDTH>, 4> lsbPipe;
  WireVector<Bool, MM_DATA_WIDTH> diff;
  WireVector<Bool, MM_DATA_WIDTH> msb;
  WireVector<Bool, MM_DATA_WIDTH> lsb;
  WireVector<Bool, MM_INPUT_WIDTH> incOut;
  WireVector<Bool, MM_INPUT_WIDTH> diff4;
  Bool carryIn,sign,dummy2,NMstart,SIstart,P2start;

Mod2P16P1(   WireVector<Bool, MM_INPUT_WIDTH>& Lsb,  // lsb Input   <BR>
	     WireVector<Bool, MM_DATA_WIDTH>& Msb,  // msb Input        <BR>  
	     Bool& start,                           // 1 if first nibble of<BR>
	                                            // word, 0 otherwise <BR>  
	     Bool *clock=NULL,                      
	     const char *name=NULL):
    PMtop(clock,name){

NAME(lsbPipe); NAME(diff); NAME(diff4); NAME(carryIn);
NAME(msb); NAME(lsb); NAME(incOut); NAME(sign); NAME(dummy2); 
NAME(NMstart); NAME(SIstart); NAME(P2start);
    int i;


   for(i=0;i<MM_DATA_WIDTH;i++)
     msb[i]=Msb[i];

   for(i=0;i<MM_INPUT_WIDTH;i++)
     lsbPipe[0][i]=Lsb[i];     

// control of start of word
    P2start=start;
    SIstart=reg(P2start,clk);

    char names[3][MAX_NAME_LEN];
    for (i=0;i<3;i++)
      strcpy(names[i],myName);

    if (myName!=NULL) {
      strcat(names[0],"/sub");
      strcat(names[1],"/p2s");
      strcat(names[2],"/inc");
    }

// sub lsb - msb 
    Sub<MM_DATA_WIDTH> *SUBT;
    SUBT=new Sub<MM_DATA_WIDTH>(lsb,msb,&clk,names[0]);
    SUBT->out(diff,&sign);
    SUBT->place();

// 16 parallel to 4 bit serial
    ParToSer<MM_DATA_WIDTH, MM_INPUT_WIDTH> *P2S;
    P2S=new ParToSer<MM_DATA_WIDTH, MM_INPUT_WIDTH>
      (P2start,diff,&clk,names[1]);
    P2S->out(diff4);
    P2S->place();

// increment
    SerialIncrement<MM_INPUT_WIDTH> *INC;
    INC=new SerialIncrement<MM_INPUT_WIDTH>
      (diff4,SIstart,carryIn,&clk,names[2]);
    INC->out(incOut);
    INC->place();
}

void out(WireVector<Bool, MM_INPUT_WIDTH>& Out){ 
  int i,j;

  for(i=0;i<MM_INPUT_WIDTH;i++){
    alias(Out[i],incOut[i]);
  }

  for(i=1;i<MM_INPUT_WIDTH;i++)
    for(j=0;j<MM_INPUT_WIDTH;j++)
      lsbPipe[i][j]=reg(lsbPipe[i-1][j],clk);

  for(i=0;i<MM_DATA_WIDTH;i++)
    alias(lsb[i],lsbPipe[MM_INPUT_WIDTH-(i/MM_INPUT_WIDTH)-1][i%MM_INPUT_WIDTH]);


  
  carryIn=reg(mux(P2start,~sign,carryIn),clk);   
}

void place(){
  int i,j;
  for(i=1;i<MM_INPUT_WIDTH;i++)
    for(j=0;j<MM_INPUT_WIDTH;j++){
      if ((j%2)==0) lsbPipe[i][j]<<=lsbPipe[i][j+1];
      else lsbPipe[i][j]<<=P2start+OFFSET(0,-1-(i-1)*2-(j/2));
    }

  SIstart<<=P2start;

// place sub
  diff[0]<<=P2start+OFFSET(1,0);
// place P2S
  diff4[0]<<=P2start+OFFSET(2,0);
// place serial inc
  incOut[0]<<=P2start+OFFSET(3,0);

}

void place(int x,int y){
  P2start<<=LOC(x,y);
  place();
}

};


//<B> Constant(K) Coefficient Multiplier</B> : bit-serial <BR>
// AREA: about 2 x N/2 = 16 CLBs

class SerKCM16:public PMtop{
 public:
#define SM_WIDTH 16

  WireVector<Bool, SM_WIDTH> PSum;   // shifted partial Sum
  WireVector<Bool, SM_WIDTH> constB; 
  WireVector<Bool, SM_WIDTH> result; // intermediate result

  Bool SMin;
  Bool SMstart;   
  Bool cout;
  int factor;
	      
SerKCM16(Bool& In,                    // Input nibble      <BR>
	   Bool& start,                 // 1 if first bit   <BR>
	                                // word, 0 otherwise <BR>
	   const int& mult,             // constant factor    <BR>
	   Bool *clock=NULL,                      
	   const char *name=NULL):
    PMtop(clock,name){

      NAME(PSum);
      NAME(constB);
      NAME(result); NAME(cout);
      NAME(SMin); NAME(SMstart);

      if (mult>pow(2,SM_WIDTH)) {
	printf("ERROR: Constant Multiplier value to large !\n");
	exit(-1);
      }
      factor=mult;

      SMstart=start;
      SMin=In;
      
}

void out(Bool &Out,       // Output bit         <BR>
	 WireVector<Bool, SM_WIDTH> *SOut=NULL) // res bits [16..32] <BR>
{
      int i;

      // loadable constant adder

      char *addname=NULL;
      if (myName!=NULL)
	addname = strcat(myName,"/add0");

      LAdd<SM_WIDTH> *LCADD;
      LCADD=new LAdd<SM_WIDTH>(PSum,constB,SMstart,&clk,addname);
      LCADD->out(result,&cout);
      LCADD->place();

      // feedback
      for(i=0;i<SM_WIDTH;i++){
	if ((factor&((int)1<<i))==1){
	  constB[i]=one;
	}else{
	  constB[i]=zero;
	}

	if (i<(SM_WIDTH-1)){
	  PSum[i]=mux(SMstart,ZERO,result[i+1]);
	}else if (i==(SM_WIDTH-1)){
	  PSum[i]=mux(SMstart,ZERO,cout);
        }
      }
      // output
      alias(Out,result[0]);

      if (SOut!=NULL){
	for(i=1;i<SM_WIDTH;i++){
	  alias((*SOut)[i-1],result[i]);
	}
	alias((*SOut)[SM_WIDTH-1],cout);
      }

} // end nibble mult out


void place(){
  int i;
  result[0]<<=PSum[0]+OFFSET(1,0);

  for(i=1;i<SM_WIDTH;i++){
    PSum[i]<<=PSum[0]+OFFSET(0,-(i/2));
  }

}

void place(int x,int y){
  PSum[0]<<=LOC(x,y);
  place();
}

};

// Constant(K) Coefficient Multiplier (16 bit fully parallel) <BR>
// AREA: 4x20 ROMS, Adder Tree: 12+12+16 => 80 CLBs <BR>

class ParKCM16:public PMtop{
 public:
#define PM_NIBBLE 4
#define PM_WIDTH 16

// vars
   WireVector<WireVector<Bool, PM_NIBBLE>, (PM_WIDTH/PM_NIBBLE)> input;
   WireVector<WireVector<Bool,(2*PM_NIBBLE+PM_WIDTH)>,
                                  (PM_WIDTH/PM_NIBBLE)>Atree;

   WireVector<WireVector<Bool, (PM_WIDTH+2*PM_NIBBLE)>, 2>PSum;
   WireVector<WireVector<Bool, (2*PM_WIDTH)>, 2> PSumB;
   WireVector<Bool, (2*PM_WIDTH)> output;
   WireVector<Bool,3> cout;

   int factor;

ParKCM16(WireVector<Bool, PM_WIDTH>& Input,  // nibble input <BR>
	 const int& mult,             // constant factor   <BR>
	 Bool *clock=NULL,                      
	 const char *name=NULL):
     PMtop(clock,name){
// NAMEs
  NAME(input); NAME(Atree);
  NAME(PSum); NAME(PSumB);
  NAME(output); NAME(cout);

// assign inputs to internal vars (=)

  factor=mult;

  for(int j=0;j<(PM_WIDTH/PM_NIBBLE);j++)
    for (int i=0;i<PM_NIBBLE;i++)
      input[j][i]=Input[j*4+i];

}

void out(WireVector<Bool, 32>& Output){
int i,j;
unsigned short romval[PM_WIDTH/PM_NIBBLE][PM_WIDTH+PM_WIDTH];
unsigned short rval;

// assign outputs to internal vars
  for (i=0;i<(2*PM_WIDTH);i++)
    alias(output[i],Output[i]);

// calculate rom values

  for (i=0;i<PM_WIDTH;i++){
    rval=i*factor;
    // 8 result bits per nibble
      for(j=0;j<(PM_WIDTH+PM_NIBBLE);j++){
	if (rval&(1<<j)){
	  romval[0][j]=romval[0][j] | (1<<i);
	  romval[1][j]=romval[1][j] | (1<<i);
	  romval[2][j]=romval[2][j] | (1<<i);
	  romval[3][j]=romval[3][j] | (1<<i);
	}else{
	  romval[0][j]=romval[0][j] & (~(short)(1<<i));
	  romval[1][j]=romval[1][j] & (~(short)(1<<i));
	  romval[2][j]=romval[2][j] & (~(short)(1<<i));
	  romval[3][j]=romval[3][j] & (~(short)(1<<i));
	}
      }
  }
  
// roms
  for (j=0;j<(PM_WIDTH/PM_NIBBLE);j++)
    for (i=0;i<(PM_NIBBLE+PM_WIDTH);i++){
      Atree[j][i+(j%2)*4]=reg(rom(input[j],romval[j][i]),clk); 
    }

// ADDER TREE (of multiplier)

  for (j=0;j<4;j++)
    for(i=0;i<4;i++)
      Atree[j][i+((j+1)%2)*(PM_NIBBLE+PM_WIDTH)]=zero;

  char addname[3][MAX_NAME_LEN];
  for (i=0;i<3;i++)
    strcpy(addname[i],myName);

  if (myName!=NULL) {
    strcat(addname[0],"/add0");
    strcat(addname[1],"/add1");
    strcat(addname[2],"/add2");
  }

  Add<2*PM_NIBBLE+PM_WIDTH> *ADD2;
  for (i=0;i<2;i++){
    ADD2=new Add<2*PM_NIBBLE+PM_WIDTH>(Atree[0+i*2],Atree[1+i*2],zero,
				       &clk,(myName?addname[i]:NULL));
    ADD2->out(PSum[i],&cout[i]);
    ADD2->place();
  }

  for(i=0;i<(2*PM_WIDTH);i++)
    if (i<(PM_WIDTH+2*PM_NIBBLE))
      PSumB[0][i]=PSum[0][i];
    else
      PSumB[0][i]=zero;

  for(i=0;i<(2*PM_WIDTH);i++)
    if (i<(2*PM_NIBBLE))
      PSumB[1][i]=zero;
    else
      PSumB[1][i]=PSum[1][i-2*PM_NIBBLE];

  Add<2*PM_WIDTH> *ADD3;
  ADD3=new Add<2*PM_WIDTH>(PSumB[0],PSumB[1],zero,
			   &clk,(myName?addname[2]:NULL));
  ADD3->out(output,&cout[2]);
  ADD3->place();

}

void place(){
  int i;

  for(i=0;i<(PM_NIBBLE+PM_WIDTH);i++){
    Atree[0][i]<<=input[0][0]+OFFSET(0,-(i/2));
    Atree[1][i]<<=input[0][0]+OFFSET(0,-((PM_NIBBLE+PM_WIDTH)/2)-(i/2));
    Atree[2][i]<<=input[0][0]+OFFSET(1,-(i/2));
    Atree[3][i]<<=input[0][0]+OFFSET(1,-((PM_NIBBLE+PM_WIDTH)/2)-(i/2));
  }
  PSum[0][0]<<=input[0][0] + OFFSET(2,-1);
  PSum[1][0]<<=input[0][0] + OFFSET(3,-1);

  output[0]<<=input[0][0] + OFFSET(4,-1);
}

void place(int x,int y){
  input[0][0]<<=LOC(x,y);
  place();
}
};


#endif
