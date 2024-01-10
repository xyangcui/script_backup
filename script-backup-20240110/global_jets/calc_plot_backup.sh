#! /bin/bash
###############################################################################
# This script calls for two ncl scripts.
# 1. jet_indices.ncl to calculate jet indices.
# 2. plot.ncl to plot
# $1: jet location; $2: latmin $3: latmax $4: lonmin $5: lonmax $6: box.
# Information
# author: cui xiangyang time: 2023-11-07
###############################################################################

export wkdir="/home/sunming/data5/cuixy/global_jets"
export indir="${wkdir}/data/ERA5_daily_u250_1979-2022_all.nc"
export udir="${wkdir}/data/ERA5_daily_u250_1979-2022.nc"
export outdir="${wkdir}/data/jet_indices_${1}.nc"
export plotdir="${wkdir}/plot/jet_indices_${1}"
export rmmdir="/home/sunming/data5/cuixy/data/clim_indices/rmm.74toRealtime.csv"

export var="u"
export var1="jets"
export var2="jetl"

export latmin="$[  ${2} ]"
export latmax="$[  ${3} ]"
export lonmin="$[  ${4} ]"
export lonmax="$[  ${5} ]"

export n1="${6}"
export n2="${7}"

##############################################################################

if [ ! -f $outdir ]; then

    ncl ${wkdir}/script/Jet_indices.ncl
fi
echo "jet indices finish."

ncl  ${wkdir}/script/plot_backup.ncl

echo "plot finish."
