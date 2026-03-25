from scores.probability import crps_for_ensemble
from scores.continuous import mse
import numpy as np
import pandas as pd
from tqdm import tqdm
import xarray as xr
import rioxarray as rxr
import glob

df = pd.read_csv("nhc.csv", header=None,
                 names=["date", "time", "storm", "type", "lat", "lon", "wind"])
lat_parts = df["lat"].str.extract(r"([-+]?\d+\.?\d*)([NS])")
df["lat"] = lat_parts[0].astype(float) * lat_parts[1].map({"N": 1, "S": -1})
lon_parts = df["lon"].str.extract(r"([-+]?\d+\.?\d*)([EW])")
df["lon"] = lon_parts[0].astype(float) * lon_parts[1].map({"E": 1, "W": -1})
df["date"] = pd.to_datetime(df["date"].astype(str), format="%Y%m%d")

ai, gefs, date = [], [], []
other = []
min_lon, max_lon = -126.25, -66.75
min_lat, max_lat = 24.50, 55
area = rxr.open_rasterio("area3.tif").squeeze("band", drop=True)
area /= area.mean()

days = pd.to_datetime([])
# days = days.append(pd.date_range("2023-04-01", "2023-09-30"))
days = days.append(pd.date_range("2024-04-01", "2024-09-30"))
days = days.append(pd.date_range("2025-04-01", "2025-09-30"))
cnt = 0

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

for day in tqdm(days):
    mask = (
        (df["date"] == day) &
        (df["time"] == 1800) &
        # (df["type"] == "HU") &
        (df["lat"] >= min_lat) & (df["lat"] <= max_lat) &
        (df["lon"] >= min_lon) & (df["lon"] <= max_lon)
    )
    hurricanes = df[mask]
    if hurricanes.empty:
        continue
    try:
        cnt += 1
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8summer0.6/*.tif"))
        # files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/ensemble8.2noaerosolsummer0.6/*.tif"))
        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gfs/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        ai_ens = xr.concat(members, dim="ensemble")

        files = sorted(glob.glob("crs2/" + day.strftime("%Y%m%d") + "/gefs/*.tif"))
        members = [rxr.open_rasterio(f).squeeze("band", drop=True) for f in files]
        gefs_ens = xr.concat(members, dim="ensemble")

        obs = rxr.open_rasterio("crs2/" + day.strftime("%Y%m%d") + "/c00/0.tif")

        # ai_crps = crps_for_ensemble(ai_ens, obs, ensemble_member_dim="ensemble", method='ecdf', weights=area)
        # gefs_crps = crps_for_ensemble(gefs_ens, obs, ensemble_member_dim="ensemble", method='fair', weights=area)
        
        ai_ssr, ai_rmse, ai_spread = spread_skill_ratio(ai_ens, obs, member_dim="ensemble")
        gefs_ssr, gefs_rmse, gefs_spread = spread_skill_ratio(gefs_ens, obs, member_dim="ensemble")
        
        ai.append(ai_rmse.mean().item())
        gefs.append(gefs_rmse.mean().item())
        date.append(day.strftime("%Y-%m-%d"))
        other.append(obs.mean().item())
    except Exception as e:
        print(f"Failed for {day.strftime('%Y-%m-%d')}: {e}")

df = pd.DataFrame({
    "date": date,
    "ai_crps": ai,
    "gefs_crps": gefs,
})
print(cnt)
df["ss"] = 1 - (df["ai_crps"] / df["gefs_crps"])
print(df["ss"].mean())




