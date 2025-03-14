/*                                                                  
   Interface Program for PG2                                        
     generated by pgpgi : ver 0.0, Dec 29 2004                      
     Toshiyuki Fukushige                                            
*/                                                                  
#include <stdio.h>                                                  
#include <math.h>                                                   
                                                                    
void force_gravity_on_emulator(x,m,eps2,a,n)
        double x[][3];
        double m[];
        double eps2;
        double a[][3]; int n;
{                                                                   
  int i,j,ii,nn;                                                    
  int devid,npipe;                                                  
  static int initflag=1;                                            
  int ndj,ni,nd,nword,retword;                                      
  unsigned int ipdata[2048];                                        
  unsigned int jpdata[2048];                                        
  unsigned int fodata[2048];                                        
  int xj;
  int yj;
  int zj;
  int mj;
  int xi;
  int yi;
  int zi;
  int ieps2;
  long long int sx;
  long long int sy;
  long long int sz;
                                                                    
  devid = 0;                                                        
  npipe = 20;                                                 
                                                                    
  if(initflag == 1){                                                
    g6_init(devid);                                                 
    g6_send_fpga_data(devid,"pgfpga.ttf");                        
    initflag = 0;                                                   
  }                                                                 
                                                                    
  ndj = 2;                                                          
  ipdata[0] = 0x2000;                                               
  ipdata[1] = 0x2;                                                  
  ipdata[2] = ndj;                                                  
  ipdata[3] = 0x0;                                                  
  g6_set_ipdata(devid,ipdata);                                      
                                                                    
  ni = 20;                                                    
  nd = 6;                                                    
  ipdata[0] = 0x3002;                                               
  ipdata[1] = 0x2;                                                  
  ipdata[2] = ni;                                                   
  ipdata[3] = nd;                                                   
  g6_set_ipdata(devid,ipdata);                                      
                                                                    
  for(j=0;j<n;j++){                                             

    xj = ((unsigned int) ((x[j][0] + ((100.0)/2.0)) * (pow(2.0,(double)32)/(100.0)) + 0.5)) & 0xffffffff;
    yj = ((unsigned int) ((x[j][1] + ((100.0)/2.0)) * (pow(2.0,(double)32)/(100.0)) + 0.5)) & 0xffffffff;
    zj = ((unsigned int) ((x[j][2] + ((100.0)/2.0)) * (pow(2.0,(double)32)/(100.0)) + 0.5)) & 0xffffffff;
    if(m[j] == 0.0){                                         
      mj = 0;                                                
    }else if(m[j] > 0.0){                                    
      mj = (((int)(pow(2.0,8.0)*log(m[j]*(pow(2.0,95.38)/(1.220703125e-04)))/log(2.0))) & 0x7fff) | 0x8000;
    }else{                                                 
      mj = (((int)(pow(2.0,8.0)*log(-m[j]*(pow(2.0,95.38)/(1.220703125e-04)))/log(2.0))) & 0x7fff) | 0x18000;
    }                                                      
                                                                    
    nword = 4;                                                      
    jpdata[0] = 0xffc00;                                            
    jpdata[1] = 1*j+0;                 
    jpdata[2] = 0x0 | ((0xffffffff & xj) << 0) ;  
    jpdata[3] = 0x0 | ((0xffffffff & yj) << 0) | ((0xffffffff & zj) << 32) | ((0x1ffff & mj) << 64) ;  
    g6_set_jpdata(devid,nword,jpdata);                              
                                                                    
  }                                                                 

  for(i=0;i<n;i+=npipe){                                              
    if((i+npipe)>n){                                                  
      nn = n - i;                                                     
    }else{                                                            
      nn = npipe;                                                     
    }                                                                 
    for(ii=0;ii<nn;ii++){                                             
      xi = ((unsigned int) ((x[i+ii][0] + ((100.0)/2.0)) * (pow(2.0,(double)32)/(100.0)) + 0.5)) & 0xffffffff;
      yi = ((unsigned int) ((x[i+ii][1] + ((100.0)/2.0)) * (pow(2.0,(double)32)/(100.0)) + 0.5)) & 0xffffffff;
      zi = ((unsigned int) ((x[i+ii][2] + ((100.0)/2.0)) * (pow(2.0,(double)32)/(100.0)) + 0.5)) & 0xffffffff;
      if(eps2 == 0.0){                                         
        ieps2 = 0;                                                
      }else if(eps2 > 0.0){                                    
        ieps2 = (((int)(pow(2.0,8.0)*log(eps2*((pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))))/log(2.0))) & 0x7fff) | 0x8000;
      }else{                                                 
        ieps2 = (((int)(pow(2.0,8.0)*log(-eps2*((pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))))/log(2.0))) & 0x7fff) | 0x18000;
      }                                                      
      ipdata[0] = 0x0 | (ii<<4);                                     
      ipdata[1] = 4;                                            
      ipdata[2] = 0xffffffff & xi;          
      ipdata[3] = 0xffffffff & yi;          
      ipdata[4] = 0xffffffff & zi;          
      ipdata[5] = 0x1ffff & ieps2;          
      g6_set_ipdata(devid,ipdata);                                  
    }                                                               
                                                                    
    ipdata[0] = 0x4000;                                             
    ipdata[1] = 0x1;                                                
    ipdata[2] = 1*n;                                     
    g6_set_ipdata(devid,ipdata);                                    
                                                                    
    nword = ni * nd;                                                
    retword = g6_get_fodata(devid,nword,fodata);                    
                                                                    
    for(ii=0;ii<nn;ii++){                                           
      sx = ((long long int)fodata[1+nd*ii] << 32)
           | (long long int)fodata[0+nd*ii];                     
      sy = ((long long int)fodata[3+nd*ii] << 32)
           | (long long int)fodata[2+nd*ii];                     
      sz = ((long long int)fodata[5+nd*ii] << 32)
           | (long long int)fodata[4+nd*ii];                     
      a[i+ii][0] = ((double)(sx<<0))*(-(pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))*(pow(2.0,23.0))/(pow(2.0,95.38)/(1.220703125e-04)))/pow(2.0,0.0);
      a[i+ii][1] = ((double)(sy<<0))*(-(pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))*(pow(2.0,23.0))/(pow(2.0,95.38)/(1.220703125e-04)))/pow(2.0,0.0);
      a[i+ii][2] = ((double)(sz<<0))*(-(pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))*(pow(2.0,23.0))/(pow(2.0,95.38)/(1.220703125e-04)))/pow(2.0,0.0);
    }                                                               
                                                                    
  }                                                                   
}                                                                   
