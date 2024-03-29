load "/home/sunming/data5/cuixy/script/ncl_func/cal_WFsf.ncl"
;--------------------------------------------------------
; draw uwind anomaly in shading, streamfunction
; anomaly in contour and OLR anomaly in contour. 
; waf vector
; This is for test sig. 95% by monte carlo method.
; time: 2023-12-18
; 2.5x2.5.
;--------------------------------------------------------

  ddir   = "/home/sunming/data5/cuixy/global_jets/data"
  pdir   = "/home/sunming/data5/cuixy/global_jets/plot"
  rmmdir = "/home/sunming/data5/cuixy/data/clim_indices/rmm.74toRealtime.csv"

  phidir = ddir+"/"+"ERA5_daily_anom_phi250_1979-2022_2.5x2.5.nc"
  udir   = ddir+"/"+"ERA5_daily_anom_u250_1979-2022_2.5x2.5.nc"
  olrdir = ddir+"/"+"olr_daily_anom_1979-2022.nc"
  ucdir  = ddir+"/"+"ERA5_daily_u250_1979-2022.nc"
  ;sigdir = ddir+"/"+"monte_carlo/phiu_sig_phase15.nc"
  usigdir = ddir+"/"+"monte_carlo/u_sig_phase15.nc"
  phisigdir = ddir+"/"+"monte_carlo/phi_sig_phase15.nc"

  latmin = -30
  latmax = 90
;--------------------------------------------------------
; u250
;--------------------------------------------------------
  f    = addfile(ucdir,"r")

  time = f->time
  TIME = cd_calendar(time, 0)
  mon  = toint(TIME(:,1))
  nt   = ind(mon.eq.12.or.mon.eq.1.or.mon.eq.2)

  uc    = dim_avg_n_Wrap(f->u(nt,0,:,:),0)

;contour plot
  resc = True
  resc@gsnFrame     = False
  resc@gsnDraw      = False
  resc@gsnMaximize  = False
  resc@gsnAddCyclic = True
  resc@gsnContourNegLineDashPattern = 1
  resc@gsnLeftString      = ""
  resc@gsnRightString     = ""
  resc@cnMonoLineColor    = True
  resc@cnLinesOn          = True
  resc@cnLineLabelsOn     = False
  resc@cnLineColor        = "magenta"
  resc@cnLineThicknessF   = 3.0
  resc@cnInfoLabelPerimOn = False
  resc@cnInfoLabelOn      = False
  resc@cnLevelSelectionMode = "Explicitlevels"
  resc@cnLevels      = (/30.,40./)

  delete([/time,f,TIME,mon,nt/])

  print("draw clim.u complete. "+ systemfunc("date"))
;--------------------------------------------------------
;; for calc WAF.
  u1dir = ddir+"/"+"ERA5_daily_u250_1979-2022_r2.5.nc"
  vdir = ddir+"/"+"ERA5_daily_v250_1979-2022_r2.5.nc"

  fu = addfile(u1dir,"r")
  fv = addfile(vdir,"r")

  u0 = fu->u(:,{250},{latmax:latmin},:)
  v0 = fv->v(:,{250},{latmax:latmin},:)

  time = u0&time
  lat  = u0&lat
  lon  = u0&lon

  TIME = cd_calendar(time,0)
  year = toint(TIME(:,0))
  mon  = toint(TIME(:,1))
  day  = toint(TIME(:,2))

  wgtl = filwgts_lanczos(201, 0, 1./100., -999., 1.)
  u0   := wgt_runave_n_Wrap(u0, wgtl, 0, 0)
  v0   := wgt_runave_n_Wrap(v0, wgtl, 0, 0)

;--------------------------------------------------------
; Main code.
;--------------------------------------------------------

  fphi = addfile(phidir,"r")
  fu   = addfile(udir,"r")
  fv   = addfile(vdir,"r")
  folr = addfile(olrdir,"r")

  olr  = folr->olr(time|:,lat|:,lon|:)
  phi  = fphi->phi(:,{latmax:latmin},:)
  u    = fu->u(:,{latmax:latmin},:)

  print("complete data selling "+ systemfunc("date"))
;-------------------------------------------------------
;; selling MJO.

  delim = ","
  rmmf  = asciiread(rmmdir,-1,"string")
  iyear = str_get_field(rmmf,1,delim)
  imon  = str_get_field(rmmf,2,delim)
  iday  = str_get_field(rmmf,3,delim)
  phaset = str_get_field(rmmf,6,delim)
  ampt   = str_get_field(rmmf,7,delim)

  iyear  := toint(iyear(1::))
  imon   := toint(imon(1::))
  iday   := toint(iday(1::))
  phaset := toint(phaset(1::))
  ampt   := tofloat(ampt(1::))

  amp   = new((/dimsizes(time)/),float)
  phase = new((/dimsizes(time)/),integer)
  amp   = 0.
  phase = 0

  do i = 0, dimsizes(time)-1
    nt = ind(iyear.eq.year(i).and.imon.eq.mon(i).and.iday.eq.day(i))
    amp(i)   = ampt(nt)
    phase(i) = phaset(nt)
    delete(nt)
  end do

  nn = ispan(0, dimsizes(time)-1, 1)
  amp!0   = "timeind"
  phase!0 = "timeind"
  amp&timeind   = nn
  phase&timeind = nn
  delete([/nn,ampt,phaset,iyear,imon,iday/])

  print("complete RMM selling "+ systemfunc("date"))
;-------------------------------------------------------------

  n1 = ind(year.eq.1979.and.mon.eq.12.and.day.eq.1)
  n2 = ind(year.eq.2022.and.mon.eq.2.and.day.eq.28)

  amp   := amp(n1:n2)
  phase := phase(n1:n2)
  mon   := mon(n1:n2)
  time  := time(n1:n2)

  nt     = ind(mon.eq.12.or.mon.eq.1.or.mon.eq.2)
  amp   := amp(nt)
  phase := phase(nt)

  delete(nt)
  ind_DJF = amp&timeind   ; indice of DJF between 1979-2022 DJF.
;----------------------------------------------------------------------
;; sig
  sigl = 0.05
  sigh = 0.95

  fsigphi = addfile(phisigdir,"r")
  fsigu   = addfile(usigdir,"r")
  m_value_phi = fsigphi->m_valuephi(:,:,:,::-1,:)
  m_value_u   = fsigu->m_valueu(:,:,:,::-1,:)

  m_valuephi  = new((/2,2,8,dimsizes(phi&lat),dimsizes(phi&lon)/),float) 
  m_valuephi  = 0.
  m_valueu  = new((/2,2,8,dimsizes(u&lat),dimsizes(u&lon)/),float) 
  m_valueu  = 0.

  nl  = toint(dimsizes(m_value_phi(:,0,0,0,0))*sigl) - 1
  nh  = toint(dimsizes(m_value_phi(:,0,0,0,0))*sigh) - 1
  m_valuephi(0,:,:,:,:) = m_value_phi(nl,:,:,:,:)
  m_valuephi(1,:,:,:,:) = m_value_phi(nh,:,:,:,:)

  m_valuephi = m_valuephi*10^(-6)

  nl = toint(dimsizes(m_value_u(:,0,0,0,0))*sigl) - 1
  nh = toint(dimsizes(m_value_u(:,0,0,0,0))*sigh) - 1
  m_valueu(0,:,:,:,:) = m_value_u(nl,:,:,:,:)
  m_valueu(1,:,:,:,:) = m_value_u(nh,:,:,:,:)

  delete([/m_value_phi,m_value_u/])
;----------------------------------------------------------------------
;; store lead-lag values for plotting. (-15 -10 ---- 15 20)
  llphi = new((/8,dimsizes(phi&lat),dimsizes(phi&lon)/),float)
  copy_VarCoords(phi(0,:,:), llphi(0,:,:))
  llphi = 0.

  llu = new((/8,dimsizes(u&lat),dimsizes(u&lon)/),float)
  copy_VarCoords(u(0,:,:), llu(0,:,:))
  llu = 0.

  llolr = new((/8,dimsizes(olr&lat),dimsizes(olr&lon)/),float)
  copy_VarCoords(olr(0,:,:), llolr(0,:,:))
  llolr = 0.

  lluw = new((/8,dimsizes(u&lat),dimsizes(u&lon)/),float)
  copy_VarCoords(u(0,:,:), lluw(0,:,:))
  lluw = 0.

  llvw = new((/8,dimsizes(u&lat),dimsizes(u&lon)/),float)
  copy_VarCoords(u(0,:,:), llvw(0,:,:))
  llvw = 0.

  prem = 25000./100000.
  nlati = ind(lat.gt.-10.and.lat.lt.10)

    ip = 5
    nt = ind(phase.eq.ip.and.amp.gt.1.)
    nind = ind_DJF(nt)
    do j = 0, 7
      ntt   = -15 + j*5
      nindd = nind + ntt
      llphi(j,:,:) = dim_avg_n(phi(nindd,:,:), 0)
      llu(j,:,:)   = dim_avg_n(u(nindd,:,:), 0)
      llolr(j,:,:) = dim_avg_n(olr(nindd,:,:), 0)
      um = dim_avg_n(u0(nindd,:,:), 0)
      vm = dim_avg_n(v0(nindd,:,:), 0)
      WAFuv = cal_WFsf(llphi(j,:,:),um,vm,phi&lat,phi&lon)
      WAFuv(:,nlati,:) = 0.
      lluw(j,:,:) = WAFuv(0,:,:)*prem
      llvw(j,:,:) = WAFuv(1,:,:)*prem
      delete([/ntt,nindd,WAFuv,um,vm/])
    end do
    delete([/ip,nt,nind/])

  llphi = llphi*10^(-6)

  print("complete calc leadlag data. "+ systemfunc("date"))
;----------------------------------------------------------------------
;; resources
  cmap = read_colormap_file("MPL_RdBu")
;shading u plot
  rest = True
  rest@gsnFrame           = False
  rest@gsnDraw            = False
  rest@gsnMaximize        = False
  rest@gsnAddCyclic       = True
  rest@gsnMajorLatSpacing = 15
  rest@gsnMajorLonSpacing = 30
  rest@gsnRightStringFontHeightF = 0.025 
  rest@gsnLeftStringFontHeightF = 0.025
  rest@gsnRightString = "~F21~250hPa_U_SF_WAF"
  rest@tmXTOn = False
  rest@tmYROn = False
  rest@tmXBLabelFont = 21
  rest@tmYLLabelFont = 21
  rest@tmXBLabelFontHeightF = 0.015
  rest@tmYLLabelFontHeightF = 0.015
  rest@mpFillOn        = False
  rest@mpFillDrawOrder = "Postdraw"
  rest@mpMinLatF   = -20
  rest@mpMaxLatF   = 90
  rest@mpMinLonF   = 100
  rest@mpMaxLonF   = 360
  rest@mpLandFillColor = "white"

  rest@cnFillOn               = True
  rest@cnFillPalette          = cmap(::-1,:)
  rest@cnLinesOn              = False
  rest@cnLineLabelsOn         = False
  rest@cnLevelSelectionMode   = "Manuallevels"
  rest@cnMinLevelValF         = -8.
  rest@cnMaxLevelValF         =  8.
  rest@cnLevelSpacingF        =  1.
  rest@cnLabelBarEndStyle     = "ExcludeOuterBoxes"
  rest@lbLabelBarOn           = False

; contour phi plot.
  resphi = True
  resphi@gsnDraw      = False
  resphi@gsnMaximize  = False
  resphi@gsnFrame     = False
  resphi@gsnAddCyclic = True
  resphi@gsnContourNegLineDashPattern = 1
  resphi@cnMonoLineColor    = True
  resphi@cnLinesOn          = True
  resphi@cnLineLabelsOn     = False
  resphi@cnLineColor        = "black"
  resphi@cnLineThicknessF   = 2.5
  resphi@cnInfoLabelPerimOn = False
  resphi@cnInfoLabelOn      = False
  resphi@cnLevelSelectionMode = "Explicitlevels"
  resphi@cnLevels      = (/-10,-8,-6,-4,-2,2,4,6,8,10/)

; contour olr plot.
  resolr = True
  resolr@gsnDraw      = False
  resolr@gsnMaximize  = False
  resolr@gsnFrame     = False
  resolr@gsnAddCyclic = True
  resolr@gsnContourNegLineDashPattern = 1
  resolr@cnMonoLineColor    = True
  resolr@cnLinesOn          = True
  resolr@cnLineLabelsOn     = False
  resolr@cnLineColor        = "green4"
  resolr@cnLineThicknessF   = 2.5
  resolr@cnInfoLabelPerimOn = False
  resolr@cnInfoLabelOn      = False
  resolr@cnLevelSelectionMode = "Explicitlevels"
  resolr@cnLevels      = (/-25,-20,-10,10,20,25/)

;; vector res.
  resw = True
  resw@gsnFrame     = False
  resw@gsnDraw      = False
  resw@gsnMaximize  = False
  resw@gsnAddCyclic = True
  resw@vcGlyphStyle            = "LineArrow"
  resw@vcLineArrowThicknessF   = 1.
;resw@vcMinDistanceF          = 0.01
  resw@vcRefMagnitudeF         = 1.5
  resw@vcRefLengthF            = 0.05
  resw@vcLineArrowColor        = "black"
  resw@vcRefAnnoOn             = False
  resw@vcRefAnnoString2On      = False
  resw@vcRefAnnoString1On      = False
  resw@vcRefAnnoPerimSpaceF    = 0.4
  resw@vcRefAnnoPerimOn        = False
  resw@vcRefAnnoFontHeightF    = 0.015
  resw@vcRefAnnoJust           = "BottomRight"
  resw@vcRefAnnoBackgroundColor = -1

  resP = True
  resP@gsnMaximize      = True
  resP@gsnFrame         = False
  resP@gsnDraw          = True
  resP@gsnPanelLabelBar = True
  resP@gsnPanelTop      = 0.98
  resP@gsnPanelBottom   = 0.02

  resP@pmLabelBarOrthogonalPosF = -0.005
  resP@pmLabelBarWidthF         = 0.75

  resP@lbLabelFont       = 21
  resP@lbTitleString     = "~F21~u anomaly (m/s)"
  resP@lbTitlePosition   = "Bottom"
  resP@lbTitleDirection  = "Across"
  resP@lbTitleFontHeightF= 0.01
  resP@lbBoxLinesOn      = True
  resP@gsnPanelRowSpec    = True
  resP@lbLabelFontHeightF = 0.012
  print("complete res. "+ systemfunc("date"))

  sres   = True 
  sres@cnLineDrawOrder    = "PostDraw"                    
  sres@gsnDraw            = False                          
  sres@gsnFrame           = False                        
  sres@cnLineLabelsOn     = False                              
  sres@cnLinesOn          = False                           
  sres@cnInfoLabelOn      = False
  sres@cnFillOn           = False                       
  sres@cnInfoLabelOn      = False
  sres@cnFillScaleF       = 0.1
  sres@gsnLeftString      =" "
  sres@gsnRightString     =" "
  sres@cnMonoFillColor    = True
  sres@cnFillColor        = "black"
  ;sres@cnLevels    = (/-0.1,0,0.1/) 

  opt = True
  opt@gsnShadeFillType   = "pattern"
  opt@gsnShadeHigh      = 10
  ;opt@gsnShadeMid        = 10
  opt@gsnShadeFillScaleF   = 1.

;----------------------------------------------------------------------
;; plot.
  wks = gsn_open_wks("eps", pdir+"/"+"u_shading_phi_contour_olr_contour_waf_vector")

  plott   = new(8,graphic)
  plotphi = plott
  plotolr = plott
  plotvc  = plott
  dum     = plott
  Label1 = (/"~F21~(a) phase 5 day -15","~F21~(b) phase 5 day -10",\
                              "~F21~(c) phase 5 day -5","~F21~(d) phase 5 day 0",\
                              "~F21~(e) phase 5 day 5","~F21~(f) phase 5 day 10",\
                              "~F21~(g) phase 5 day 15","~F21~(h) phase 5 day 20"/)

  do n = 0,7
    rest@gsnLeftString = "~F21~"+Label1(n)
    x = llu(n,:,:)
    y = llphi(n,:,:)
    xt = llu(n,:,:)
    xt = 0.
    do i = 0, dimsizes(lat)-1
      do j = 0, dimsizes(lon)-1
        if(x(i,j).lt.m_valueu(0,0,n,i,j).or.x(i,j).gt.m_valueu(1,0,n,i,j)) then
          xt(i,j) = 2.
        else
          xt(i,j) = -2.
        end if
      end do
    end do
    y = mask(y,y.le.m_valuephi(0,1,n,:,:).or.y.ge.m_valuephi(1,1,n,:,:),True)
    plott(n)   = gsn_csm_contour_map(wks, x, rest)
    plotphi(n) = gsn_csm_contour(wks, y, resphi)
    plotolr(n) = gsn_csm_contour(wks, llolr(n,:,:), resolr)
    if (n.eq.7)then
      resw@vcRefAnnoOn             = True
      resw@vcRefAnnoString1On      = True
      resw@vcRefAnnoString1        = "$VMG$" +" ~F21~m~S~2~N~/s~S~2~N~"
      resw@vcRefAnnoOrthogonalPosF = 0.2
      resw@vcRefAnnoParallelPosF   = 1.0  
    end if
    plotvc(n)  = gsn_csm_vector(wks, lluw(n,::4,::4), llvw(n,::4,::4), resw)
    plotu  = gsn_csm_contour(wks, uc, resc)
    dum(n)   = gsn_csm_contour(wks,xt,sres)
    dum(n)   = gsn_contour_shade(dum(n),1.9,-999.,opt)
    overlay(plott(n),dum(n))
    overlay(plott(n),plotvc(n))
    overlay(plott(n),plotu)
    overlay(plott(n),plotphi(n))
    overlay(plott(n),plotolr(n))
    ;overlay(plott(n),dum(n))
  end do
  gsn_panel(wks, (/plott(0),plott(4),plott(1),plott(5),\
                plott(2),plott(6),plott(3),plott(7)/), (/2,2,2,2/), resP)

  ;i = 1
  ;do while (i.eq.1)
  ;  i = 1
  ;end do
