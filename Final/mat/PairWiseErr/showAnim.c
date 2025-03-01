#include <stdio.h>
#include <GL/glut.h>
#include <string.h> // strtok(),strcpy()
#include <stdlib.h> // atof()
#include <math.h>
#define NMAX 210000
#define XSCALE 2.0
#define YSCALE 2.0
//#define IS_PRESET 0
#define IS_PRESET 1
#define PRESET_NBODY 4096
//#define PRESET_NBODY 16384
//#define PRESET_NBODY 3

#define PRESET_NWRITE 1
#define PRESET_NSKIP 1

static char ifile[256];
static int istep;
static FILE *fp;

int imax;
double x[NMAX];
double y[NMAX];
int NBODY;
int SKIP_STEP;

void reset_fp()
{
    printf("restart\n");
    fclose(fp);
    fp = fopen(ifile,"r");
    istep=0;
}

void skip_step()
{
  int i;
  char line[101];
  for(i=0;i<NBODY;i++) if(fgets(line,100,fp)==NULL){reset_fp();}
}

void myidle()
{
  istep++;
  if((istep%SKIP_STEP) != 0){
    skip_step();
  }else{
    glutPostRedisplay();
  }
  //  printf("%d step\n",(istep*SKIP_STEP));
}

void display();

void init()
{
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glColor3f(1.0,1.0,1.0);
}


int main(int argc, char** argv)
{

  if(IS_PRESET){
    NBODY = PRESET_NBODY*PRESET_NWRITE;
    SKIP_STEP=PRESET_NSKIP;
  }else{
    int nb,nw;
    printf("enter NBODY:");  scanf("%d",&nb);  //$BN3;R?t$r;XDj(B
    printf("enter Nwrite:");  scanf("%d",&nw);  //$BO"B3=q9~$_%3%^?t(B
    //    printf("enter SKIP_STEP:");  scanf("%d",&SKIP_STEP); 
    NBODY = (int)(nb * nw);
    SKIP_STEP=1; // Fixed
  }
  istep=0;
  if(argc <2){printf("no inputfile.\n"); exit(0); }
  strcpy(ifile,argv[1]);
  fp = fopen(ifile,"r");

  glutInit(&argc,argv);
  glutInitDisplayMode(GLUT_DOUBLE |GLUT_RGB);
  glutInitWindowSize(400,400);
  glutInitWindowPosition(600,0);
  glutCreateWindow("NBODYH-2003/11/08");
  glutDisplayFunc(display);
  glutIdleFunc(myidle);
  init();
  glutMainLoop();

  fclose(fp);
  return 0;
}




void display()
{
  static int flag=0;
  void display_set_GL_LINES();
  void display_get_position();
  glClear(GL_COLOR_BUFFER_BIT);
  glPointSize(1.0);

  { //--- TIME METER ---
    char p[10];
    int i,nketa;
    nketa = 6;
    sprintf(p,"%06d",istep);
    glColor3f(0.1 ,0.2,0.3);
    for(i=0;i<nketa;i++){
      glutBitmapCharacter(GLUT_BITMAP_TIMES_ROMAN_24,p[nketa-i]);
      glRasterPos2f(-0.70-0.06*i, -0.95);
    }
  }

  display_set_GL_LINES();
  glBegin(GL_POINTS);
  //  glColor3f(1.0 ,0.8,0.0);
  if(flag != 0){
    int n;
    display_get_position();
    for(n=0;n<NBODY;n++){
      if(n==1)   glColor3f(1.0,0.5,0.0); else   glColor3f(0.0,0.7,0.0);
      glVertex2f(x[n]/XSCALE, y[n]/YSCALE);
    }
  }
  flag=1;
  glEnd();
  glutSwapBuffers();
}


/* display$B4X?tMQ(B */
void display_set_GL_LINES()
{ // --- MEMORI ---

  glBegin(GL_LINES);

  glColor3f(0.7,0.0,0.0);
  glVertex2f(-1.0, 0.0);    glVertex2f(1.0, 0.0);
  glVertex2f(0.0, -1.0);    glVertex2f(0.0, 1.0);

  glColor3f(0.0,0.2,0.5);
  glVertex2f(-1.0, 1.0/3.0);    glVertex2f(1.0, 1.0/3.0);
  glVertex2f(-1.0, 2.0/3.0);    glVertex2f(1.0, 2.0/3.0);
  glVertex2f(-1.0, -1.0/3.0);    glVertex2f(1.0, -1.0/3.0);
  glVertex2f(-1.0, -2.0/3.0);    glVertex2f(1.0, -2.0/3.0);

  glVertex2f(1.0/3.0,-1.0);    glVertex2f(1.0/3.0,1.0);
  glVertex2f(2.0/3.0,-1.0);    glVertex2f(2.0/3.0,1.0);
  glVertex2f(-1.0/3.0,-1.0);    glVertex2f(-1.0/3.0,1.0);
  glVertex2f(-2.0/3.0,-1.0);    glVertex2f(-2.0/3.0,1.0);

  {
    double tiny=0.04;
    double small=0.04;
    glColor3f(0.9,0.4,0.8);
    glVertex2f(-1.0,  0.0);    glVertex2f(-(1.0-small),  0.0);
    glVertex2f( 1.0,  0.0);    glVertex2f( (1.0-small),  0.0);
    glVertex2f(  0.0, 1.0);    glVertex2f(  0.0,   1.0-small);
    glVertex2f(  0.0,-1.0);    glVertex2f(  0.0,  -1.0+small);

    glColor3f(0.38, 0.01, 0.8);
    glVertex2f(-1.0, 1.0/3.0);    glVertex2f(-(1.0-tiny), 1.0/3.0);
    glVertex2f( 1.0, 1.0/3.0);    glVertex2f( (1.0-tiny), 1.0/3.0);
    glVertex2f(-1.0, 2.0/3.0);    glVertex2f(-(1.0-tiny), 2.0/3.0);
    glVertex2f( 1.0, 2.0/3.0);    glVertex2f( (1.0-tiny), 2.0/3.0);
    glVertex2f(-1.0, -1.0/3.0);    glVertex2f(-(1.0-tiny), -1.0/3.0);
    glVertex2f( 1.0, -1.0/3.0);    glVertex2f( (1.0-tiny), -1.0/3.0);
    glVertex2f(-1.0, -2.0/3.0);    glVertex2f(-(1.0-tiny), -2.0/3.0);
    glVertex2f( 1.0, -2.0/3.0);    glVertex2f( (1.0-tiny), -2.0/3.0);

    glVertex2f(1.0/3.0,-1.0);    glVertex2f(1.0/3.0,-(1.0-tiny));
    glVertex2f(1.0/3.0, 1.0);    glVertex2f(1.0/3.0, (1.0-tiny));
    glVertex2f(2.0/3.0,-1.0);    glVertex2f(2.0/3.0,-(1.0-tiny));
    glVertex2f(2.0/3.0, 1.0);    glVertex2f(2.0/3.0, (1.0-tiny));
    glVertex2f(-1.0/3.0,-1.0);    glVertex2f(-1.0/3.0,-(1.0-tiny));
    glVertex2f(-1.0/3.0, 1.0);    glVertex2f(-1.0/3.0, (1.0-tiny));
    glVertex2f(-2.0/3.0,-1.0);    glVertex2f(-2.0/3.0,-(1.0-tiny));
    glVertex2f(-2.0/3.0, 1.0);    glVertex2f(-2.0/3.0, (1.0-tiny));
  }
  glEnd(); // --- End GL_LINES;
}

void display_get_position()
{
  int i;
  char line[1024];
  char* p;
  double _x,_y,_z;
  for(i=0;i<NBODY;i++){
    if(fgets(line,100,fp)!=NULL){
      p = (char* )strtok(line,"\t"); _x = atof(p);
      p = (char* )strtok(NULL,"\t"); _y = atof(p);
      p = (char* )strtok(NULL,"\t"); _z = atof(p);
      x[i] = _x;
      y[i] = _y;
    }else{
      reset_fp();
    }
  }
}
