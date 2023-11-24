#! /bin/bash
###############################################################################
# This script calls for two ncl scripts.
# 1. jet_indices.ncl to calculate jet indices.
# 2. plot.ncl to plot
# $1: jet location; $2: latmin $3: latmax $4: lonmin $5: lonmax
# Information
# author: cui xiangyang time: 2023-11-07
###############################################################################

export dddir="/home/sunming/data5/cuixy/data/MJO_pan-Atlantic"
export wkdir="/home/sunming/data5/cuixy/global_jets"
export indir="${wkdir}/data/ERA5_daily_u250_1979-2022_all.nc"
export outdir="${wkdir}/data/jet_indices_${1}_${6}.nc"
export plotd="${wkdir}/plot/${1}_${6}"
#export plotu="${wkdir}/plot/${1}_u250"
export rmmdir="/home/sunming/data5/cuixy/data/clim_indices/rmm.74toRealtime.csv"

export var="u"
export var1="jets"
export var2="jetl"
export var3="jetz"

export latmin="$2"
export latmax="$3"
export lonmin="$4"
export lonmax="$5"

export n1="${7}"
export n2="${8}"

##############################################################################
if [ ! -f $outdir ]; then

	ncl ${wkdir}/script/Jet_indices1.ncl
	echo "indices finish"
fi

#ncl  ${wkdir}/script/u250clim.ncl
#echo "plot u250 finish"

ncl  ${wkdir}/script/plot.ncl
echo "plot indices finish"


