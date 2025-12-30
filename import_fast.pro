function ntohl,data,i
  return,ulong(uint(data[i,*]))*65536+uint(data[i+1,*])
end
pro import_fast
  t0=2019.0; Range Zero - TC converted into seconds but counted from timer startup. First data point which sees dynamic acceleration is first point after this time
;  data=read_binary('ouf013.sds',data_t=2,endian='big')
;  datapower=reform(data,5,n_elements(data)/5)
;  seqpower=ntohl(datapower,0)
;  tcpower=fix_tc(/sec,ntohl(datapower,2))-t0
  swindow,0
  device,dec=1
  data=read_binary('RKTO0620_010_00.sds',data_t=2,endian='big')
  help,data
  data=reform(data,17,n_elements(data)/17)
  seq=ntohl(data,0)
  ;_T_ime _c_ount of the _M_PU6050 sensor, converted to seconds from range 0
  tcm=fix_tc(/sec,ntohl(data,2))-t0
  ;_M_PU6050 _A_ccelerometer _X_ raw data
  max=data[ 4,*]
  ;_M_PU6050 _A_ccelerometer _Y_ raw data
  may=data[ 5,*]
  ;_M_PU6050 _A_ccelerometer _Z_ raw data
  maz=data[ 6,*]
  ;_M_PU6050 _G_yro _X_ raw data
  mgx=data[ 7,*]
  ;_M_PU6050 _G_yro _X_ raw data
  mgy=data[ 8,*]
  ;_M_PU6050 _G_yro _X_ raw data
  mgz=data[ 9,*]
  ;_M_PU6050 _T_emperature raw data
  mt =data[10,*]
  ;_H_ighAcc _X_ raw data
  hx=data[11,*] mod 4096
  ;_H_ighAcc _Y_ raw data
  hy=data[12,*] mod 4096
  ;_H_ighAcc _Z_ raw data
  hz=data[13,*] mod 4096
;  openw,ouf,'RKTO0620_fast.csv',/get_lun
;  printf,ouf,'    seq,           tc,   max,   may,   maz,   mgx,   mgy,   mgz,    mt,    hx,    hy,    hz'
;  printf,ouf,format='(%"%7d,%13.7f,%6d,%6d,%6d,%6d,%6d,%6d,%6d,%6d,%6d,%6d")',transpose([[[double(seq)]],[[tcm]],[[max]],[[may]],[[maz]],[[mgx]],[[mgy]],[[mgz]],[[mt]],[[hx]],[[hy]],[[hz]]],[2,1,0])
;  free_lun,ouf
  ;_T_ime _C_ount of the _M_PU6050 sensor readout finish
  tcm1=fix_tc(/sec,ntohl(data,14))-t0
  ;The numerator of the fraction is my best estimate of true measurable acceleration of gravity at launch site, in m/s^2, taking
  ;into account altitude above geoid, slab gravity, and centrifugal force from rotation of the Earth. The denominator is the 
  ;measured total acceleration using the nameplate sensitivity and 1g=10m/s^2 exactly (so we expect a bit of error)
  ;phyrange=160.0d *9.79280914d/10.2654d
  ;nameplate sensitivity of the accelerometers
  phyrange=16d*(9.80665d);*9.79280914/10.2654
  dnrange=32768.0
  ;Numerator is number of roll rotations measured on the way up before despin measured by the compass, denominator is same measured
  ;by gyroscope. The rest is the nameplate rotation sensitivity
  phygrange=2000.0*(218.0/216.25)/360.0;rev/sec
  dngrange=32768.0
  ;Rocket was floating throug space at an acceleration indistinguishable from zero G during this range time
  t0g=[130,470]
  w0g=where(tcm gt t0g[0] and tcm lt t0g[1])
  phyrangeh=2000;
  dnrangeh=2048
  ;_H_ighacc _X_ _m_ean during zero-g coast
  hxm=mean(hx[w0g])
  ;_H_ighacc _Y_ _m_ean during zero-g coast
  hym=mean(hy[w0g])
  ;_H_ighacc _Z_ _m_ean during zero-g coast
  hzm=mean(hz[w0g])
  print,"hm",hxm,hym,hzm
  print,"hs",stdev(hx[w0g]),stdev(hy[w0g]),stdev(hz[w0g])
  
  ;Attempt to find temperature coefficients of acceleration bias in each axis
  ;First column of printout is label
  ;Second is constant coefficient
  ;Third is linear coefficient
  ;Fourth is stdev of all zero-g data
  ;Fifth is stdev of residual from linear fit
  ;Sixth is r^2 coefficient, fraction of stdev explained by fit
  plot,tcm,mt
  !p.multi=[0,3,2]
  maxf=linfit(mt[w0g],max[w0g],yfit=yfit) & print,"max || ",maxf[0],"||",maxf[1],"||",stdev(max[w0g]),"||",stdev(yfit-max[w0g]),"||",1-(stdev(yfit-max[w0g])/stdev(max[w0g]))
;  plot,mt[w0g],max[w0g],psym=3,/ynoz,charsize=2,xtitle='Temperature DN',ytitle='X acceleration DN'
;  oplot,mt[w0g],yfit,color='0000ff'x
  mayf=linfit(mt[w0g],may[w0g],yfit=yfit) & print,"may || ",mayf[0],"||",mayf[1],"||",stdev(may[w0g]),"||",stdev(yfit-may[w0g]),"||",1-(stdev(yfit-may[w0g])/stdev(may[w0g]))
;  plot,mt[w0g],may[w0g],psym=3,/ynoz,charsize=2,xtitle='Temperature DN',ytitle='Y acceleration DN'
;  oplot,mt[w0g],yfit,color='0000ff'x
  mazf=linfit(mt[w0g],maz[w0g],yfit=yfit) & print,"maz || ",mazf[0],"||",mazf[1],"||",stdev(maz[w0g]),"||",stdev(yfit-maz[w0g]),"||",1-(stdev(yfit-maz[w0g])/stdev(maz[w0g]))
;  plot,mt[w0g],maz[w0g],psym=3,/ynoz,charsize=2,xtitle='Temperature DN',ytitle='Z acceleration DN'
;  oplot,mt[w0g],yfit,color='0000ff'x
  
  ;Same for gyro coefficients
  mgxf=linfit(mt[w0g],mgx[w0g],yfit=yfit) & print,"mgx || ",mgxf[0],"||",mgxf[1],"||",stdev(mgx[w0g]),"||",stdev(yfit-mgx[w0g]),"||",1-(stdev(yfit-mgx[w0g])/stdev(mgx[w0g]))
;  plot,mt[w0g],mgx[w0g],psym=3,/ynoz,charsize=2,xtitle='Temperature DN',ytitle='X rotation rate DN'
;  oplot,mt[w0g],yfit,color='0000ff'x
  mgyf=linfit(mt[w0g],mgy[w0g],yfit=yfit) & print,"mgy || ",mgyf[0],"||",mgyf[1],"||",stdev(mgy[w0g]),"||",stdev(yfit-mgy[w0g]),"||",1-(stdev(yfit-mgy[w0g])/stdev(mgy[w0g]))
;  plot,mt[w0g],mgy[w0g],psym=3,/ynoz,charsize=2,xtitle='Temperature DN',ytitle='Y rotation rate DN'
;  oplot,mt[w0g],yfit,color='0000ff'x
  mgzf=linfit(mt[w0g],mgz[w0g],yfit=yfit) & print,"mgz || ",mgzf[0],"||",mgzf[1],"||",stdev(mgz[w0g]),"||",stdev(yfit-mgz[w0g]),"||",1-(stdev(yfit-mgz[w0g])/stdev(mgz[w0g]))
;  plot,mt[w0g],mgz[w0g],psym=3,/ynoz,charsize=2,xtitle='Temperature DN',ytitle='Z rotation rate DN'
;  oplot,mt[w0g],yfit,color='0000ff'x
  
  ;Use the constant coefficient to subtract off the sensor zero-g bias. We will do the linear as well, just because it's there. Scale the 
  ;measurements to physical units based on phyrange
  ;_M_PU6050 _A_cceleration _X_ axis _P_hysical units (m/s^2)
  maxp= (max-poly(mt,maxf))*phyrange/dnrange
  ;_M_PU6050 _A_cceleration _Y_ axis _P_hysical units (m/s^2)
  mayp= (may-poly(mt,mayf))*phyrange/dnrange
  ;_M_PU6050 _A_cceleration _Z_ axis _P_hysical units (m/s^2)
  mazp= (maz-poly(mt,mazf))*phyrange/dnrange
  ;_M_PU6050 _G_yroscope _X_ axis _P_hysical units (rev/s)
  mgxp= (mgx-poly(mt,mgxf))*phygrange/dngrange
  ;_M_PU6050 _G_yroscope _Y_ axis _P_hysical units (rev/s)
  mgyp= (mgy-poly(mt,mgyf))*phygrange/dngrange
  ;_M_PU6050 _G_yroscope _Z_ axis _P_hysical units (rev/s)
  mgzp= (mgz-poly(mt,mgzf))*phygrange/dngrange
  matp=sqrt(maxp^2+mayp^2+mazp^2)
  mgtp=sqrt(mgxp^2+mgyp^2+mgzp^2)
  ;Plot rotation rate around each axis and total in rev/s
  print,"Nameplate sensitivity in rev/s: ",2000.0/360.0
  !p.multi=0
  xrange=[0,1000]
  plot,tcm, mgtp,xrange=xrange,yrange=[-phygrange,phygrange],xtitle='Range time s',ytitle='Rotation rate rev/sec',/ys
  oplot,tcm,mgxp,color='0000ff'x
  oplot,tcm,mgyp,color='00ff00'x
  oplot,tcm,mgzp,color='ff0000'x
  ;_H_ighacc _X_ _P_hysical (m/s^2)  
  hxp=(hx-hxm)*phyrangeh/dnrangeh
  ;_H_ighacc _Y_ _P_hysical (m/s^2)  
  hyp=(hy-hym)*phyrangeh/dnrangeh
  ;_H_ighacc _Z_ _P_hysical (m/s^2)  
  hzp=(hz-hzm)*phyrangeh/dnrangeh
  
  
  ;Integrate velocity and position traveled along Z axis (rocket nose-to-tail axis) using derived physical calibration and
  ;simple 1G subtraction - Variables are named 1s because originally it was just during the first 1 second of flight
  ;_W_here _1s_ - Time from launch to +78s, encompassing spinup via fins through spindown via yoyo, but before 
  ;stabilization by ACS and rotation to sun-point
  w1s=where(tcm gt -1 and tcm lt 78)
  ;_w_here for _m_ean on ground
  wm=where(tcm gt -5 and tcm lt 0)
  ;_M_PU6050 _A_cceleration _Z_ axis _M_ean on ground in DN
  mazm_onground=mean(maz[wm])
  ;_M_PU6050 _A_cceleration _Z_ axis during boost up to spindown (m/s^2) - calculated by subtracting mean before-launch
  ;Z acceleration in DN from data during boost, then converting to physical units 
  maz_1s=-(maz[w1s]-mazm_onground)*phyrange/dnrange
  ;_T_ime _C_ount of _M_PU6050 data during boost
  tcm_1s=tcm[w1s]
  ;_d_ifferential of TCM_1s
  dtcm_1s=tcm_1s-shift(tcm_1s,1)
  plot,tcm_1s[1:-1],dtcm_1s[1:-1],/ynoz,charsize=2,yrange=[0,0.005]
  dtcm_1s[0]=dtcm_1s[1]   ;Just use the first delta as the delta for the whole series
  
  ;Numerical integrate using trapezoidal rule to get speed from acceleration
  ;_d_ifferential _M_PU6050 _A_cceleration _Z_ axis during boost
  dmaz_1s=maz_1s+shift(maz_1s,1)
  dmaz_1s[0]=0
  mvz_1s=0.5*total(/c,dtcm_1s*dmaz_1s)
  plot,tcm_1s,mvz_1s,xrange=[0,1],xtitle='Range time s',ytitle='Z spd m/s'
  
  ;Numerical integrate using trapezoidal rule to get distance from speed
  ;_d_ifferential _M_PU6050 _R_vector _Z_ axis during boost
  dmvz_1s=mvz_1s+shift(mvz_1s,1)
  dmvz_1s[0]=0
  mrz_1s=0.5*total(/c,dtcm_1s*dmvz_1s)
  plot,tcm_1s,mrz_1s,xrange=[-0.1,0.1],xtitle='Range time s',ytitle='Z dist m'
  
  ;Plot of timestep, verify that fast recording was used throughout flight
  dtc=tcm-shift(tcm,1)
  dtc[0]=dtc[1]
  plot,tcm,dtc*1000,yrange=[0,50],xtitle='Range time s',ytitle='Measurement time step, ms',/xs,/ys
  
  ;Plot of total HighAcc acceleration
  plot,tcm,sqrt(hxp^2+hyp^2+hzp^2),xrange=[0,100],xtitle='Range time s',ytitle='Total highacc, m/s^2',/xs,/ys


  ;Integrate rotation rate
  mgz_1s=mgzp[w1s]
  dmgz_1s=mgz_1s+shift(mgz_1s,1)
  mvzg_1s=0.5*total(/c,dtcm_1s*dmgz_1s)
  plot,tcm_1s,mvzg_1s,xrange=[0,78]
  
  data=read_binary('RKTO0620_00a_00.sds',data_t=2,endian='big')
  help,data
  data=reform(data,12,n_elements(data)/12)
  seq=ntohl(data,0)
  tcp=fix_tc(/sec,ntohl(data,2))-t0
  traw=data[ 4,*]
  praw=ntohl(data,5)
  t=data[ 7,*]
  p=ntohl(data,8)
  plot,tcp,p,xrange=xrange
;  openw,ouf,'RKTO0620_bmp.csv',/get_lun
;  printf,ouf,'    seq,           tc, traw,  praw,   t,    p'
;  printf,ouf,format='(%"%7d,%13.7f,%5d,%6d,%4.1f,%5d")',transpose([[[double(seq)]],[[tcp]],[[traw]],[[praw]],[[double(t)/10]],[[p]]],[2,1,0])
;  free_lun,ouf
  data=read_binary('RKTO0620_004_00.sds',data_t=2,endian='big')
  help,data
  data=reform(data,7,n_elements(data)/7)
  seq=ntohl(data,0)
  tcb=fix_tc(/sec,ntohl(data,2))-t0
  bx=data[ 4,*]
  by=data[ 6,*]
  bz=data[ 5,*]
  openw,ouf,'RKTO0620_hmc.csv',/get_lun
  printf,ouf,'    seq,           tc,   bx,   by,   bz'
  printf,ouf,format='(%"%7d,%13.7f,%5d,%5d,%5d")',transpose([[[double(seq)]],[[tcb]],[[bx]],[[by]],[[bz]]],[2,1,0])
  free_lun,ouf
  hrange=[0,575]
  h2range=[600,900]
  whrange=where(tcb gt hrange[0] and tcb lt hrange[1])
  wh2range=where(tcb gt h2range[0] and tcb lt h2range[1])
  plot,tcb,bx,xrange=hrange,/xs,yrange=[min([bx,by,bz]),max([bx,by,bz])],psym=3
  oplot,tcb,bx,color='0000ff'x,psym=3
  oplot,tcb,by,color='00ff00'x,psym=3
  oplot,tcb,bz,color='ff0000'x,psym=3
  ellipsoid_fit,bx[whrange],by[whrange],bz[whrange],center=center,radii=radii,evec=evec
  ellipsoid_fit,bx[wh2range],by[wh2range],bz[wh2range],center=center2,radii=radii2,evec=evec2
  hbx=center[0]
  hby=center[1]
  hbz=center[2]
  bb=rebin(Radii,3,3)*evec
  lat0=!dtor*32.417995
  lon0=-106.32016*!dtor
  alt0=1209
  bsurf0=wmm2010([lat0,lon0,alt0],2013.8)
  bsurf=sqrt(total(bsurf0^2)) ;need the field magnitude
  aa=bb ## invert(evec) /bsurf
  bdn=double([[transpose(bx)],[transpose(by)],[transpose(bz)]])
  bp=invert(aa) ## (bdn-rebin(center,size(bdn,/dim)))
  bxp=bp[*,0]
  byp=bp[*,1]
  bzp=bp[*,2]
  !p.multi=[0,2,2]
  plot,bp[whrange,0],bp[whrange,1],xrange=[-1,1]*bsurf,yrange=[-1,1]*bsurf,xtitle='x',ytitle='y',/iso,psym=3
  plot,bp[whrange,0],bp[whrange,2],xrange=[-1,1]*bsurf,yrange=[-1,1]*bsurf,xtitle='x',ytitle='z',/iso,psym=3
  plot,bp[whrange,1],bp[whrange,2],xrange=[-1,1]*bsurf,yrange=[-1,1]*bsurf,xtitle='y',ytitle='z',/iso,psym=3
  !p.multi=0
  swindow,1
  device,dec=0
  loadct,39
  plot,bxp,byp,/iso,color=0,background=255,/nodata
  xrange=[0,78]
  wf=where(tcb gt xrange[0] and tcb lt xrange[1])
  plots,bxp[wf],byp[wf],color=lindgen(n_elements(wf))*255L/n_elements(wf),psym=-1
  
 ; how many times did we spin?
  bxp_1s=bxp[wf]
  byp_1s=byp[wf]
  ;
  w=where(bxp_1s gt 0 and byp_1s*shift(byp_1s,1) lt 0,count)
  bxp_count=bxp_1s[w]
  byp_count=byp_1s[w]
  
  plot,tcb[wf],bxp_1s gt 0, yrange=[-1,2]
  oplot,tcb[wf],(byp_1s * shift(byp_1s,1))/abs(byp_1s * shift(byp_1s,1)),color=254
  
  ;initial conditions
  el0=86.6*!dtor
  az0=352*!dtor
  ;point the nose (p_b) at the sky (p_r), gravity vector (t_b) toward local vertical (t_r)
  w=max(where(tcb lt 1.0))
  t_b=normalize_grid(transpose(bp[w,*]))
  zz=[cos(lat0)*cos(lon0),cos(lat0)*sin(lon0),sin(lat0)]
  t_r=zz
  w=max(where(tcm lt -1.0))
  t_b=normalize_grid([maxp[w],mayp[w],mazp[w]])
  ee=normalize_grid(crossp_grid([0,0,1],zz))
  nn=normalize_grid(crossp_grid(zz,ee))
  p_r=zz*sin(el0)+nn*cos(el0)*cos(az0)+ee*cos(el0)*sin(az0)
  p_b=[0,0,-1]
  b_i=normalize_grid(bsurf0[0]*nn+bsurf0[1]*ee-bsurf0[2]*zz)
  M=point_toward(p_r=transpose(p_r),p_b=transpose(p_b),t_r=transpose(t_r),t_b=transpose(t_b))
  print,m
  q=quat_to_mtx(/inv,m)
  print,q
  nose_i=M ## transpose([0,0,-1])
  print,"Elevation: ",asin(dotp(nose_i,zz))*!radeg
  print,"Azimuth:   ",atan(dotp(nose_i,ee),dotp(nose_i,nn))*!radeg
  stop
end