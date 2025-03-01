/*-----------------------------------------------------------*/ 
/*  pamtypes.h: support functions,types,constants, etc.      */
/*-----------------------------------------------------------*/ 
/* PAM-Blox version 1.1:                                     */
/* object-oriented circuit generators for custom computing   */
/*                     Oskar Mencer                          */ 
/*      Computer Architecture and Arithmetic Group           */
/*                  Stanford University                      */
/*                                                           */
/* PAM-Blox are distributed under the GNU Public license     */ 
/*      check GNUlicense.h for the license notice            */ 
/*      check GNUlicense.txt for all the details             */ 
/*                                                           */
/*  Questions ? email: pamblox@umunhum.stanford.edu          */ 
/*                                                           */
/* last mod 6/6/98 by mencer                                */ 
/*************************************************************/

#ifndef PAMTYPES_H 
#define PAMTYPES_H 
 
// general includes

#include <stdio.h> 
#include <ctype.h>
#include <iostream.h> 
#include <fstream.h> 
#include "stddef.h" 
#include "assert.h" 
#include "string.h" 
#include "math.h"
 
#include <PamDC/design.h> 
#include <PamDC/XC4000E.h> 
#include <PamDC/ppamv1.h>
 
#define DEBUG

const int MAX_NAME_LEN=100; 
int namenum=0; 
 
// logic functions 
enum logicFunctions {LOGIC_AND, LOGIC_OR, LOGIC_XOR, LOGIC_NAND, LOGIC_NOR, LOGIC_XNOR}; 
 
enum chiptypes {XC4010E, XC4020E}; 
char *chipnames[2] = {"XC4010E", "XC4020E"}; 
char *chippackages[2] = {"PQ208", "HQ208"}; 
  
chiptypes chiptype; 
 
// create name for the chip 
char *mkname(char *basename, char *chipname) { 
 
  char *name = new char[strlen(basename) + strlen(chipname) + 1]; 
 
  strcpy(name, basename); 
  strcat(name, chipname); 
 
  for (int i=0; name[i] != 0; i++) { 
    name[i] = char(tolower(name[i])); 
  } 
 
  return name; 
} 
 
// create a unique name in case the user does not specify any name  
char *make_name(char *name){ 
  char y[10]; 
  char *x; 
  x=(char *)malloc(MAX_NAME_LEN); 
 
  assert(x==strcpy(x,name)); 
  
  sprintf(y,"%d\0",namenum); 
  strcat(x,y); 
  namenum++; 
  return x; 
} 
 
// Utility which returns equationHandler type "0" and "1" with 
// integer input
EquationHandler retEH(int x) {
    if (x)
        return(ONE);
    else
        return(ZERO);
}

// create wire naming 
#define XCAT(_x) "/" #_x 

#define NAME(_wire) { char tmp[MAX_NAME_LEN]; strcpy((char *)tmp,(char *)myName); this->add_internal(&_wire,strcat((char *)tmp,XCAT(_wire))); } 

// fix wiring functions: shift, rotate, vector constants, etc.
//      usage:  W.AliasVector(...);

class Wiring{
 public:

void AliasVector(Wire& X, Wire& Y){
  int i;

  if (X.get_n_elts()!=Y.get_n_elts()) {
    printf("ERROR: AliasVector parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<X.get_n_elts();i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt(i)->get_bool());
  }
}

void EqualVector(Wire& X, Wire& Y){
  int i;

  if (X.get_n_elts()!=Y.get_n_elts()) {
    printf("ERROR: EqualVector parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<X.get_n_elts();i++){
    *Y.get_elt(i)->get_bool()=*X.get_elt(i)->get_bool();
  }
}

void FlipVector(Wire& X, Wire& Y){
  int i;

  if (X.get_n_elts()!=Y.get_n_elts()) {
    printf("ERROR: VectorAlias parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<X.get_n_elts();i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt(X.get_n_elts()-i)->get_bool());
  }
}

void ConstantVector(Wire& X, int& value){
  int i;

  for(i=0;i<X.get_n_elts();i++){
    if ((value>>i)&1L)
      *X.get_elt(i)->get_bool()=ONE;
    else
      *X.get_elt(i)->get_bool()=ZERO;
  }
}

void ShiftLeft(Wire& X, Wire& Y, int by){
  int i;

  if (X.get_n_elts()!=Y.get_n_elts()) {
    printf("ERROR: ShiftLeft parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<by;i++){
    *Y.get_elt(i)->get_bool()=ZERO;
  }
  for(i=by;i<X.get_n_elts();i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt(i-by)->get_bool());
  }
}

void ShiftRight(Wire& X, Wire& Y, int by){
  int i, elemX;

  elemX = X.get_n_elts();

  if (elemX!=Y.get_n_elts()) {
    printf("ERROR: ShiftRight parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<by;i++){
    *Y.get_elt(elemX-i-1)->get_bool() = ZERO;
  }
  for(i=0;i<(elemX-by);i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt(i+by)->get_bool());
  }
}

void ShiftRight2sComp(Wire& X, Wire& Y, int by){
  int i, elemX;

  elemX = X.get_n_elts();

  if (elemX!=Y.get_n_elts()) {
    printf("ERROR: ShiftRight parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<by;i++){
    *Y.get_elt(elemX-i-1)->get_bool() = *X.get_elt(elemX-1)->get_bool();
  }
  for(i=0;i<(elemX-by);i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt(i+by)->get_bool());
  }
}

void RotLeft(Wire& X, Wire& Y, int by){
  int i;

  if (X.get_n_elts()!=Y.get_n_elts()) {
    printf("ERROR: RotLeft parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<X.get_n_elts();i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt((i-by)%X.get_n_elts())->get_bool());
  }
}

void RotRight(Wire& X, Wire& Y, int by){
  int i;

  if (X.get_n_elts()!=Y.get_n_elts()) {
    printf("ERROR: RotRight parameter size mismatch.\n");
    exit(-1);
  }
  for(i=0;i<X.get_n_elts();i++){
    alias(*Y.get_elt(i)->get_bool(),*X.get_elt((i+by)%X.get_n_elts())->get_bool());
  }
}

void Scatter(Bool& X, Wire& Y){
  int i;
  for(i=0;i<X.get_n_elts();i++)
    alias(*Y.get_elt(i)->get_bool(),X);
}

EquationHandler logic(EquationHandler& A, EquationHandler& B, int& funct){ 
  switch (funct){ 
    case LOGIC_AND: 
      return (A&B); 
      break; 
    case LOGIC_OR: 
      return (A|B); 
      break; 
    case LOGIC_XOR: 
      return (A^B); 
      break; 
    case LOGIC_NAND: 
      return ((~A)&(~B)); 
      break; 
    case LOGIC_NOR:  
      return ((~A)|(~B)); 
      break; 
    case LOGIC_XNOR: 
      return ((~A)^(~B)); 
      break; 
  default: 
    DEBUG("ERROR: no such logic function.\n"); 
    return A; 
  } 
} 
 
};

Wiring W;


// Utility which returns equationHandler type "0" and "1" with 
// integer input

EquationHandler returnEH(int x) {
    if (x)
        return(ONE);
    else
        return(ZERO);
}

//////////////////////////// 
// Simulation support 
//////////////////////////// 
 
//  convert wire vector 'a' into integer value, provided that 
//  'a[i]' matches 'wanting'. 'allowFloating' allows for floating 
//  values on 'a[i]' 

long intval(Wire& a, int wanting, int allowFloating) 
{ 
  long v = 0, i; 
  assert((a.is_vector() == 1) && (a.get_n_elts() > 0) && 
	 (a.get_elt(0)->get_bool())); 
  for (i = 0; i < a.get_n_elts(); i++) { 
    assert(allowFloating || 
	   (a.get_elt(i)->get_bool()->get_value() != 2)); 
    if (a.get_elt(i)->get_bool()->get_value() == wanting) { 
        v |= 1L<<i; 
    } 
  } 
  return v; 
} 
 
  
// PCI/PIF interface protocol defines 
 
const int ebAIF = 0x7; 
const int ebDW  = 0x6; 
// AIU AUI must differ in low bit only 
const int ebAIU = 0x5; // Processor Write 
const int ebAUI = 0x4; // Processor Read 
const int ebDV  = 0x3; // DV DS must differ in low bit only 
const int ebDS  = 0x2; 
const int ebMSTR= 0x1; 
const int ebIDLE= 0x0; 
 
 
// Coordinates for placement
 
class Coords{ 
  public: 
   int x; 
   int y;  
 
   Coords(int x, int y){ 
      assert((x>=0)&&(y>=0)); 
      this->x = x; 
      this->y = y; 
   } 
 
   Coords(Coords *corner){ 
      assert((corner->x>=0)&&(corner->y>=0)); 
      this->x = corner->x; 
      this->y = corner->y; 
   } 
 
}; 
 
 
// Shapes for placement of hardware objects 
 
class Rect{ 
  public: 
   Coords corner; 
   int width; 
   int height; 
   int area;  // usually width*height 
 
   Rect(int x, int y, int width, int height):corner(x,y){ 
      assert((x>=0)&&(y>=0)); 
      this->width = width; 
      this->height = height; 
   } 
 
   Rect(Rect *rect):corner(rect->corner.x,rect->corner.y){ 
      if (rect==NULL) return; 
      assert((rect->corner.x>=0)&&(rect->corner.y>=0)); 
      this->width = rect->width; 
      this->height = rect->height; 
   } 
 
   Rect* getPtr(){ return this; } 
 
   void move(int x, int y){  
     this->corner.x += x; 
     this->corner.y += y; 
   } 
 
}; 
 
// util_design.cxx 
// library functions for design 
// 
// Last modified on Thu Jun 16 18:31:22 MET DST 1994 by phi 
 

// various types of Registers 

 
// Register with Enable 

void reg_en(Bool& En, EquationHandler In, Bool& Out, Bool& clock) { 
  Out = reg(mux(En, In, Out), clock); 
  Out <<= CLB_INPUT(EC, En); 
} 
 
// Register with Asynchronous Reset 

void reg_rd(Bool& Rd, EquationHandler In, Bool& Out, Bool& clock) { 
  Out = ~Rd & reg(~Rd & In, clock); 
  Out <<= CLB_INPUT(RD, Rd); 
} 
 
// Register with Enable and Asynchronous Reset 

void reg_en_rd(Bool& En, Bool& Rd, EquationHandler In, Bool& Out, Bool& clock) { 
  Out = ~Rd & reg(~Rd & mux(En, In, Out), clock); 
  Out <<= CLB_INPUT(EC, En); 
  Out <<= CLB_INPUT(RD, Rd); 
} 
 
// Register with Synchronous Set Reset 

void reg_SR(EquationHandler Set, EquationHandler Reset, Bool& Out, Bool& clock) { 
  Out = reg(~Reset & (Set | Out), clock); 
} 
 

//  flexible Timer 

class Timer : public Node { 
  int size, delay; 
 
int t_size(int delay) { 
  for(int n = 1; ; n++) if((1<<n) + n >= delay) return n; 
} 
 
 public: 
  DynWireVector<Bool> Q, R; 
  Bool Enable; 
 
Timer(int delay) : Q(t_size(delay)), R(t_size(delay)), Node("Timer") { 
  this->size = t_size(delay); 
  this->delay = delay; 
  internal(Q); internal(R); internal(Enable); 
} 
 
void logic(Bool& In, Bool& Out, Bool& clock) { 
  input(In); output(Out); 
  int init = (1 << size) + size - delay; 
 
  Enable = reg(In | (~Out & Enable), clock); 
     
  if(init & 1) Q[0] = reg(In | (Q[0] ^ Enable), clock); 
  else Q[0] = reg(~In & (Q[0] ^ Enable), clock); 
  R[0] = reg(~In & Q[0] & Enable, clock); 
 
  for(int i = 1; i < size; i++) { 
    if(init & (1<<i)) Q[i] = reg(In | (R[i-1] ^ Q[i]), clock); 
    else Q[i] = reg(~In & (R[i-1] ^ Q[i]), clock); 
    R[i] = reg(~In & R[i-1] & Q[i], clock); 
  } 
   
  alias(Out, R[size-1]); 
} 
 
void placement(int X0, int Y0, int Width, int Heigh) { 
  int i, SignX, SignY, AWidth, AHeigh, x, y; 
 
  SignX = Width > 0 ? 1 : -1; 
  SignY = Heigh > 0 ? 1 : -1; 
  AWidth = SignX * Width; 
  AHeigh = SignY * Heigh; 
  if(AWidth * AHeigh < size + 1) { 
    printf("Size not fit\n"); 
    exit(1); 
  } 
 
  for(i = 0; i < size + 1; i++) { 
    y = i / AWidth; 
    x = y % 2 ? AWidth - (i % AWidth) - 1 : i % AWidth; 
    if(i < size) { 
      Q[i] <<= LOC(X0 + SignX * x,  Y0 + SignY * y); 
      R[i] <<= Q[i]; 
    } 
    else { 
      Enable <<= LOC(X0 + SignX * x,  Y0 + SignY * y); 
    } 
  } 
} 
 
}; 
 

// Decoder 
 
EquationHandler Decode(Wire *In, long Val, long Mask) { 
 
  // Check In is a vector of Bools containing at least one element; 
  if (!(In->is_vector() == 1 && In->get_n_elts() > 0 && In->get_elt(0)->get_bool() != 0)) { 
    In->useError("Decode : Bad Input type", 1 /* fatal */); 
  } 
  EquationHandler result = ONE; 
 
  for(int i = 0; i < In->get_n_elts(); i++) { 
    if (((1L<<i) & Mask)) { 
      if(Val & (1L<<i)) 
	result = result & (*(In->get_elt(i)->get_bool())); 
      else 
	result = result & ~(*(In->get_elt(i)->get_bool())); 
    } 
  } 
  return result; 
} 
 
EquationHandler Decode(Wire *In, long Val) { 
    long Mask; 
    if (In->is_vector() == 1) 
	Mask = (1<<In->get_n_elts())-1; 
    else 
	Mask = 1; 
    return Decode(In, Val, Mask); 
} 
 
 

// Simulation utilities for setting and getting vectors 

int getVector(Wire *In){ 
  int i, val = 0; 
 
  // Check if In is a vector of Bools containing at least one element
  if (!(In->is_vector() == 1 && In->get_n_elts() > 0 && In->get_elt(0)->get_bool() != 0)) { 
    In->useError("Decode : Bad Input type", 1 /* fatal */); 
  } 
  for(i = 0; i < In->get_n_elts(); i++) 
    val |= ((*(In->get_elt(i)->get_bool())).get_value() & 1) << i; 
  return val; 
} 
 
 
void setVector(Wire *In, int val) { 
  int i; 
 
  // Check if In is a vector of Bools containing at least one element
  if (In->is_vector() == 1 && In->get_n_elts() > 0 && In->get_elt(0)->get_bool() != 0) { 
    for(i = 0; i < In->get_n_elts(); i++) 
      (*(In->get_elt(i)->get_bool())).set_value((val >> i) & 1); 
  } 
  else { 
    In->useError("Decode : Bad Input type", 1 /* fatal */); 
  } 
} 
 

#endif 
 
/* pamtypes END */ 
