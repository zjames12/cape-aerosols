#!/usr/bin/env python3
"""
RMSE and spread-skill analysis for CAPE aerosols diffusion model evaluation.

This module calculates Root Mean Square Error (RMSE) and spread-skill ratios
to evaluate the performance and reliability of ensemble forecasts compared
to GEFS operational forecasts.
"""

from scores.probability import crps_for_ensemble, brier_score_for_ensemble
from scores.continuous import mse
import pandas as pd
import numpy as np
from tqdm import tqdm
import xarray as xr
import rioxarray as rxr
import glob
cnt = 0
ai, gefs, ai_r, gefs_r, ai_s, gefs_s, date = [], [], [], [], [], [], []
other = []
area = rxr.open_rasterio("area3.tif").squeeze("band", drop=True)
area /= area.mean()
M = 30 # number of ensemble members

days = pd.to_datetime([])
days = days.append(pd.date_range("2023-04-01", "2023-09-30"))
days = days.append(pd.date_range("2024-04-01", "2024-09-30"))
days = days.append(pd.date_range("2025-04-01", "2025-09-30"))

def spread_skill_ratio(ens: xr.DataArray, obs: xr.DataArray, member_dim="ensemble"):
    """
    ens: DataArray with dims (member, lat, lon)
    obs: DataArray with dims (lat, lon)
    """
    # Ensemble mean
    ens_mean = ens.mean(dim=member_dim)

    # Ensemble variance -> spread
    ens_var = ens.var(dim=member_dim, ddof=1)
    weighted_var = (ens_var * area)
    spread = np.sqrt(weighted_var.mean().item())

    # RMSE
    # rmse = np.sqrt(mse(ens_mean, obs, weights=area).mean().item()-weighted_var.mean().item()/M)
    rmse = np.sqrt(mse(ens_mean, obs, weights=area).mean().item()) 
    
    # rmse = np.sqrt(((ens_mean - obs) ** 2).mean())

    # Spread-skill ratio, rmse, spread
    return (float(spread / rmse), rmse, spread)

for day in tqdm(days):#pd.date_range(start="2023-07-01", end="2023-07-31", freq="D"): 
    # print(day.strftime("%Y-%m-%d"))
    try:
        # f = "scoring-combined/" + day.strftime("%Y%m%d") + ".tif"
        # truth = rxr.open_rasterio(f)
        # ch7 = truth.isel(band=6)
        # ch3 = truth.isel(band=1)
        # chaod = truth.isel(band=1) + truth.isel(band=2) + truth.isel(band=3) + truth.isel(band=4) + truth.isel(band=5)
        # mask = (ch7 < 743) & (ch3 > 0.03 )#547 is the 80th percentile of ch7, 0.03077247 is the 80th percentile of ch3
        # # mask = (ch7 > 320) & (ch3 > 0.018 )
        # count = mask.sum().item()
        # if count < 200:
        #     continue
        # cnt += 1
        
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble9.3.2.0.6/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8summer0.6/*.tif"))
        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8.0summer0.6/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gfs/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        ai_ens = xr.concat(members, dim="ensemble")

        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gefs/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        gefs_ens = xr.concat(members, dim="ensemble")

        obs = rxr.open_rasterio("crs2/" + day.strftime("%Y%m%d") + "/c00/0.tif")

        ai_ssr, ai_rmse, ai_spread = spread_skill_ratio(ai_ens, obs, member_dim="ensemble")
        gefs_ssr, gefs_rmse, gefs_spread = spread_skill_ratio(gefs_ens, obs, member_dim="ensemble")
        ai.append(ai_ssr)
        gefs.append(gefs_ssr)
        ai_r.append(ai_rmse)
        gefs_r.append(gefs_rmse)
        ai_s.append(ai_spread)
        gefs_s.append(gefs_spread)
        date.append(day.strftime("%Y-%m-%d"))
        other.append(obs.mean().item())
    except Exception as e:
        print(f"Failed for {day.strftime('%Y-%m-%d')}: {e}")

df = pd.DataFrame({
        "date": date,
        "ai_rmse": ai_r,
        "gefs_rmse": gefs_r,
        "ai_spread": ai_s,
        "gefs_spread": gefs_s,
        "ai_ssr": ai,
        "gefs_ssr": gefs,
        "other" : other,
    })
df["ss"] = 1 - (df["ai_rmse"] / df["gefs_rmse"])
print(cnt)
print(df["ai_ssr"].mean())
# df.to_csv("temp.csv", index=False)
df.to_csv("rmse_ensemble8.0summer0.6.csv", index=False)



