#!/usr/bin/env python3
"""
Brier score evaluation for CAPE aerosols diffusion model.

This module calculates Brier scores for binary event prediction to evaluate
how well the ensemble forecasts predict threshold exceedance events
compared to GEFS and climatological forecasts.
"""

from scores.probability import crps_for_ensemble, brier_score_for_ensemble
import pandas as pd
import xarray as xr
import rioxarray as rxr
import glob

# def mse(ens: xr.DataArray, obs: xr.DataArray):
#     mse = mse(ens_mean, obs, weights=area).mean().item()

ai_99, gefs_99, date = [], [], []
ai_999, gefs_999 = [], []
ai_9999, gefs_9999 = [], []
clim_99, clim_999, clim_9999 = [], [], []

area = rxr.open_rasterio("area3.tif").squeeze("band", drop=True)
area /= area.mean()

q99, q999, q9999 = 2462, 3799, 4846.544 # Calculated in extremes_calculation.R

for day in pd.date_range(start="2022-01-01", end="2025-12-01", freq="D"): 
    print(day.strftime("%Y-%m-%d"))
    try:
        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble30.8/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        ai_ens = xr.concat(members, dim="ensemble")
        ai_ens = ai_ens.where(ai_ens > 20, 0)

        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gefs/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        gefs_ens = xr.concat(members, dim="ensemble")

        clim99 = rxr.open_rasterio("clim_crop_99.tif") * area
        clim999 = rxr.open_rasterio("clim_crop_999.tif") * area
        clim9999 = rxr.open_rasterio("clim_crop_9999.tif") * area
        # clim = (clim >= q99).astype(int)

        obs = rxr.open_rasterio("crs2/" + day.strftime("%Y%m%d") + "/c00/0.tif")

        ai_brier_99 = brier_score_for_ensemble(ai_ens, obs, ensemble_member_dim="ensemble", weights=area, event_thresholds=q99)
        ai_brier_999 = brier_score_for_ensemble(ai_ens, obs, ensemble_member_dim="ensemble", weights=area, event_thresholds=q999)
        ai_brier_9999 = brier_score_for_ensemble(ai_ens, obs, ensemble_member_dim="ensemble", weights=area, event_thresholds=q9999)

        gefs_brier_99 = brier_score_for_ensemble(gefs_ens, obs, ensemble_member_dim="ensemble", weights=area, event_thresholds=q99)
        gefs_brier_999 = brier_score_for_ensemble(gefs_ens, obs, ensemble_member_dim="ensemble", weights=area, event_thresholds=q999)
        gefs_brier_9999 = brier_score_for_ensemble(gefs_ens, obs, ensemble_member_dim="ensemble", weights=area, event_thresholds=q9999)
        
        clim_brier_99 = (((obs >= q99).astype(int) - clim99)**2)
        clim_brier_999 = (((obs >= q999).astype(int) - clim999)**2)
        clim_brier_9999 = (((obs >= q9999).astype(int) - clim9999)**2)


        ai_99.append(ai_brier_99.mean().item())
        gefs_99.append(gefs_brier_99.mean().item())
        clim_99.append(clim_brier_99.mean().item())
        ai_999.append(ai_brier_999.mean().item())
        gefs_999.append(gefs_brier_999.mean().item())
        clim_999.append(clim_brier_999.mean().item())
        ai_9999.append(ai_brier_9999.mean().item())
        gefs_9999.append(gefs_brier_9999.mean().item())
        clim_9999.append(clim_brier_9999.mean().item())


        date.append(day.strftime("%Y-%m-%d"))
        print(ai_brier_99.mean().item(), gefs_brier_99.mean().item(), clim_brier_99.mean().item())
    except Exception as e:
        print(f"Failed for {day.strftime('%Y-%m-%d')}: {e}")

df = pd.DataFrame({
    "date": date,
    "ai_brier_99": ai_99,
    "gefs_brier_99": gefs_99,
    "clim_brier_99": clim_99,
    "ai_brier_999": ai_999,
    "gefs_brier_999": gefs_999,
    "clim_brier_999": clim_999,
    "ai_brier_9999": ai_9999,
    "gefs_brier_9999": gefs_9999,
    "clim_brier_9999": clim_9999,
})
df.to_csv("brier_crop_weighted.csv", index=False)



