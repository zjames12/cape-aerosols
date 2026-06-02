#!/usr/bin/env python3
"""
CRPS (Continuous Ranked Probability Score) evaluation for CAPE aerosols diffusion model.

This module calculates CRPS scores to evaluate the probabilistic skill of
ensemble forecasts from the diffusion model compared to GEFS forecasts.
"""

from scores.probability import crps_for_ensemble
import pandas as pd
from tqdm import tqdm
import xarray as xr
import rioxarray as rxr
import glob

ai, gefs, date = [], [], []
other = []
# min_lon, max_lon = -126.25, -66.75
# min_lat, max_lat = 24.50, 55
area = rxr.open_rasterio("area3.tif").squeeze("band", drop=True)
area /= area.mean()

days = pd.to_datetime([])
days = days.append(pd.date_range("2023-04-01", "2023-09-30"))
days = days.append(pd.date_range("2024-04-01", "2024-09-30"))
days = days.append(pd.date_range("2025-04-01", "2025-09-30" ))
cnt = 0
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
        # # mask = (ch7 < 66) & (ch3 > 0.03 )
        # count = mask.sum().item()
        # if count < 200:
        #     continue
        cnt += 1

        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble9.3.2.0.6/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8.1.500.0.6/*.tif"))
        # files = sorted(glob.glob("crs2-7/" + day.strftime("%Y%m%d") + "/ensemble8.1.100.0.6.e/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8summer0.6/*.tif"))
        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8.0summer0.6/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gfs/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        ai_ens = xr.concat(members, dim="ensemble")
        # ai_ens = ai_ens.where(ai_ens > 20, 0)

        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gefs/*.tif"))
        # files = sorted(glob.glob("crs2-1/" + day.strftime("%Y%m%d") + "/ensemble8.1.500.0.6/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8.2noaerosolsummer0.6/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        gefs_ens = xr.concat(members, dim="ensemble")

        obs = rxr.open_rasterio("crs2/" + day.strftime("%Y%m%d") + "/c00/0.tif")

        ai_crps = crps_for_ensemble(ai_ens, obs, ensemble_member_dim="ensemble", method='fair', weights=area)
        gefs_crps = crps_for_ensemble(gefs_ens, obs, ensemble_member_dim="ensemble", method='fair', weights=area)

        ai.append(ai_crps.mean().item())
        gefs.append(gefs_crps.mean().item())
        date.append(day.strftime("%Y-%m-%d"))
        # other.append(obs.mean().item())
        # print(ai_crps.mean().item(), gefs_crps.mean().item())
    except Exception as e:
        print(f"Failed for {day.strftime('%Y-%m-%d')}: {e}")

df = pd.DataFrame({
    "date": date,
    "ai_crps": ai,
    "gefs_crps": gefs,
    # "other" : other,
})
# print(cnt)
df["ss"] = 1 - (df["ai_crps"] / df["gefs_crps"])
print(df["ai_crps"].mean())
# print(df["gefs_crps"].mean())
print(df["ss"].mean())
df.to_csv("crps_ensemble8.0summer0.6.csv", index=False)



