import requests
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import time
from typing import Dict, Any

class LiveWeatherEngine:
    def __init__(self):
        self.base_url = "https://power.larc.nasa.gov/api/temporal/daily/point"
        self.params = "T2M_MAX,T2M_MIN,PRECTOTCORR,ALLSKY_SFC_SW_DWN,EVPTRNS,T2MDEW,RH2M,GWETTOP,GWETROOT,WS10M_MAX,TS"
    
    def _get_season_config(self, query_date: datetime):
        year = query_date.year
        month = query_date.month
        
        if 6 <= month <= 10:
            return "Kharif", datetime(year, 6, 1), datetime(year, 10, 31)
        elif month >= 11:
            return "Rabi", datetime(year, 11, 1), datetime(year + 1, 3, 31)
        elif month <= 3:
            return "Rabi", datetime(year - 1, 11, 1), datetime(year, 3, 31)
        else:
            return "Zaid", datetime(year, 4, 1), datetime(year, 5, 31)

    def _fetch_nasa(self, lat: float, lon: float, start: datetime, end: datetime) -> pd.DataFrame:
        api_params = {
            "parameters": self.params,
            "community": "AG",
            "longitude": lon,
            "latitude": lat,
            "start": start.strftime("%Y%m%d"),
            "end": end.strftime("%Y%m%d"),
            "format": "JSON"
        }
        
        for _ in range(2):
            try:
                response = requests.get(self.base_url, params=api_params, timeout=12)
                if response.status_code == 200:
                    data = response.json()
                    feat_data = data['properties']['parameter']
                    dates = sorted(feat_data['T2M_MAX'].keys())
                    
                    df = pd.DataFrame({'Date': dates})
                    for key in feat_data:
                        df[key] = [feat_data[key][d] for d in dates]
                    
                    df.replace(-999, np.nan, inplace=True)
                    df.ffill(inplace=True)
                    df.bfill(inplace=True)
                    return df
            except Exception as e:
                print(f"[WEATHER_ENGINE] NASA API attempt error: {e}")
                time.sleep(0.5)
        return pd.DataFrame()

    def _calculate_features(self, df: pd.DataFrame) -> Dict[str, Any]:
        if df.empty:
            return {}

        es = 0.6108 * np.exp((17.27 * df['T2M_MAX']) / (df['T2M_MAX'] + 237.3))
        ea = 0.6108 * np.exp((17.27 * df['T2MDEW']) / (df['T2MDEW'] + 237.3))
        df['VPD'] = (es - ea).clip(lower=0)

        df['GDD'] = (((df['T2M_MAX'] + df['T2M_MIN']) / 2) - 10).clip(lower=0)
        df['Net_Water'] = df['PRECTOTCORR'] - df['EVPTRNS']

        df['Heat_Stress'] = (df['T2M_MAX'] > 35).astype(int)
        df['Pest_Risk'] = ((df['RH2M'] > 85) & (df['T2M_MIN'] > 20)).astype(int)

        return {
            'Total_Rain': float(round(df['PRECTOTCORR'].sum(), 2)),
            'Total_Solar_Rad': float(round(df['ALLSKY_SFC_SW_DWN'].sum(), 2)),
            'Total_GDD': float(round(df['GDD'].sum(), 2)),
            'Total_ET0': float(round(df['EVPTRNS'].sum(), 2)),
            'Net_Water_Balance': float(round(df['Net_Water'].sum(), 2)),
            'Mean_VPD': float(round(df['VPD'].mean(), 4)),
            'Mean_Surface_Moisture': float(round(df['GWETTOP'].mean() * 100, 2)),
            'Mean_Root_Moisture': float(round(df['GWETROOT'].mean() * 100, 2)),
            'Total_Heat_Stress_Days': int(df['Heat_Stress'].sum()),
            'Total_Pest_Risk_Days': int(df['Pest_Risk'].sum()),
            'Max_Wind_Speed': float(round(df['WS10M_MAX'].max(), 2)),
            'Mean_Soil_Temp': float(round(df['TS'].mean(), 2))
        }

    def generate_prediction_vector(self, lat: float, lon: float, query_date_str: str) -> Dict[str, Any]:
        query_date = datetime.strptime(query_date_str, "%Y-%m-%d")
        season, start_date, end_date = self._get_season_config(query_date)

        obs_end = min(query_date, end_date)
        df_obs = self._fetch_nasa(lat, lon, start_date, obs_end)

        obs_pest_risk_days = 0
        if not df_obs.empty:
            mask_pest = (df_obs['RH2M'] > 85) & (df_obs['T2M_MIN'] > 20)
            obs_pest_risk_days = int(mask_pest.sum())

        df_future = pd.DataFrame()
        if obs_end < end_date and not df_obs.empty:
            fut_start = obs_end + timedelta(days=1)
            historical_dfs = []
            for year_offset in [1, 2]:
                try:
                    h_start = fut_start.replace(year=fut_start.year - year_offset)
                    h_end = end_date.replace(year=end_date.year - year_offset)
                    h_df = self._fetch_nasa(lat, lon, h_start, h_end)
                    if not h_df.empty:
                        historical_dfs.append(h_df)
                except Exception:
                    pass

            if historical_dfs:
                min_len = min([len(d) for d in historical_dfs])
                avg_data = {}
                for col in self.params.split(','):
                    cols = [d[col].values[:min_len] for d in historical_dfs]
                    avg_data[col] = np.mean(cols, axis=0)
                df_future = pd.DataFrame(avg_data)

        if df_future.empty:
            df_full = df_obs
        else:
            df_full = pd.concat([df_obs, df_future], ignore_index=True)

        if df_full.empty:
            # Fallback default weather features if API unavailable
            return {
                'Total_Rain': 450.0,
                'Total_Solar_Rad': 1850.0,
                'Total_GDD': 1400.0,
                'Total_ET0': 520.0,
                'Net_Water_Balance': -70.0,
                'Mean_VPD': 1.25,
                'Mean_Surface_Moisture': 45.0,
                'Mean_Root_Moisture': 55.0,
                'Total_Heat_Stress_Days': 3,
                'Total_Pest_Risk_Days': 2,
                'Max_Wind_Speed': 14.5,
                'Mean_Soil_Temp': 26.5,
                'Season': season,
                'Crop_Year': start_date.year,
                'Observed_Pest_Risk_Days': 2
            }

        features = self._calculate_features(df_full)
        features['Season'] = season
        features['Crop_Year'] = start_date.year
        features['Observed_Pest_Risk_Days'] = obs_pest_risk_days

        return features


_engine = LiveWeatherEngine()

def get_weather_data(latitude: float, longitude: float, sowing_date: str = None, crop: str = None, season: str = None) -> dict:
    try:
        today_str = datetime.now().strftime("%Y-%m-%d")
        features = _engine.generate_prediction_vector(latitude, longitude, today_str)
        return features
    except Exception as e:
        print(f"[ERROR] get_weather_data failed: {e}")
        return {
            'Total_Rain': 450.0,
            'Total_Solar_Rad': 1850.0,
            'Total_GDD': 1400.0,
            'Total_ET0': 520.0,
            'Net_Water_Balance': -70.0,
            'Mean_VPD': 1.25,
            'Mean_Surface_Moisture': 45.0,
            'Mean_Root_Moisture': 55.0,
            'Total_Heat_Stress_Days': 3,
            'Total_Pest_Risk_Days': 2,
            'Max_Wind_Speed': 14.5,
            'Mean_Soil_Temp': 26.5,
            'Season': 'Kharif',
            'Crop_Year': datetime.now().year,
            'Observed_Pest_Risk_Days': 2
        }
