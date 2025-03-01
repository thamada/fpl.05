/*------------------------------------------------------------*/ 
/*  pamblox.h: simple hardware objects w/ up to 1 carry-chain */ 
/*------------------------------------------------------------*/
/* PAM-Blox version 1.1:                                      */
/* object-oriented circuit generators for custom computing    */
/*                     Oskar Mencer                           */ 
/*      Computer Architecture and Arithmetic Group            */
/*                  Stanford University                       */
/*                                                            */ 
/* PAM-Blox are distributed under the GNU Public license      */ 
/*      check GNUlicense.h for the license notice             */ 
/*      check GNUlicense.txt for all the details              */ 
/*                                                            */
/*  Questions ? email: pamblox@umunhum.stanford.edu           */ 
/*                                                            */
/* last mod 4/10/1998 by mencer                               */ 
/**************************************************************/
/*  Area: most PamBlox take N/2 + 1 CLBs                      */
/*                                                            */
/*  Latency: 1 clock cycle, cycle time depending on N         */
/**************************************************************/

#ifndef PAMBLOX_H 
#define PAMBLOX_H 
 
#include "pamtypes.h" 
 
int printlicense=0; 
 
// PamBlox (templates) Top Object  
 
template<int N>  
class PBtop:public Node{ 
 public: 
  Bool clk; 
  Bool zero,one; 
  WireVector<Bool, N> outp; 
 
PBtop(Bool *clock=NULL, const char *name=NULL): 
  Node((name!=NULL)?(name):(name=make_name("PamBlox"))){ 
  internal(clk); 
  internal(outp); 
  internal(zero); 
  internal(one); 
 
  if (printlicense==0){ 
    printlicense=1; 
     
    printf("\nPAM-Blox version 1.1, copyleft (c) 1998 by Oskar Mencer\n"); 
    printf("PAM-Blox is free and comes with ABSOLUTELY NO WARRANTY\n");  
    printf("Check out the GNU Public License for details.\n"); 
    printf("=======================================================\n\n\n\n"); 
    DEBUG("Instantiating ....\n\n"); 
  } 
 
  if (clock!=NULL){ 
    alias(clk,*clock); 
  }else{ 
    alias(clk,TheClock_0); 
  } 
 
  zero=reg(~one); 
  one=~reg(~ONE); 
 
  DEBUG(" %s\n",name); 
} 
 
virtual void out( WireVector<Bool, N>& output){ 
  for(int i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
    outp[i]=reg(~ONE,clk); 
  } 
}  
 
// place 'output' into a rectangle

virtual void place(const Rect& place,  
		   WireVector<Bool, N>& output){ 
 
   int i, width, height, x, y; 
    
   width = place.width; 
   height = place.height; 
 
   assert((2 * width * height) >= N); 
    
   for(i = 0; i < N; i++) { 
     x = (i/2) / height; 
     y = ((i/2) % height); 
     output[i] <<= LOC(place.corner.x + x,   
                       place.corner.y - y); 
   } 
} 
	 
// place 'output' vertically

virtual void place(WireVector<Bool, N>&output){ 
   int i; 
   for(i = 1; i < N; i++) {      
     //output[i]<<=output[i]; 
     if (i%2){ 
       output[i] <<= output[i-1]; 
     }else{ 
       output[i]<<=output[i-1]+OFFSET(0,-1);        
     }	 
   } 
} 
 
// place carry chain into rectangle (version 1)

virtual void placecarry1(const Rect& place, 
			 WireVector<Bool, N>& carry,  
			 WireVector<Bool, N>& output){ 
   int i, width, height, x, y; 
    
   width = place.width; 
   height = place.height; 
 
   assert((2 * width * height) >= N); 
       
   for(i = 0; i < N; i++) { 
     x = (i/2) / height; 
     y = ((i/2) % height); 
      
     output[i] <<= LOC(place.corner.x + x,   
                       place.corner.y - y); 
     carry[i] <<= output[i]; 
     if (i%2){ 
       carry[i]<<=CLB_OUTPUT(COUT);  
     }else{ 
       carry[i]<<=CLB_OUTPUT(COUT0); 
       output[i] <<= output[i+1]; 
     }	 
   } 
} 
	 
// place carry chain upwards (version 1)

virtual void placecarry1(WireVector<Bool, N>& carry,  
			 WireVector<Bool, N>& output){ 
   int i,dx,dy; 
 
   for(i = 0; i < N; i++) { 
      carry[i] <<= output[i]; 
      dx=0; dy=-1; 
      if (i%2){ 
         carry[i]<<=CLB_OUTPUT(COUT);  
	 if (i<(N-1)) output[i+1]<<=output[i]+OFFSET(dx,dy); 
      }else{ 
         carry[i]<<=CLB_OUTPUT(COUT0); 
         output[i] <<= output[i+1]; 
      }	 
 
   } 
} 
 
// place carry-chain upwards into rectangle (version 2) 

virtual void placecarry2(const Rect& box, 
			 Bool& Cin, 
			 Bool& dummy, 
			 Bool& Cout, 
			 WireVector<Bool, N>& carry,  
			 WireVector<Bool, N>& output){ 
 
  int width,height,x,y,i;  
  width = box.width; 
  height = box.height; 
   
  assert((2 * width * height) >= N); 
   
  Cin<<=LOC(box.corner.x,box.corner.y+1);  
  dummy<<=Cin; 
  dummy<<=CLB_OUTPUT(COUT); 
 
  for (i=0; i<N; i++) { 
    x = (i/2) / height; 
    y = (i/2) % height; 
     
    output[i] <<= LOC(box.corner.x + x,   
		      box.corner.y - y);  
     
    carry[i] <<= output[i]; 
    if (i%2){ 
      carry[i] <<= CLB_OUTPUT(COUT); 
    }else{ 
      carry[i] <<= CLB_OUTPUT(COUT0); 
    } 
  } 
   
   Cout <<= carry[N-1]+OFFSET(0,-1); 
 
} 
        
// place vertically carry-chain upwards (version 2)

virtual void placecarry2(Bool& Cin, 
			 Bool& dummy, 
			 Bool& Cout, 
			 WireVector<Bool, N>& carry,  
			 WireVector<Bool, N>& output){ 
 
  int i;  
   
  Cin<<=output[0]+OFFSET(0,1);  
  dummy<<=Cin; 
  dummy<<=CLB_OUTPUT(COUT); 
 
  for (i=0; i<N; i++) { 
    carry[i] <<= output[i];     
    if (i%2){ 
      carry[i] <<= CLB_OUTPUT(COUT); 
      carry[i] <<= carry[i-1]; 
    }else{ 
      carry[i] <<= CLB_OUTPUT(COUT0); 
      if (i>0) carry[i]<<=carry[i-1]+OFFSET(0,-1); 
    } 
  } 
   
  Cout <<= carry[N-1]+OFFSET(0,-1);   
 
} 
        
}; 

// PaModules (objects) top object

class PMtop:public Node{
 public:
  Bool clk;
  Bool zero,one;
  char myName[MAX_NAME_LEN];

PMtop(Bool *clock=NULL, const char *name=NULL):
  Node((name!=NULL)?(name):(name=make_name("PaModule"))){
  internal(clk);
  internal(zero);
  internal(one);

  zero=reg(~ONE,clk);
  one=reg(~ZERO,clk);

  if (clock!=NULL){
    alias(clk,*clock);
    input(*clock);
  }else{
    alias(clk,TheClock_0);
  }

  // hierarchical naming
  if (name!=NULL)
    strcpy(myName,name);
  else
    myName[0]='\0';

  DEBUG("%s\n",myName);
}
}; 
 
// A constant Register 
 
template<int N> 
class ConstReg: public PBtop<N>{ 
 public: 
  int val;
 
ConstReg(const int& Value, 
	 Bool *clock=NULL,
	 const char *name=NULL):PBtop<N>(clock,name){
  val=Value;
} 
 
void out(WireVector<Bool, N>& output){   
  for(int i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
    outp[i]=nextval(val,i); 
  } 
}  
 
virtual EquationHandler nextval(const int val, int i){ 
  return reg(~((val&(1<<i))?ZERO:ONE),clk); 
} 
 
virtual void place(const Rect& place){ 
  PBtop<N>::place(place,outp); 
} 
 
virtual void place(){ 
  PBtop<N>::place(outp); 
} 
 
}; 
 
// Loadable Register

template<int N> 
class Register: public PBtop<N>{ 
 public: 
  WireVector<Bool, N> invector; 
  Bool loadreg; 
     
Register(Bool& load,WireVector<Bool, N>& in,Bool *clock=NULL,const char *name=NULL):PBtop<N>(clock,name){ 
  internal(invector); 
  internal(loadreg); 
 
  for(int i=0;i<N;i++){ 
    invector[i]=in[i]; 
  } 
  loadreg=load; 
 
} 
 
void out(WireVector<Bool, N>& output){   
  for(int i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
    outp[i]=nextval(i); 
  } 
}  
 
virtual EquationHandler nextval(int i){ 
  return reg(mux(loadreg,invector[i],outp[i]),clk); 
} 
 
virtual void place(const Rect& place){ 
  PBtop<N>::place(place,outp); 
} 
 
virtual void place(){ 
  PBtop<N>::place(outp); 
} 
 
};  
 
// Mux Register (firstSel ? in1 : in2)

template<int N> 
class MuxReg: public Register<N>{ 
 public: 
  WireVector<Bool, N> invector2; 
     
MuxReg(Bool& firstSel, 
       WireVector<Bool, N>& in1, 
       WireVector<Bool, N>& in2, 
       Bool *clock=NULL,const char *name=NULL): 
	 Register<N>(firstSel,in1,clock,name){ 
 
   internal(invector2); 
   for(int i=0;i<N;i++) 
     invector2[i]=in2[i]; 
 
} 
 
virtual EquationHandler nextval(int i){ 
  return reg(mux(loadreg,invector[i],invector2[i]),clk); 
} 
 
}; 

// simple Counter (with carry version 1)
 
template<int N> 
class Counter: public PBtop<N>{ 
 public: 
  WireVector<Bool, N> carry; 
   
  Counter(Bool *clock=NULL,const char *name=NULL): 
    PBtop<N>(clock,name) 
      { 
	internal(carry); 
      } 
   
virtual EquationHandler counting(int i){ 
  if (i==0) 
    return (reg(~outp[0],clk)); 	     
  else 
    return (reg((outp[i] ^ carry[i-1]),clk)); 
} 
 
virtual void out(WireVector<Bool, N>& output){	  
  int i; 
  for(i=0;i<N;i++) 
    alias(outp[i],output[i]); 
 
   outp[0] = counting(0); 
   carry[0] = outp[0]; 
   for (i=1; i<N; i++) { 
      outp[i] = counting(i); 
      carry[i] = carry[i-1] & outp[i]; 
   } 
} 

virtual void place(const Rect& place){ 
  placecarry1(place,carry,outp); 
}   
 

virtual void place(){ 
  placecarry1(carry,outp); 
} 
 
}; 
 
 
// Resetable Counter  
 
template<int N> 
class RCounter: public Counter<N>{ 
 public: 
  Bool countreset; 
 
  RCounter(Bool& reset,Bool *clock=NULL,const char *name=NULL): 
    Counter<N>(clock,name){ 
      internal(countreset); 
      countreset=reset; 
    } 
 
   
virtual EquationHandler counting(int i){ 
  if (i==0) 
    return (reg(~outp[0]&~countreset,clk)); 	     
  else 
    return (reg((outp[i] ^ carry[i-1])&~countreset,clk)); 
} 
 
}; 

 
// Counter with Enable 

template<int N> 
class ECounter: public Counter<N>{ 
 public: 
  Bool enable; 
 
ECounter(Bool& Enable,Bool *clock=NULL,const char *name=NULL): 
    Counter<N>(clock,name){ 
      internal(enable); 
 
      enable=Enable; 
 
} 
 
 
virtual EquationHandler counting(int i){ 
  if (i==0) 
    return (reg(mux(enable,~outp[0],outp[0]),clk)); 	     
  else 
    return (reg(mux(enable,(outp[i] ^ carry[i-1]),outp[i]),clk)); 
} 
 
}; 


// Counter with Reset and Enable (with priority of Enable)

template<int N> 
class RECounter: public ECounter<N>{ 
 public: 
  Bool reset; 
 
RECounter(Bool& Reset,Bool& Enable,Bool *clock=NULL,const char *name=NULL): 
    ECounter<N>(Enable,clock,name){ 
      internal(reset); 
 
      reset=Reset; 
 
} 
 
virtual EquationHandler counting(int i){ 
  if (i==0) 
    return (reg(mux(enable,mux(reset,ZERO,~outp[0]),outp[0])),clk); 	     
  else 
    return (reg(mux(enable,mux(reset,ZERO,(outp[i]^carry[i-1])),outp[i])),clk);
} 
 
}; 

 
// Loadable Counter 

template<int N> 
class LCounter: public Counter<N>{ 
 public: 
  Bool countload; 
  WireVector<Bool, N> newvalue; 
 
LCounter(Bool& Load,WireVector<Bool, N>& loadVal,Bool *clock=NULL,const char *name=NULL): 
    Counter<N>(clock,name){ 
      internal(countload); internal(newvalue); 
      int i; 
      for(i=0;i<N;i++) 
         newvalue[i]=loadVal[i]; 
 
      countload=Load; 
} 
 
 
virtual EquationHandler counting(int i){ 
  if (i==0) 
    return (reg(mux(countload,newvalue[i],~outp[0]),clk)); 	     
  else 
    return (reg(mux(countload,newvalue[i],(outp[i] ^ carry[i-1])),clk)); 
} 
 
}; 

  
// Reset and Loadable Counter  
 
template<int N> 
class RLCounter: public LCounter<N>{ 
 public: 
  Bool countreset; 
 
RLCounter(Bool& load,WireVector<Bool, N>& nval,Bool& reset,Bool *clock=NULL,const char *name=NULL): 
  LCounter<N>(load,nval,clock,name){ 
   countreset=reset; 
} 
 
virtual EquationHandler counting(int i){  
  if (i==0) 
    return (reg(mux(countload,newvalue[i],~outp[0]&~countreset),clk)); 	     
  else 
    return (reg(mux(countload,newvalue[i],((outp[i] ^ carry[i-1])&~countreset)),clk)); 
} 
 
}; 
 
 
// Loadable Counter with Enable
 
template<int N> 
class LECounter: public LCounter<N>{ 
 public: 
  Bool countenable; 
  Bool cin_dummy,cout_dummy; 
 
LECounter(Bool& load,WireVector<Bool, N>& nval,Bool& enable,Bool *clock=NULL,const char *name=NULL): 
  LCounter<N>(load,nval,clock,name){ 
    internal(countenable); 
    internal(cin_dummy); 
    internal(cout_dummy); 
    countenable=enable; 
} 
 
void out(WireVector<Bool, N>& output){	  
  int i; 
  for(i=0;i<N;i++) 
    alias(outp[i],output[i]); 
 
  cin_dummy=countenable; 
 
  outp[0] = reg(mux(countload,newvalue[0],(outp[0] ^ cin_dummy)),clk); 
  carry[0] = cin_dummy & outp[0]; 
  for (i=1; i<N; i++) { 
    outp[i] = reg(mux(countload,newvalue[i],(outp[i] ^ carry[i-1])),clk); 
    carry[i] = carry[i-1] & outp[i]; 
  } 
} 
 
virtual void place(const Rect& place){ 
  placecarry2(place,countenable,cin_dummy,cout_dummy,carry,outp); 
} 
 
virtual void place(){ 
  placecarry2(countenable,cin_dummy,cout_dummy,carry,outp); 
} 
 
};
 
 
// Enable and Loadable Shiftregister. <BR>
//       (e.g. for parallel to serial conversion) 
 
template<int N> 
class LEShifter: public LECounter<N>{ 
 public: 
 
LEShifter(Bool& load,
	  WireVector<Bool, N>& nval,
	  Bool& enable,
	  Bool *clock=NULL,
	  const char *name=NULL):LECounter(load, nval,enable,clock,name){} 
 
void out(WireVector<Bool, N>& output, Bool& carry_out){	  
  int i; 
  for(i=0;i<N;i++) 
    alias(outp[i],output[i]); 
 
    carry[0] = ZERO;
    for (i=0; i<N; i++) { 
      outp[i] = counting(i); 
      if (i>0) carry[i] = mux(enable,outp[i-1],outp[i]);
    } 
  carry_out=(reg(outp[N-1]),clk); 
} 
 
virtual EquationHandler counting(int i){  
  if (i==0) 
    return (reg(mux(countload,newvalue[i],carry[0]),clk)); 
  else 
    return (reg(mux(countload,newvalue[i],carry[i-1]),clk)); 
} 
 
};  

 
// Enable and Loadable Rotate Register. 
 
template<int N> 
class LERotate: public LECounter<N>{ 
 public: 
 
LERotate(Bool& load,
	  WireVector<Bool, N>& nval,
	  Bool& enable,
	  Bool *clock=NULL,
	  const char *name=NULL):LECounter(load, nval,enable,clock,name){} 
 
void out(WireVector<Bool, N>& output, Bool& carry_out){	  
  int i; 
  for(i=0;i<N;i++) 
    alias(outp[i],output[i]); 
 
    carry[0] = outp[N-1];
    for (i=0; i<N; i++) { 
      outp[i] = counting(i); 
      if (i>0) carry[i] = mux(enable,outp[i-1],outp[i]);
    } 
  carry_out=(reg(outp[N-1]),clk); 
} 
 
virtual EquationHandler counting(int i){  
  if (i==0) 
    return (reg(mux(countload,newvalue[i],carry[0]),clk)); 
  else 
    return (reg(mux(countload,newvalue[i],carry[i-1]),clk)); 
} 
 
};  


 
// Add 2 N bit numbers.
 
template<int N>  
class Add: public Counter<N>{ 
public: 
 
WireVector<Bool, N> Ain; 
WireVector<Bool, N> Bin; 
Bool carryIn; 
Bool cin_dummy; 
Bool carryOut,carryOut_dummy; 
 
Add(WireVector<Bool, N>& A, WireVector<Bool, N>& B, 
       Bool& cIn, Bool *clock=NULL,const char *name=NULL):  
	 Counter<N>(clock,name){ 
 
  internal(Ain); internal(Bin); 
  internal(carryIn); internal(cin_dummy); 
  internal(carryOut); internal(carryOut_dummy); 
 
  carryIn=cIn; 
 
  int i; 
  for(i=0;i<N;i++){ 
    Ain[i]=A[i]; 
    Bin[i]=B[i]; 
  } 
} 
 
Add(WireVector<Bool, N>& A, Bool& cIn, 
    Bool *clock=NULL,const char *name=NULL):Counter<N>(clock,name){ 
 
  internal(Ain);   internal(Bin); 
  internal(carryIn); internal(cin_dummy); 
  internal(carryOut); internal(carryOut_dummy); 
 
  carryIn=cIn; 
 
  int i; 
  for(i=0;i<N;i++) 
    Ain[i]=A[i]; 
} 
 
virtual void out(WireVector<Bool, N>& output, Bool *Cout=NULL) { 
  int i; 
  if (Cout!=NULL) 
    alias(*Cout,carryOut); 
  for(i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
  } 
 
  cin_dummy=carryIn; 
 
  for(i = 0; i < N; i++){ 
    outp[i] = adding(i); 
    carry[i] = carryout(i); 
  } 
 carryOut = reg(carry[N-1],clk); 
 
}  
      
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg((Ain[0] ^ Bin[0] ^ cin_dummy),clk)); 
  }else{ 
    return (reg((Ain[i] ^ Bin[i] ^ carry[i-1]),clk)); 
  } 
} 
 
 
virtual EquationHandler carryout(int i){ 
  if (i==0){ 
    return (Ain[0] & Bin[0] | 
	     Ain[0] & cin_dummy | 
	     Bin[0] & cin_dummy); 
  }else{ 
    return (Ain[i] & Bin[i] | 
	       Ain[i] & carry[i-1] | 
	       Bin[i] & carry[i-1]); 
  } 
} 
 
virtual void place(const Rect& box){ 
  PBtop<N>::placecarry2(box,carryIn,cin_dummy,carryOut,carry,outp); 
} 
 
virtual void place(){ 
  PBtop<N>::placecarry2(carryIn,cin_dummy,carryOut,carry,outp); 
} 
 
}; 
 

// Combinational Add of 2 N bit numbers (no registers)

template<int N> 
class CAdd: public Add<N>{ 
 public: 
 
CAdd(WireVector<Bool, N>& A, WireVector<Bool, N>& B, 
     Bool& cIn, Bool *clock=NULL,const char *name=NULL):  
         Add<N>(A,B,cIn,clock,name){ 
} 
      
virtual EquationHandler adding(int i){ 
 
  if (i==0){ 
    return (Ain[0] ^ Bin[0] ^ cin_dummy); 
  }else{ 
    return(Ain[i] ^ Bin[i] ^ carry[i-1]); 
  } 
} 
 
}; 
 
 
// multicycle adder with variable datawidth.  <BR>
//      (adds 2 (N*X) bit numbers in X clock cycles)
 
template<int N>  
class SerialAdd: public Add<N>{ 
 public: 
 
SerialAdd(WireVector<Bool, N>& A,  
        WireVector<Bool, N>& B, 
	Bool& startBit,  
	Bool *clock=NULL, 
	const char *name=NULL):  
	  Add<N>(A,B,startBit,clock,name){} 

SerialAdd(WireVector<Bool, N>& A,  
	Bool& startBit,  
	Bool *clock=NULL, 
	const char *name=NULL):  
	  Add<N>(A,startBit,clock,name){} 
 
virtual void out(WireVector<Bool, N>& output, Bool *Cout=NULL) { 
  int i; 
  if (Cout!=NULL) 
    alias(carryOut,*Cout); 
  for(i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
  } 
 
  cin_dummy=carryOut; 
 
  for(i = 0; i < N; i++){ 
    outp[i] = adding(i); 
    carry[i] = carryout(i); 
  } 
  carryOut = mux(carryIn,zero,reg(carry[N-1],clk)); 
}  
 
};  


// Add/Sub: Select ? (A-B) : (A+B). <BR>
//          i.e. Select = carry_in 

template<int N>  
class AddSub: public Add<N>{ 
public: 
Bool Select; 
 
AddSub(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool& select, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,select,clock,name){ 
 internal(Select);
  Select=~select; 
 
} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg((Ain[0] ^ ~(Bin[0] ^ Select) ^ cin_dummy),clk)); 
  }else{ 
    return (reg((Ain[i] ^ ~(Bin[i] ^ Select) ^ carry[i-1]),clk)); 
  } 
} 
 
virtual EquationHandler carryout(int i){ 
  if (i==0){ 
    return (Ain[0] & ~(Bin[0] ^ Select) | 
	     ~(Bin[0] ^ Select) & cin_dummy | 
	     cin_dummy & Ain[0]); 
  }else{ 
    return (Ain[i] & ~(Bin[i] ^ Select) | 
	     ~(Bin[i] ^ Select) & carry[i-1] | 
	     carry[i-1] & Ain[i]); 
  } 
} 
 
virtual void place(const Rect& box){ 
  PBtop<N>::placecarry2(box,carryIn,cin_dummy,carryOut,carry,outp); 
} 
 
virtual void place(){ 
  Select<<=carryOut;
  PBtop<N>::placecarry2(carryIn,cin_dummy,carryOut,carry,outp); 
} 

}; 

// multicycle add/subtract with variable datawidth.  <BR>
//      (add/subtracts 2 (N*X) bit numbers in X clock cycles)
 
template<int N>  
class SerialAddSub: public AddSub<N>{ 
 public: 
   Bool start;
 
SerialAddSub(WireVector<Bool, N>& A,  
        WireVector<Bool, N>& B, 
	Bool& carryIn,  
	Bool& startBit,  
	Bool *clock=NULL, 
	const char *name=NULL):  
	  AddSub<N>(A,B,carryIn,clock,name){
   internal(start);
   start=startBit;
} 
 
virtual void out(WireVector<Bool, N>& output, Bool *Cout=NULL) { 
  int i; 
  if (Cout!=NULL) 
    alias(carryOut,*Cout); 
  for(i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
  } 
 
  cin_dummy=carryOut; 
 
  for(i = 0; i < N; i++){ 
    outp[i] = adding(i); 
    carry[i] = carryout(i); 
  } 
  carryOut = mux(start,carryIn,reg(carry[N-1],clk)); 
}  
 
};  
 
 
// Loadable Add with carry in

template<int N>  
class LAddCin: public Add<N>{ 
public: 
Bool ldNot; 
 
LAddCin(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool& carryIn, 
     Bool& LoadNot, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,carryIn,clock,name){ 
	       
   internal(ldNot); 
 
   ldNot=LoadNot; 
} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg(mux(ldNot,(Ain[0] ^ Bin[0] ^ cin_dummy),Ain[0]),clk)); 
  }else{ 
    return (reg(mux(ldNot,(Ain[i] ^ Bin[i] ^ carry[i-1]),Ain[i]),clk)); 
  } 
} 
 
}; 

// Loadable Add

template<int N>  
class LAdd: public LAddCin<N>{ 
public: 
 
LAdd(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool& LoadNot, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    LAddCin<N>(A,B,zero,LoadNot,clock,name){} 
}; 
 
// Resetable Add with carry in
 
template<int N>  
class RAddCin: public Add<N>{ 
public: 
Bool reset; 
 
RAddCin(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool& carryIn, 
     Bool& Reset, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,carryIn,clock,name){ 
	       
   internal(reset); 
 
   reset=Reset; 
} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg(mux(reset,~reset,(Ain[0] ^ Bin[0] ^ cin_dummy)),clk)); 
  }else{ 
    return (reg(mux(reset,~reset,(Ain[i] ^ Bin[i] ^ carry[i-1])),clk)); 
  } 
} 
 
}; 

// Resetable Add
 
template<int N>  
class RAdd: public RAddCin<N>{ 
public:  
RAdd(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool& Reset, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    RAddCin<N>(A,B,zero,Reset,clock,name){} 
}; 

 
// Subtract 2 N bit numbers

template<int N>  
class Sub: public Add<N>{ 
public: 
 
Sub(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,one,clock,name){} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg((Ain[0] ^ ~Bin[0] ^ cin_dummy),clk)); 
  }else{ 
    return (reg((Ain[i] ^ ~Bin[i] ^ carry[i-1]),clk)); 
  } 
} 
 
virtual EquationHandler carryout(int i){ 
  if (i==0){ 
    return (Ain[0] & ~Bin[0] | 
	     Ain[0] & cin_dummy | 
	     ~Bin[0] & cin_dummy); 
  }else{ 
    return (Ain[i] & ~Bin[i] | 
	     Ain[i] & carry[i-1] | 
	     ~Bin[i] & carry[i-1]); 
  } 
} 
 
}; 
 

// LogicAdd: (A + B) LOGIC_[AND|OR|XOR|NAND|NOR|XNOR]  C.
 
template<int N>  
class LogicAdd: public Add<N>{ 
public: 
  int funct; 
  WireVector<Bool, N> Cin;  
 
LogicAdd(WireVector<Bool, N>& A,
     WireVector<Bool, N>& B,  
     int& logicFunct, 
     WireVector<Bool, N>& C, 	  
     Bool& select, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,zero,clock,name){ 

  internal(Cin);

  funct = logicFunct; 
  int i; 
  for(i=0;i<N;i++){ 
    Cin[i]=C[i]; 
  } 
} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg(W.logic(Ain[0] ^ Bin[0] ^ cin_dummy, Cin[0],funct), clk)); 
  }else{ 
    return (reg(W.logic(Ain[i] ^ Bin[i] ^ carry[i-1] , Cin[i], funct), clk)); 
  } 
} 
 
}; 

// LogicSub: (A - B) LOGIC_[AND|OR|XOR|NAND|NOR|XNOR]  C.
 
template<int N>  
class LogicSub: public Sub<N>{ 
public: 
  int funct; 
  WireVector<Bool, N> Cin;  
 
LogicSub(WireVector<Bool, N>& A,
     WireVector<Bool, N>& B,  
     int& logicFunct, 
     WireVector<Bool, N>& C, 	  
     Bool& select, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,clock,name){ 
 
  internal(Cin);

  funct = logicFunct; 
  int i; 
  for(i=0;i<N;i++){ 
    Cin[i]=C[i]; 
  } 
} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg(W.logic(Ain[0] ^ ~Bin[0] ^ cin_dummy, Cin[0],funct), clk)); 
  }else{ 
    return (reg(W.logic(Ain[i] ^ ~Bin[i] ^ carry[i-1] , Cin[i], funct), clk)); 
  } 
} 
 
}; 
 

// Combinational Add/Sub: Select ? (A-B) : (A+B).
 
template<int N>  
class CAddSub: public Add<N>{ 
public: 
Bool Select; 
 
CAddSub(WireVector<Bool, N>& A,  
     WireVector<Bool, N>& B,  
     Bool& select, 
     Bool *clock=NULL, 
     const char *name=NULL):  
	    Add<N>(A,B,select,clock,name){ 
  internal(Select);
  Select=~select; 
} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (Ain[0] ^ ~(Bin[0]^Select) ^ cin_dummy); 
  }else{ 
    return (Ain[i] ^ ~(Bin[i]^Select) ^ carry[i-1]); 
  } 
} 
 
virtual EquationHandler carryout(int i){ 
  if (i==0){ 
    return (Ain[0] & ~(Bin[0]^Select) | 
	     Ain[0] & cin_dummy | 
	     ~(Bin[0]^Select) & cin_dummy); 
  }else{ 
    return (Ain[i] & ~(Bin[i]^Select) | 
	     Ain[i] & carry[i-1] | 
	     ~(Bin[i]^Select) & carry[i-1]); 
  } 
} 
 
}; 
 
 
// Constant Serial Add <BR>
//      adds 1 N*X bit number in X clock cycles. <BR>
//      Area[CLBs]: N/2 + 1 (N=4 X=4 -> 16 bit data)<BR>
// ! NOT A TEMPLATE ! <BR>
 
class ConstSerialAdd: public SerialAdd<4>{ 
 public: 
  WireVector<Bool, 2> Count; 
  WireVector<WireVector<Bool, 4>, 4> tmp; 
 
  int K; 
 
ConstSerialAdd(WireVector<Bool, 4>& A,  
	       WireVector<Bool, 2>& count, 
	       Bool& CSstart, 
	       int& Aconstant, 
	       Bool *clock=NULL, 
	       const char *name=NULL):  
		 SerialAdd<4>(A,CSstart,clock,name){ 
  internal(Count); internal(tmp); 
 
  int i; 
  K=Aconstant; 
  Count[0]=count[0]; Count[1]=count[1]; 
 
  for(i=0;i<4;i++){   
    tmp[i][0]=((K>>(0+i))&1L)?(~Count[0]&~Count[1]):ZERO; 
    tmp[i][0]<<=outp[i]; 
    tmp[i][1]=tmp[i][0] | (((K>>(4+i))&1L)?(Count[0]&~Count[1]):ZERO); 
    tmp[i][1]<<=tmp[i][0]; 
    tmp[i][2]=tmp[i][1] | (((K>>(8+i))&1L)?(~Count[0]&Count[1]):ZERO); 
    tmp[i][2]<<=tmp[i][1]; 
    tmp[i][3]=tmp[i][2] | (((K>>(12+i))&1L)?(Count[0]&Count[1]):ZERO); 
    tmp[i][3]<<=tmp[i][2]; 
  } 
} 
 
virtual EquationHandler adding(int i){ 
 
  if (i==0){ 
    return (reg((Ain[0] ^ tmp[0][3] ^ cin_dummy),clk)); 
  }else{ 
    return (reg((Ain[i] ^ tmp[i][3] ^ carry[i-1]),clk)); 
  } 
} 
 
 
virtual EquationHandler carryout(int i){ 
 
  if (i==0){ 
    return (Ain[0] & tmp[0][3] | 
	     Ain[0] & cin_dummy | 
	     tmp[0][3] & cin_dummy); 
  }else{ 
    return (Ain[i] & tmp[i][3] | 
	       Ain[i] & carry[i-1] | 
	       tmp[i][3] & carry[i-1]); 
  } 
} 
 
};  
 
 
// Parallel ==> Serial Conversion. 
 
template<int IN, int OUT> 
class ParToSer: public Register<IN>{ 
 public: 
 
ParToSer(Bool& Load, WireVector<Bool, IN>& Input,  
	 Bool *clock=NULL, const char *name=NULL): 
	   Register<IN>(Load,Input,clock,name){ 
} 
 
void out(WireVector<Bool, OUT>& output){	  
  int i; 
  for(i=0;i<OUT;i++) 
    alias(outp[i],output[i]); 
 
  for (i=0; i<IN; i++) { 
    if (i<(IN-OUT)) 
      outp[i] = reg(mux(loadreg,invector[i],outp[i+OUT]),clk); 
    else   
      outp[i] = reg(mux(loadreg,invector[i],outp[i]),clk); 
  } 
} 
 
};  
 

// Serial ==> Parallel conversion

template<int IN, int OUT> 
class SerToPar: public PBtop<OUT>{ 
 public: 
  WireVector<Bool, IN> in; 
 
SerToPar(WireVector<Bool, IN>& Input, 
	 Bool *clock=NULL, const char *name=NULL): 
	   PBtop<OUT>(clock,name){ 
 
  internal(in); 
 
  int i; 
  for(i=0;i<IN;i++) 
    in[i]=Input[i]; 
} 
 
void out(WireVector<Bool, OUT>& output){	  
  int i; 
  for(i=0;i<OUT;i++) 
    alias(outp[i],output[i]); 
 
  for (i=0; i<OUT; i++) { 
    if (i<(OUT-IN)) 
      outp[i] = reg(outp[i+IN],clk); 
    else   
      outp[i] = reg(in[i-OUT+IN],clk); 
     
  } 
} 
 
virtual void place(const Rect& box){ 
  PBtop<OUT>::place(box,outp); 
} 
 
virtual void place(){ 
  PBtop<OUT>::place(outp); 
} 
};  

 
// Increment  
 
template<int N> 
class Increment: public Add<N>{ 
 public: 
Increment(WireVector<Bool, N>& Input, 
	  Bool& Enable, 
	  Bool *clock=NULL,const char *name=NULL): 
	    Add<N>(Input,Input,Enable,clock,name){} 
 
virtual EquationHandler adding(int i){ 
  if (i==0){ 
    return (reg((Ain[0] ^ cin_dummy),clk)); 
  }else{ 
    return (reg((Ain[i] ^ carry[i-1]),clk)); 
  } 
} 
  
virtual EquationHandler carryout(int i){ 
  if (i==0){ 
    return (Ain[0] & cin_dummy); 
  }else{ 
    return (Ain[i] & carry[i-1]); 
  } 
} 
 
}; 
 

// Serial Increment
//      increments 1 N*X bit number in X clock cycles.

template<int N> 
class SerialIncrement: public Increment<N>{ 
 public: 
Bool enable; 
Bool cin_dummy1; 
 
SerialIncrement(WireVector<Bool, N>& Input, 
		Bool& start, 
		Bool& Enable, 
		Bool *clock=NULL,const char *name=NULL): 
    Increment<N>(Input,start,clock,name){ 
internal(enable); internal(cin_dummy1); 
 
enable=Enable; 
} 
 
virtual void out(WireVector<Bool, N>& output, Bool *Cout=NULL) { 
  int i; 
  if (Cout!=NULL) 
    alias(carryOut,*Cout); 
  for(i=0;i<N;i++){ 
    alias(outp[i],output[i]); 
  } 
  cin_dummy1=enable&(carryIn|carryOut); 
  cin_dummy=cin_dummy1; 
 
  for(i = 0; i < N; i++){ 
    outp[i] = adding(i); 
    carry[i] = carryout(i); 
  } 
  carryOut = reg(carry[N-1],clk); 
}  
 
};  
 
 
// match N bits (currently only supports N=[8|12|16]) 
 
template<int N> 
class MatchAll: public PBtop<N>{ 
 public: 
  WireVector<Bool, (N/4)> quad;  
  WireVector<Bool, (N/8)> oct;  
  WireVector<Bool, N> In;   
  int value; 
 
MatchAll(WireVector<Bool, N>&in, const int& Val,Bool *clock=NULL,const char *name=NULL): 
  PBtop<N>(clock,name) 
{ 
    internal(In); internal(quad); internal(oct); 
 
    for (int i=0;i<N;i++) 
      In[i]=in[i]; 
 
    value=(int)Val; 
    if ((value!=0)&&(value!=1)) { 
       printf("ERROR: MatchAll value!=0,1 \n"); 
       exit(-1); 
    } 
 
} 
   
virtual void out(Bool& Out){	  
   int i; 
   alias(outp[0],Out); 
 
   for (i=0; i<(N/4); i++) { 
     if (value==0){ 
       quad[i]=(~In[i*4]&~In[i*4+1]&~In[i*4+2]&~In[i*4+3]); 
     }else{ 
       quad[i]=(In[i*4]&In[i*4+1]&In[i*4+2]&In[i*4+3]); 
     } 
     quad[i]<<=quad[i]; 
   } 
    
   for (i=0;i<(N/8);i++){ 
     oct[i]=(quad[2*i]&quad[2*i+1]); 
     oct[i]<<=quad[2*i]; 
   } 
   switch(N){ 
   case 4: 
     Out=reg(oct[0],clk); 
     break; 
   case 8: 
     Out=reg(oct[0]&oct[1],clk); 
     break; 
   case 12: 
     Out=reg(oct[0]&oct[1]&oct[2],clk); 
     break; 
   case 16: 
     Out=reg(oct[0]&oct[1]&oct[2]&oct[3],clk); 
     break; 
   } 
      
   Out<<=Out; 
} 
 
virtual void place(){ 
  int i; 
   for (i=1; i<(N/4); i++)  
     quad[i]<<=quad[0]+OFFSET(0,-(i/2)); 
   for (i=0; i<(N/8); i++)  
     oct[i]<<=quad[0]+OFFSET(1,-(i/2)); 
 
   outp[0]<<=quad[0]+OFFSET(1,-(i/2)-1); 
} 
 
virtual void place(const Coords& corner){ 
  quad[0]<<=LOC(corner.x,corner.y); 
  place(); 
}   
 
}; 
 
  
#endif 

/* PamBlox END */ 
 
 
 
 
 
 
 
