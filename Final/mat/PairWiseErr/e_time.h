//--------------------------------------------------------------------------------------------- FOR PROFILING //
#include <sys/time.h>                                                                                         //
#include <sys/resource.h>                                                                                     //
double e_time(void)                                                                                           //
{                                                                                                             //
  static struct timeval now;                                                                                  //
  static struct timezone tz;                                                                                  //
  gettimeofday(&now, &tz);                                                                                    //
  return (double)(now.tv_sec + now.tv_usec/1000000.0);                                                        //
}                                                                                                             //
static double lap_i,lap_j,lap_c,lap_f;                                                                        //
void lap_clean(void){  lap_j=lap_i=lap_c=lap_f=0.0; }                                                         //
void lap_get(double* j, double* i, double* c, double* f){*j = lap_j;  *i = lap_i;  *c = lap_c;  *f = lap_f;}  //
//------------------------------------------------------------------------------------------------------------//
