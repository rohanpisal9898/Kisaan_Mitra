import os
import pandas as pd
from typing import Dict, Optional

class SoilService:
    def __init__(self, csv_path: str = None):
        if csv_path is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            csv_path = os.path.join(base_dir, "data", "Final_Soil_Dataset_Combined.csv")
        
        self.csv_path = csv_path
        self.soil_df = None
        self._load_data()

    def _load_data(self):
        if os.path.exists(self.csv_path):
            try:
                self.soil_df = pd.read_csv(self.csv_path)
                print(f"[SOIL] Loaded soil dataset ({len(self.soil_df)} rows) from {self.csv_path}")
            except Exception as e:
                print(f"[ERROR] Failed to load soil dataset: {e}")
                self.soil_df = None
        else:
            print(f"[WARNING] Soil dataset CSV not found at {self.csv_path}")

    def get_soil_by_district(self, state: str, district: str) -> Optional[Dict]:
        if self.soil_df is None or len(self.soil_df) == 0:
            return self._fallback_soil_data()

        result = self.soil_df[
            (self.soil_df['State'].astype(str).str.upper() == state.upper()) &
            (self.soil_df['District'].astype(str).str.upper() == district.upper())
        ]

        if len(result) == 0:
            # Match state only if district fails
            state_match = self.soil_df[self.soil_df['State'].astype(str).str.upper() == state.upper()]
            if len(state_match) > 0:
                row = state_match.iloc[0]
            else:
                row = self.soil_df.iloc[0]
        else:
            row = result.iloc[0]

        return {
            "n_Val": float(row['n_Val']),
            "p_Val": float(row['p_Val']),
            "k_Val": float(row['k_Val']),
            "OC_Val": float(row['OC_Val']),
            "S_Risk": float(row['S_Risk']),
            "Zn_Risk": float(row['Zn_Risk']),
            "B_Risk": float(row['B_Risk']),
            "pH_Stress": float(row['pH_Stress']),
            "Salinity_Risk": float(row['Salinity_Risk']),
            "bdod_val": float(row['bdod_val']),
            "cfvo_val": float(row['cfvo_val']),
            "clay_val": float(row['clay_val']),
            "sand_val": float(row['sand_val']),
            "silt_val": float(row['silt_val']),
            "Texture_Class": int(row['Texture_Class'])
        }

    def _fallback_soil_data(self) -> Dict:
        """Default soil profile for Nashik / Maharashtra if CSV lookup fails"""
        return {
            "n_Val": 240.0,
            "p_Val": 18.5,
            "k_Val": 310.0,
            "OC_Val": 0.55,
            "S_Risk": 35.0,
            "Zn_Risk": 42.0,
            "B_Risk": 20.0,
            "pH_Stress": 7.2,
            "Salinity_Risk": 0.15,
            "bdod_val": 1.35,
            "cfvo_val": 8.0,
            "clay_val": 45.0,
            "sand_val": 25.0,
            "silt_val": 30.0,
            "Texture_Class": 1
        }

    def get_soil_data(self, state: str, district: str) -> Dict:
        data = self.get_soil_by_district(state, district)
        if data is None:
            return self._fallback_soil_data()
        return data

# Global singleton instance
soil_service = SoilService()
