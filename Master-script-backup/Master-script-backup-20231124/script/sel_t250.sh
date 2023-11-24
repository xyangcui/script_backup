#!/bin/bash
# InFo
# select t250 from 1979 to 2022.
# author: cui xiangyang. time: 2023-11-21
export Ddir="/home/sunming/data5/cuixy/DATA/ERA-5/daily/tprs"
export odir="/home/sunming/data5/cuixy/global_jets/data"

for date in $(seq -w 01 23);do
    cdo -sellevel,250 ${Ddir}/day_t_flt_${date}.nc ${odir}/tmp_day_t_flt_${date}.nc
done

cdo -mergetime ${odir}/tmp_day_t_flt_??.nc ${odir}/tmp_ERA5_daily_t250.nc

cdo -seldate,1979-01-01,2022-12-31  ${odir}/tmp_ERA5_daily_t250.nc ${odir}/ERA5_daily_t250_1979-2022_all.nc

rm -f ${odir}/tmp*.nc
