/*---------------------*/
/*      cordic.h       */
/*---------------------*************************************/
/* PAM-Blox version 1.1:                                   */
/* object-oriented circuit generators for custom computing */
/*                     Oskar Mencer                        */ 
/*      Computer Architecture and Arithmetic Group         */
/*                  Stanford University                    */
/*                                                         */
/* last mod 5/1/1998 by mencer                             */
/***********************************************************/
#include "GNUlicense.h"

#ifndef CORDIC_H
#define CORDIC_H

#include "pamblox.h"

// Parallel-Parallel CORDIC <BR>
//   Parallel Arithmetic, Parallel execution <BR>
//   N= data width, S = number of iterations = latency <BR>

template<int N, int S>
class PPcordic:public PMtop{
 public:
  // for theory behind shift-sequences see <BR>
  // PhD Thesis, H.M.Ahmed, 1982, Stanford. <BR>
  int ShiftSequence[N];

  WireVector<WireVector<Bool, N>, (S+1)> X,Y,Z;

  WireVector<WireVector<Bool, N>, S> TVal, shiftedX, shiftedY, shiftedZ;
  WireVector<Bool, S> signZ, notSignZ;
  int tablevals[S];

  AddSub<N> *ASX[S+1];
  AddSub<N> *ASY[S+1];
  AddSub<N> *ASZ[S];

PPcordic(WireVector<Bool, N>& Xval,
	 WireVector<Bool, N>& Yval,
	 WireVector<Bool, N>& PhiVal,
	  Bool *clock=NULL,                      
	  const char *name=NULL,
	 int *sequence=NULL):
    PMtop(clock,name){

      int i;

      NAME(X); NAME(Y); NAME(Z);
      NAME(shiftedX);      NAME(shiftedY);      NAME(shiftedZ);
      NAME(signZ);  NAME(notSignZ);  NAME(TVal);

  for(i=0;i<N;i++){
    if (sequence != NULL){
      ShiftSequence[i]=sequence[i];
    }else{
      ShiftSequence[i]=i;
    }
  }
  for (i=0;i<N;i++){
    X[0][i]=Xval[i]; Y[0][i]=Yval[i]; Z[0][i]=PhiVal[i]; 
  }
}

void out(WireVector<Bool, N>& Xout,WireVector<Bool, N>& Yout)
{
  int i,j;
  for (i=0;i<N;i++){
    alias(Xout[i],X[S][i]); alias(Yout[i], Y[S][i]);
  }

// atan table
  DEBUG("tablevals : ");
  for (i=0; i<N;i++){
	tablevals[i]=(int)(pow(2,(N-2))*atan(pow(2.0,(double)-ShiftSequence[i])));
	DEBUG("%x ",tablevals[i]);
  }
  DEBUG("\n");

// shifted values
  for(i=0;i<S;i++){
    W.ShiftRight2sComp(X[i],shiftedX[i],ShiftSequence[i]);
    W.ShiftRight2sComp(Y[i],shiftedY[i],ShiftSequence[i]);
    alias(signZ[i],Z[i][N-1]);
    notSignZ[i]=~signZ[i];
  }

  for(i=0;i<S;i++){

     ASX[i]=new AddSub<N>(X[i],shiftedY[i],notSignZ[i],&clk,make_name("ASX"));
     ASX[i]->out(X[i+1]);
     ASX[i]->place();

     ASY[i]=new AddSub<N>(Y[i],shiftedX[i],signZ[i],&clk,make_name("ASY"));
     ASY[i]->out(Y[i+1]);
     ASY[i]->place();

     if (i<(S-1)){
       W.ConstantVector(TVal[i],tablevals[i]);

       ASZ[i]=new AddSub<N>(Z[i],TVal[i],notSignZ[i],&clk,make_name("ASZ"));
       ASZ[i]->out(Z[i+1]);
       ASZ[i]->place();
     }
  }
}

// relative placement
void place(){
  int i;
  for(i=0;i<=S;i++){
    Y[i][0]<<=Z[i][0]+OFFSET(0,-(N/2)-1);
    X[i][0]<<=Z[i][0]+OFFSET(0,-N-2);
    if (i<S){ 
      notSignZ[i]<<=signZ[i];
      if (i>0){
	Z[i][0]<<=Z[0][0]+OFFSET(i,0);
      }
    }
  }

}

// absolut placement
void place(int x,int y){
  place();
  Z[0][0]<<=LOC(x,y);
}

};

// Serial-Parallel CORDIC <BR>
//   Serial Arithmetic, Parallel execution <BR>
//   N= data width, S = number of iterations = latency <BR>

template<int N, int S>
class SPcordic:public PMtop{
 public:
  WireVector<WireVector<Bool, 1>, (S+1)> X,Y,Z,Xd,Yd,Zd;

  WireVector<WireVector<Bool, 1>, S> TVal, shiftedX, shiftedY, shiftedZ;
  WireVector<Bool, S> signZ, notSignZ, startD;

  WireVector<WireVector<Bool, 4>, 16> delay;  
  Bool start;

  int tablevals[S];

  SerialAddSub<1> *ASX[S+1];
  SerialAddSub<1> *ASY[S+1];
  SerialAddSub<1> *ASZ[S];

SPcordic(Bool& Xval,
	 Bool& Yval,
	 Bool& PhiVal,
	 Bool& Start,
	  Bool *clock=NULL,                      
	  const char *name=NULL):
    PMtop(clock,name){

      int i,j;

      NAME(X); NAME(Y); NAME(Z);  NAME(start); NAME(startD);
      NAME(shiftedX);      NAME(shiftedY);      NAME(shiftedZ);
      NAME(signZ);  NAME(notSignZ);  NAME(TVal);
      NAME(Xd); NAME(Yd); NAME(Zd); NAME(delay);

      X[0][0]=Xval; Y[0][0]=Yval; Z[0][0]=PhiVal; 

  start=Start;
}

void out(Bool& Xout, Bool& Yout)
{
  int i,j;
  alias(Xout,X[S][0]); alias(Yout, Y[S][0]);

// atan table
  DEBUG("tablevals : ");
  for (i=1; i<=N;i++){
	tablevals[i-1]=(int)(pow(2,(N-2))*atan(pow(2.0,1.0-i)));
	DEBUG("%x ",tablevals[i-1]);
  }
  DEBUG("\n");

  Yd[0][0]=reg(ramd(delay[N],delay[0],one,Y[0][0],clk,0)); 
  Xd[0][0]=reg(ramd(delay[N],delay[0],one,X[0][0],clk,0)); 
  alias(shiftedX[0][0],Xd[0][0]);
  alias(shiftedY[0][0],Yd[0][0]);
  
  for(i=0;i<S;i++){
    signZ[i]=reg(mux(start,reg(Z[i][0]),signZ[i]));
    notSignZ[i]=~signZ[i];
    
    if (i>0){
      Yd[i][0]=reg(ramd(delay[N],delay[0],one,Y[i][0],clk,0)); 
      Xd[i][0]=reg(ramd(delay[N],delay[0],one,X[i][0],clk,0));
      
      shiftedY[i][0]=reg(ramd(delay[i],delay[0],one,Yd[i][0],clk,0));
      shiftedX[i][0]=reg(ramd(delay[i],delay[0],one,Xd[i][0],clk,0));
    }
    
    ASX[i]=new SerialAddSub<1>(Xd[i],shiftedY[i],notSignZ[i],startD[i],&clk,make_name("ASX"));
    ASX[i]->out(X[i+1]);
    ASX[i]->place();
    
    ASY[i]=new SerialAddSub<1>(Yd[i],shiftedX[i],signZ[i],startD[i],&clk,make_name("ASY"));
    ASY[i]->out(Y[i+1]);
    ASY[i]->place();
    
    if (i<(S-1)){
      Zd[i][0]=reg(ramd(delay[N],delay[0],one,Z[i][0],clk,0));
      TVal[i][0]=reg(ramd(delay[i],delay[i],one,one,clk,tablevals[i]));
      
      ASZ[i]=new SerialAddSub<1>(Zd[i],TVal[i],notSignZ[i],startD[i],
				 &clk,make_name("ASZ"));
      ASZ[i]->out(Z[i+1]);
      ASZ[i]->place();
    }
  }

// counter controlling delay FIFOs

  RCounter<4> *DC; 
  DC=new RCounter<4>(start,&clk); 
  DC->out(delay[0]); 
  DC->place(); 

  startD[0]=start;
  for (i=1;i<9;i++){ 
    if (i<8) startD[i]=reg(startD[i-1],clk);
    for (j=0;j<4;j++) 
       delay[i][j]=reg(delay[i-1][j]); 
  }
}

// relative placement
void place(){
  int i,j;

//  delay[0][0]<<=X[0][0] + OFFSET(1,-4);
  startD[0] <<= X[0][0] + OFFSET(1,-11);

  for (i=1;i<9;i++){ 
    if (i<8) startD[i]<<=startD[i-1] + OFFSET(1,0);
    delay[i][0]<<=delay[i-1][0] + OFFSET(2,0);
    for (j=1;j<4;j++) 
       delay[i][j]<<=delay[i][j-1] + OFFSET((j-1)%2,0); 
  }

  Y[0][0]<<=X[0][0] + OFFSET(0,-2);
  Z[0][0]<<=Y[0][0] + OFFSET(1,-3);

  for (i=0;i<S;i++){
    shiftedX[i][0]<<=X[i][0] + OFFSET(1,-1);
    shiftedY[i][0]<<=Y[i][0] + OFFSET(1,-1);
    shiftedZ[i][0]<<=Z[i][0] + OFFSET(1,-1);

    if ((i>0)&&(i<(S-1))){
      Xd[i][0]<<=X[i][0] + OFFSET(1,0);
      Yd[i][0]<<=Y[i][0] + OFFSET(1,0);
      Zd[i][0]<<=Z[i][0] + OFFSET(1,0);
    }
    TVal[i][0]<<=Z[i][0] + OFFSET(1,-1);

    if (i>0){
      X[i][0]<<=X[i-1][0] + OFFSET(2,0);
      Y[i][0]<<=Y[i-1][0] + OFFSET(2,0);
      Z[i][0]<<=Z[i-1][0] + OFFSET(2,0);

      if (i%2){ 
	// signZ[i]<<=signZ[i-1];
	// notSignZ[i]<<=notSignZ[i-1];
      }
    }

  }

}

// absolut placement
void place(int x,int y){
  X[0][0]<<=LOC(x,y);
  place();
}

};



#endif


