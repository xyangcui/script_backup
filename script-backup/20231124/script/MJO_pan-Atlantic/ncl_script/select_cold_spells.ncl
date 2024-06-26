;------------------------------------------------------
; select Cold Spell dates for ever point in NA.
; take 5th percentile. anomalies lower than it.
; Information
; author: cui xiangyang time: 2023-10-29 release:v1
;------------------------------------------------------
datadir = "/home/sunming/data5/cuixy/data/MJO_pan-Atlantic/ERA5_2m_temperature/"
inname  = "ERA5_2m_temperature_anom_1979-2022.nc"
ouname  = "selected_cold_spell_dates.nc"

var = "t2m"
x_5th = var+"_5th"

;------------------------------------------------------
; function nth percentile
;------------------------------------------------------
undef("percent_to_value")
function percent_to_value(i_data,i_per)
local i_value,igood,floatInd,floorInd,ceilInd,retVal
begin
  
  if ( any(ismissing(i_data)) ) then
    igood   = ind(.not.ismissing(i_data))
    i_value = i_data(igood)
  else
    i_value = i_data
  end if

  ; sort!!!!!
  qsort(i_value)
  
  floatInd = i_per*.01*dimsizes(i_value) - 0.5
  floorInd = toint( floor(floatInd) )
  floorInd = where( floorInd.lt.0,0,floorInd )
  ceilInd  = toint( ceil(floatInd) )
  ceilInd  = where( ceilInd.ge.dimsizes(i_value), \
                   dimsizes(i_value)-1,ceilInd)

  if( ceilInd.eq.floorInd) then
    retVal = i_value(floorInd)
  else
    retVal = i_value(floorInd)*(ceilInd-floatInd) \
    + i_value(ceilInd)*(floatInd-floorInd)
  end if

  return(retVal)
  delete([/i_data,i_value,igood,floatInd,floorInd,ceilInd,retVal/])
end

;------------------------------------------------------
; function stats values 5th percentile
;------------------------------------------------------
undef("th_percentile")
function th_percentile(x[*][*][*]:float,per)
local x,y,th,nlat1,nlon1
begin
  nlat1 = dimsizes(x&lat)
  nlon1 = dimsizes(x&lon)
  th = new((/nlat1,nlon1/),float)
  th = 0.

  do i = 0, nlat1-1
    do j = 0, nlon1-1
        th(i,j) = percent_to_value(x(:,i,j),per)
    end do
  end do
  return(th)
  delete([/x,y,th,nlat1,nlon1/])
end 
;------------------------------------------------------
; Main code.
;------------------------------------------------------

f = addfile(datadir+inname,"r")

time = f->time
TIME = cd_calendar(time, 0)
year = toint(TIME(:,0))
mon  = toint(TIME(:,1))
day  = toint(TIME(:,2))

t2m = f->$var$

lat  = t2m&lat
lon  = t2m&lon
nlat = dimsizes(lat)
nlon = dimsizes(lon)

;--5th percentile calculation.
nt  = ind(mon.eq.3.or.mon.eq.1.or.mon.eq.2)
year(nt) = year(nt)-1
delete(nt)
nt  = ind(mon.eq.12.or.mon.eq.1.or.mon.eq.2)
t2mtmp = t2m(nt,:,:)

t2m_5th = th_percentile(t2mtmp,5)
print("5th final.")
; select Cold spell days.
cdate    = new((/dimsizes(nt),nlat,nlon/),integer)
cdate    = 0
t2t  = new((/dimsizes(nt),nlat,nlon/),float)
t2t  = 0.
delete(t2m)

do i =0,dimsizes(nt)-1
  t2t(i,:,:)  = t2mtmp(i,:,:) - t2m_5th
end do

do k=0,nlat-1
    do m=0,nlon-1  
        nle  = ind(t2t(:,k,m).lt.0.)              ;t2t index, lab2(nle)--time's index
        if (.not.all(ismissing(nle)) )then
          cdate(nle,k,m) = 1 
        end if 
        delete(nle)
    end do
end do
copy_VarCoords(t2mtmp, cdate)
copy_VarCoords(t2mtmp(0,:,:), t2m_5th)

system("rm -f "+datadir+ouname)
f1 = addfile(datadir+ouname,"c")
f1->cdate   = cdate 
f1->$var$ = t2m_5th
