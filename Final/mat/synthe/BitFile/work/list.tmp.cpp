# 1 "list.tmp"
# 1 "<built-in>"
# 1 "<\245\263\245\336\245\363\245\311\245\351\245\244\245\363>"
# 1 "list.tmp"
-- 2004/06/02 16:30 *** ltof : BRAM table must be nstage>1 ***
-- for matsubayashi simulation
# 39 "list.tmp"
--(1.220703125e-04) 0xdf61

/NPIPE 20
/NVMP 1

/JPSET xj,0,0,31,x[][0],ufix,32,(pow(2.0,(double)32)/(100.0)),((100.0)/2.0)
/JPSET yj,0,32,63,x[][1],ufix,32,(pow(2.0,(double)32)/(100.0)),((100.0)/2.0)
/JPSET zj,0,64,95,x[][2],ufix,32,(pow(2.0,(double)32)/(100.0)),((100.0)/2.0)
/JPSET mj,0,96,112,m[],log,17,8,(pow(2.0,95.38)/(1.220703125e-04))
/IPSET xi,x[][0],ufix,32,(pow(2.0,(double)32)/(100.0)),((100.0)/2.0)
/IPSET yi,x[][1],ufix,32,(pow(2.0,(double)32)/(100.0)),((100.0)/2.0)
/IPSET zi,x[][2],ufix,32,(pow(2.0,(double)32)/(100.0)),((100.0)/2.0)
/IPSET ieps2,eps2,log,17,8,((pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0)))
/FOSET sx,a[][0],fix,64,(-(pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))*(pow(2.0,23.0))/(pow(2.0,95.38)/(1.220703125e-04)))
/FOSET sy,a[][1],fix,64,(-(pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))*(pow(2.0,23.0))/(pow(2.0,95.38)/(1.220703125e-04)))
/FOSET sz,a[][2],fix,64,(-(pow(2.0,(double)32)/(100.0))*(pow(2.0,(double)32)/(100.0))*(pow(2.0,23.0))/(pow(2.0,95.38)/(1.220703125e-04)))
/VALSET fx_ofst,0x9700,0,16
/VALSET fy_ofst,0x9700,0,16
/VALSET fz_ofst,0x9700,0,16
/DATASET fx_ofst,01001011100000000,0,16
/DATASET fy_ofst,01001011100000000,0,16
/DATASET fz_ofst,01001011100000000,0,16

void force_gravity_on_emulator(x,m,eps2,a,n)
        double x[][3]; double m[]; double eps2; double a[][3]; int n;
{
  pg_rundelay(11);
  pg_fix_addsub(SUB,xi,xj,xij,32,1);
  pg_fix_addsub(SUB,yi,yj,yij,32,1);
  pg_fix_addsub(SUB,zi,zj,zij,32,1);
  pg_conv_ftol(xij,dx,32,17,8,1);
  pg_conv_ftol(yij,dy,32,17,8,1);
  pg_conv_ftol(zij,dz,32,17,8,1);

  pg_pdelay(dx,dxr,17,4);
  pg_pdelay(dy,dyr,17,4);
  pg_pdelay(dz,dzr,17,4);

  pg_log_shift(1,dx,x2,17);
  pg_log_shift(1,dy,y2,17);
  pg_log_shift(1,dz,z2,17);

  pg_pdelay(ieps2,ieps2r,17,2);
  pg_log_unsigned_add_itp( x2,y2,x2y2,17,8,1,6);
  pg_log_unsigned_add_itp(z2,ieps2r,z2e2,17,8,1,6);
  pg_log_unsigned_add_itp( x2y2,z2e2,r2,17,8,1,6);

  pg_log_shift(-1,r2,r1,17);
  pg_log_muldiv(MUL,r2,r1,r3,17,1);

  pg_pdelay(mj,mjr,17,5);
  pg_log_muldiv(DIV,mjr,r3,mf,17,1);

  pg_log_muldiv(MUL,mf,dxr,fx,17,1);
  pg_log_muldiv(MUL,mf,dyr,fy,17,1);
  pg_log_muldiv(MUL,mf,dzr,fz,17,1);

  pg_log_muldiv(SDIV,fx,fx_ofst,fxo,17,1);
  pg_log_muldiv(SDIV,fy,fy_ofst,fyo,17,1);
  pg_log_muldiv(SDIV,fz,fz_ofst,fzo,17,1);

  pg_conv_ltof(fxo,ffx,17,8,57,2);
  pg_conv_ltof(fyo,ffy,17,8,57,2);
  pg_conv_ltof(fzo,ffz,17,8,57,2);
  pg_fix_accum(ffx,sx,57,64,1,10);
  pg_fix_accum(ffy,sy,57,64,1,10);
  pg_fix_accum(ffz,sz,57,64,1,10);
}
