import os
import catboost as cb
import pandas as pd
from typing import Tuple, Dict, Any

SAT_FEATURES_ORDER = [
    'State', 'District', 'Latitude', 'Longitude', 'Crop', 'Crop_Year', 'Season',
    'Total_Rain', 'Total_Solar_Rad', 'Total_GDD', 'Total_ET0', 'Net_Water_Balance',
    'Mean_VPD', 'Mean_Surface_Moisture', 'Mean_Root_Moisture',
    'Total_Heat_Stress_Days', 'Total_Pest_Risk_Days', 'Max_Wind_Speed', 'Mean_Soil_Temp',
    'n_Val', 'p_Val', 'k_Val', 'OC_Val', 'S_Risk', 'Zn_Risk', 'B_Risk',
    'pH_Stress', 'Salinity_Risk', 'bdod_val', 'cfvo_val', 'clay_val', 'sand_val',
    'silt_val', 'Texture_Class', 'NDVI', 'NDMI', 'NDYI', 'LST'
]

NOSAT_FEATURES_ORDER = [f for f in SAT_FEATURES_ORDER if f not in ['NDVI', 'NDMI', 'NDYI', 'LST']]


class ModelLoader:
    def __init__(self, data_dir: str = None):
        if data_dir is None:
            # Default to backend/data
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            data_dir = os.path.join(base_dir, "data")
        
        self.data_dir = data_dir
        self.sat_model = None
        self.nosat_model = None
        self._models_loaded = False

    def load_models(self):
        """Load both CatBoost models (.cbm)"""
        if self._models_loaded:
            return

        sat_path = os.path.join(self.data_dir, "oilseed_yield_satellite.cbm")
        nosat_path = os.path.join(self.data_dir, "oilseed_yield_nosat.cbm")

        if os.path.exists(sat_path):
            self.sat_model = cb.CatBoostRegressor()
            self.sat_model.load_model(sat_path)
            print(f"[ML] Loaded satellite model from {sat_path}")
        else:
            print(f"[WARNING] Satellite model not found at {sat_path}")

        if os.path.exists(nosat_path):
            self.nosat_model = cb.CatBoostRegressor()
            self.nosat_model.load_model(nosat_path)
            print(f"[ML] Loaded no-satellite model from {nosat_path}")
        else:
            print(f"[WARNING] No-satellite model not found at {nosat_path}")

        self._models_loaded = True

    def get_model_for_user(self, has_satellite_data: bool) -> Tuple[Any, list]:
        """Get model and feature ordering based on satellite availability"""
        if not self._models_loaded:
            self.load_models()

        if has_satellite_data and self.sat_model is not None:
            return self.sat_model, SAT_FEATURES_ORDER
        elif self.nosat_model is not None:
            return self.nosat_model, NOSAT_FEATURES_ORDER
        else:
            raise RuntimeError("No CatBoost yield models available")

    def predict(self, model: Any, X_input: pd.DataFrame) -> Dict[str, float]:
        """Generate CatBoost multi-quantile prediction [lower, predicted, upper]"""
        preds = model.predict(X_input)
        
        # Format prediction
        if hasattr(preds, 'shape') and len(preds.shape) > 1 and preds.shape[1] >= 3:
            lower = max(0.1, round(float(preds[0][0]), 2))
            predicted = max(0.1, round(float(preds[0][1]), 2))
            upper = max(lower + 0.1, round(float(preds[0][2]), 2))
        else:
            pred_val = float(preds[0]) if hasattr(preds, '__len__') else float(preds)
            predicted = round(max(0.1, pred_val), 2)
            lower = round(max(0.1, predicted * 0.85), 2)
            upper = round(predicted * 1.15, 2)

        return {
            "lower": lower,
            "predicted": predicted,
            "upper": upper
        }


# Singleton instance
model_loader = ModelLoader()
