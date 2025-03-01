#include <math.h>
#define DIM (3)              /* ������ */
//#define NMAX (65536)         /* �ő嗱�q�� */
#define NMAX (262144)
//#define NTOTAL 1000      /* ���q�� (NTOTAL <= NMAX) */

//b3_force_sepaj4.c
void b3_force_sepaj4(double x[][3],
		     double m[],
		     double eps2,
		     double a[][3],
		     int n);

//pg_pipe.c
void force_gravity_on_emulator(double x[][3],
			       double m[],
			       double eps2,
			       double a[][3],
			       int n);

//force_gravity_on_b3.c
void force_gravity_on_b3(double x[][3],
			  double m[],
			  double eps2,
			  double a[][3],
			  int n);

//force_gravity_on_pg2.c
void force_gravity_on_pg2(double x[][3],
			  double m[],
			  double eps2,
			  double a[][3],
			  int n);

void force(double x[][DIM], double m[], double eps2, double a[][DIM], int n);

double energy(double m[], double x[][DIM], double v[][DIM], double eps2, int n);

void leapflog(double dt,double x[][DIM],double v[][DIM],int n);
void leapflog_half(double dt,double x[][DIM],double v[][DIM],int n);

void debug_func_force(double x[][DIM],double m[], double eps2,double a[][DIM],int n);

void debug_position(double x[][DIM], double dt, int n);
void debug_position_snap(double x[][DIM], double Gflops, int n, int nstep);

void writelog(double m[], double x[][DIM], double v[][DIM], double eps2, int n);

void init_particles(char* fname,
		    int* npar,
		    double mass[],
		    double posi[][DIM],
		    double veloc[][DIM]);
