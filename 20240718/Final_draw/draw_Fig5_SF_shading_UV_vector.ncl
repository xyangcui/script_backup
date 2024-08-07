;--------------------------------------------------------
; draw uwind anomaly in shading, streamfunction
; anomaly in contour and OLR anomaly in contour. 
; waf vector
; This is for test sig. 95% by monte carlo method.
; time: 2023-12-18
; 2.5x2.5.
;--------------------------------------------------------


;;----------------------------------------------------------
function siglevel(ovalue,mvalue)
begin

  rv = ovalue
  lati = rv&lat
  loni = rv&lon

  do i = 0, dimsizes(lati)-1
    do j = 0, dimsizes(loni)-1
      if(ovalue(i,j).lt.mvalue(0,i,j).or.ovalue(i,j).gt.mvalue(1,i,j)) then
        rv(i,j) = 2.
      else
        rv(i,j) = -2.
      end if
    end do
  end do

  return rv

end

  ddir   = "/home/sunming/data5/cuixy/global_jets/data"
  pdir   = "/home/sunming/data5/cuixy/global_jets/plot"
  rmmdir = "/home/sunming/data5/cuixy/data/clim_indices/rmm.74toRealtime.csv"

  phidir = ddir+"/"+"ERA5_daily_anom_phi250_1979-2022_2.5x2.5.nc"
  udir   = ddir+"/"+"ERA5_daily_anom_u250_1979-2022_2.5x2.5.nc"

  vdir   = ddir+"/"+"ERA5_daily_anom_v250_1979-2022_2.5x2.5.nc"

  olrdir = ddir+"/"+"olr_daily_anom_1979-2022.nc"
  ucdir  = ddir+"/"+"ERA5_daily_u250_1979-2022_r2.5.nc"

  sdir = "/home/sunming/data5/cuixy/global_jets/data/monte_carlo/Fig4_sf_uv_sig.nc"

  lats = -20
  latn =  60
  lonw =  0
  lone =  210

;--------------------------------------------------------
; u250
;--------------------------------------------------------
  f    = addfile(ucdir,"r")

  ut = f->u(:,0,:,:)
  time = f->time
  TIME = cd_calendar(time, 0)
  year = toint(TIME(:,0))
  mon  = toint(TIME(:,1))
  day  = toint(TIME(:,2))
  n1 = ind(year.eq.1979.and.mon.eq.12.and.day.eq.1)
  n2 = ind(year.eq.2022.and.mon.eq.3.and.day.eq.1)

  mon := mon(n1:n2)
  ut  := ut(n1:n2,:,:)
  nt = ind(mon.eq.12.or.mon.eq.1.or.mon.eq.2)
  uc = dim_avg_n_Wrap(ut(nt,:,:),0)

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
  resc@cnLineColor        = "magenta";magenta
  resc@cnLineThicknessF   = 2.5
  resc@cnInfoLabelPerimOn = False
  resc@cnInfoLabelOn      = False
  resc@cnLevelSelectionMode = "Explicitlevels"
  resc@cnLevels  = (/30.,45.,60.,75./)

  delete([/time,f,TIME,mon,nt,ut,n1,n2,year,day/])

  print("draw clim.u complete. "+ systemfunc("date"))
;--------------------------------------------------------
; Main code.
;--------------------------------------------------------

  fphi = addfile(phidir,"r")
  fu   = addfile(udir,"r")
  fv   = addfile(vdir,"r")
  folr = addfile(olrdir,"r")

  olr  = folr->olr(:,{lats:latn},{lonw:lone})
  phi  = fphi->phi(:,{lats:latn},{lonw:lone})
  u    = fu->u(:,{lats:latn},{lonw:lone})
  v    = fv->v(:,{lats:latn},{lonw:lone})

  time = phi&time
  TIME = cd_calendar(time, 0)
  year = toint(TIME(:,0))
  mon  = toint(TIME(:,1))
  day  = toint(TIME(:,2))

  print("complete data selling "+ systemfunc("date"))

  fsig = addfile(sdir,"r")
  mvalue1 = fsig->mvalue;(:,:,:,{lats:latn},{lonw:lone})
;-------------------------------------------------------
;; selling MJO.

  delim  = ","
  rmmf   = asciiread(rmmdir,-1,"string")
  iyear  = str_get_field(rmmf,1,delim)
  imon   = str_get_field(rmmf,2,delim)
  iday   = str_get_field(rmmf,3,delim)
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
;; store lead-lag values for plotting. (-15 -10 ---- 15 20)
  llphi = new((/2,dimsizes(phi&lat),dimsizes(phi&lon)/),float)
  copy_VarCoords(phi(0,:,:), llphi(0,:,:))
  llphi = 0.

  llu = new((/2,dimsizes(u&lat),dimsizes(u&lon)/),float)
  copy_VarCoords(u(0,:,:), llu(0,:,:))
  llu = 0.

  llv = new((/2,dimsizes(v&lat),dimsizes(v&lon)/),float)
  copy_VarCoords(v(0,:,:), llv(0,:,:))
  llv = 0.

  llolr = new((/2,dimsizes(olr&lat),dimsizes(olr&lon)/),float)
  copy_VarCoords(olr(0,:,:), llolr(0,:,:))
  llolr = 0.

  nt = ind(phase.eq.2.and.amp.gt.1.)
  nind  = ind_DJF(nt)
  ntt   = 3
  nindd = nind + ntt
  do ntt = 1,7
    nit = nind + ntt
    nindd := array_append_record(nindd, nit, 0)
    delete(nit)
  end do
  llphi(0,:,:) = dim_avg_n(phi(nindd,:,:), 0)
  llu(0,:,:)   = dim_avg_n(u(nindd,:,:), 0)
  llv(0,:,:)   = dim_avg_n(v(nindd,:,:), 0)
  llolr(0,:,:) = dim_avg_n(olr(nindd,:,:), 0)
  delete([/nt,nind,nindd/])

  nt = ind(phase.eq.6.and.amp.gt.1.)
  nind = ind_DJF(nt)
  nindd = nind + ntt
  do ntt = 1,7
    nit = nind + ntt
    nindd := array_append_record(nindd, nit, 0)
    delete(nit)
  end do
  llphi(1,:,:) = dim_avg_n(phi(nindd,:,:), 0)
  llu(1,:,:)   = dim_avg_n(u(nindd,:,:), 0)
  llv(1,:,:)   = dim_avg_n(v(nindd,:,:), 0)
  llolr(1,:,:) = dim_avg_n(olr(nindd,:,:), 0)
  delete([/nt,nind,ntt,nindd/])
  llolr = smth9_Wrap(llolr, 0.5, 0.25, False)
  llolr = smth9_Wrap(llolr, 0.5, 0.25, False)
  print("complete calc leadlag data. "+ systemfunc("date"))
;----------------------------------------------------------------------
;; resources
  cmap = read_colormap_file("MPL_RdBu")  ;MPL_RdBu
;shading u plot
  resu = True
  resu@gsnFrame           = False
  resu@gsnDraw            = False
  resu@gsnMaximize        = False
  resu@gsnAddCyclic       = False
  resu@gsnMajorLatSpacing = 15
  resu@gsnMajorLonSpacing = 30
  resu@gsnRightStringFontHeightF = 0.015 
  resu@gsnLeftStringFontHeightF  = 0.015

  resu@gsnRightStringOrthogonalPosF = 0.01
  resu@gsnLeftStringOrthogonalPosF  = 0.01

  resu@tmXTOn = False
  resu@tmYROn = False
  resu@tmXBLabelFont = 21
  resu@tmYLLabelFont = 21
  resu@tmXBLabelFontHeightF = 0.01
  resu@tmYLLabelFontHeightF = 0.01

  resu@mpMinLatF = lats
  resu@mpMaxLatF = latn
  resu@mpMinLonF = lonw
  resu@mpMaxLonF = lone
  resu@mpFillOn        = False
  resu@mpLandFillColor = "white"
  resu@mpGridAndLimbDrawOrder = "PostDraw"
  resu@mpGridLineColor        = "Gray60"

  resu@cnFillOn               = True
  resu@cnFillPalette          = cmap(::-1,:);(66:146,:)
  resu@cnLinesOn              = False
  resu@cnLineLabelsOn         = False
  resu@cnLevelSelectionMode   = "Manuallevels"
  resu@cnMinLevelValF         = -6.
  resu@cnMaxLevelValF         =  6.
  resu@cnLevelSpacingF        =  1.
  resu@cnLabelBarEndStyle     = "ExcludeOuterBoxes"
  resu@lbLabelBarOn           = False

; contour phi plot.
  cmap1 = read_colormap_file("BlueWhiteOrangeRed")
  resphi = True
  resphi@gsnDraw      = False
  resphi@gsnMaximize  = False
  resphi@gsnFrame     = False
  resphi@gsnAddCyclic = False
  resphi@gsnContourNegLineDashPattern = 1
  resphi@cnMonoLineColor    = True
  resphi@cnLinesOn          = True
  resphi@cnLineLabelsOn     = False
  resphi@cnLineColor        = "black"
  resphi@cnLineThicknessF   = 2.5
  resphi@cnInfoLabelPerimOn = False
  resphi@cnInfoLabelOn      = False
  resphi@cnLevelSelectionMode = "Explicitlevels"
  resphi@cnLevels      = (/-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10/)
; contour olr plot.
  resolr = True
  resolr@gsnDraw      = False
  resolr@gsnMaximize  = False
  resolr@gsnFrame     = False
  resolr@gsnAddCyclic = False
  resolr@gsnContourNegLineDashPattern = 1
  resolr@cnMonoLineColor    = True
  resolr@cnLinesOn          = True
  resolr@cnLineLabelsOn     = False
  resolr@cnLineColor        = "red3"
  resolr@cnLineThicknessF   = 3.5
  resolr@cnInfoLabelPerimOn = False
  resolr@cnInfoLabelOn      = False
  resolr@cnLevelSelectionMode = "Explicitlevels"
  resolr@cnLevels      = (/-25,-20,-15,-10,-5,5,10,15,20,25/)
;; vector res.
  resw = True
  resw@gsnFrame     = False
  resw@gsnDraw      = False
  resw@gsnMaximize  = False
  resw@gsnAddCyclic = False
  resw@vcGlyphStyle            = "LineArrow"
  resw@vcLineArrowThicknessF   = 2.5
  resw@vcRefMagnitudeF         = 4.
  resw@vcRefLengthF            = 0.05
  resw@vcLineArrowColor        = "mediumblue"
  resw@vcRefAnnoString2On      = False
  resw@vcRefAnnoString1        = "~F21~$VMG$" +" m s~S~-1~N~"
  resw@vcRefAnnoPerimOn        = False
  resw@vcRefAnnoBackgroundColor = -1

  resP = True
  resP@gsnMaximize  = True
  resP@gsnFrame     = False
  resP@gsnDraw      = True

  resP@pmLabelBarOrthogonalPosF = 0.0
  resP@pmLabelBarParallelPosF   = 0.0
  resP@pmLabelBarWidthF         = 0.6

  sres   = True 
  sres@cnLineDrawOrder    = "PostDraw"                    
  sres@gsnDraw            = False                          
  sres@gsnFrame           = False                        
  sres@cnLineLabelsOn     = False                              
  sres@cnLinesOn          = False                           
  sres@cnInfoLabelOn      = False
  sres@cnFillOn           = False                       
  sres@cnInfoLabelOn      = False
  sres@cnFillScaleF       = 0.5
  sres@cnFillDotSizeF     = 0.003
  sres@gsnLeftString      =" "
  sres@gsnRightString     =" "
  sres@cnMonoFillColor    = True
  sres@cnFillColor        = "gray"

  opt = True
  opt@gsnShadeFillType   = "pattern"
  opt@gsnShadeHigh       = 17
  opt@gsnShadeFillScaleF = 1.5

  respoly = True
  respoly@gsLineColor      = "purple"
  respoly@gsLineThicknessF = 4.5

  print("complete res. "+ systemfunc("date"))
;----------------------------------------------------------------------
;; plot.
  wks = gsn_open_wks("x11", pdir+"/"+"Fig3_SF_UV_MEEAJS")

  plot    = new(2,graphic)
  plotolr = plot
  plotv   = plot

  dum1    = plot

  Label  = (/"~F21~(a) 250hPa_SF&UV_P2","~F21~(b) 250hPa_SF&UV_P6"/)

  do n = 0,1
    x  = llphi(n,:,:)
    y  = llu(n,:,:)
    l  = llv(n,:,:)
    lt = l
    yt = y
    mvalue  = mvalue1
    if(n.eq.0)then
      xt = siglevel(x,mvalue(0,:,n,:,:))

      ;lt = mask(l,y.lt.mvalue(1,0,n,:,:).or.y.gt.mvalue(1,1,n,:,:).or.\
      ;          l.lt.mvalue(2,0,n,:,:).or.l.gt.mvalue(2,1,n,:,:),True)
      ;yt = mask(y,y.lt.mvalue(1,0,n,:,:).or.y.gt.mvalue(1,1,n,:,:).or.\
      ;          l.lt.mvalue(2,0,n,:,:).or.l.gt.mvalue(2,1,n,:,:),True)
      copy_VarCoords(y,lt)
      copy_VarCoords(y,yt)
      resw@vcRefAnnoOn  = False
    else
      xt = siglevel(x,mvalue(0,:,n,:,:))

      ;lt = mask(l,y.lt.mvalue(1,0,n,:,:).or.y.gt.mvalue(1,1,n,:,:).or.\
      ;          l.lt.mvalue(2,0,n,:,:).or.l.gt.mvalue(2,1,n,:,:),True)
      ;yt = mask(y,y.lt.mvalue(1,0,n,:,:).or.y.gt.mvalue(1,1,n,:,:).or.\
      ;          l.lt.mvalue(2,0,n,:,:).or.l.gt.mvalue(2,1,n,:,:),True)
      copy_VarCoords(y,lt)
      copy_VarCoords(y,yt)

      resw@vcRefAnnoOn = True
      resw@vcRefAnnoFontHeightF    = 0.012
      resw@vcRefAnnoOrthogonalPosF = 0.2
      resw@vcRefAnnoParallelPosF   = 0.95
    end if

    x = x*10^(-6)

    resu@gsnLeftString  = "~F21~"+Label(n)

    plot(n) = gsn_csm_contour_map(wks, x, resu)
    plotv(n)  = gsn_csm_vector(wks, yt(::2,::2), lt(::2,::2), resw)
    plotolr(n) = gsn_csm_contour(wks, llolr(n,:,:), resolr)
    plotut  = gsn_csm_contour(wks, uc, resc)

    dum1(n)   = gsn_csm_contour(wks,xt,sres)
    dum1(n)   = gsn_contour_shade(dum1(n),1.9,-999.,opt)

    lonmin =  10
    lonmax =  70
    latmin = -100
    latmax =  100
    polyx = (/lonmin,lonmax,lonmax,lonmin,lonmin/)
    polyy = (/latmin,latmin,latmax,latmax,latmin/)
    respoly@gsLineDashPattern = 0
    dum2 = gsn_add_polyline(wks, plot(n), polyx, polyy, respoly)

    lonmin =  110
    lonmax =  180
    latmin = -100
    latmax =  100
    polyx = (/lonmin,lonmax,lonmax,lonmin,lonmin/)
    polyy = (/latmin,latmin,latmax,latmax,latmin/)
    respoly@gsLineDashPattern = 1
    dum3 = gsn_add_polyline(wks, plot(n), polyx, polyy, respoly)

    overlay(plot(n),plotv(n))
    ;overlay(plot(n),dum1(n))
    overlay(plot(n),plotut)
    overlay(plot(n),plotolr(n))
    overlay(plot(n),dum2)
    overlay(plot(n),dum3)
  end do

  resP@gsnPanelLabelBar = True
  resP@lbTitleOn = True
  resP@lbTitleString = "[10~S~-6~N~ m~S~2~N~ s~S~-1~N~]"
  resP@lbTitlePosition  = "Right"
  resP@lbTitleDirection = "Across"
  resP@lbTitleFontHeightF = 0.015
  resP@lbBoxLinesOn       = True
  resP@gsnPanelRowSpec    = True
  resP@lbLabelFontHeightF = 0.013
  resP@lbTitleStringParallelPosF = -0.1

  gsn_panel(wks,(/plot(0),plot(1)/),(/1,1/),resP);

  i = 0
  do while(i.eq.0)
    i= 0
  end do