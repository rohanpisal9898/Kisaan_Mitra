"""
Water status calculation service.

Uses FAO-56 crop coefficient method:
  ETc = Kc × ETo  (Crop water demand)
  Effective Rainfall = 70% of forecast rainfall
  Net Irrigation Requirement = max(0, ETc - Effective Rainfall)

UI separates:
  1. Crop water demand (ETc)
  2. Water to apply / irrigation_mm
"""

from typing import Dict, Any, Optional

WELL_SUPPLIED_THRESHOLD = 0.85
NEEDS_SOON_THRESHOLD = 0.60
IRRIGATION_NEEDED_THRESHOLD = 0.35
RAIN_SUFFICIENT_MM = 5.0


class WaterService:
    """Calculates water status using FAO-56 Kc method."""

    def calculate_kc(
        self,
        crop_profile: Dict[str, Any],
        days_after_sowing: int,
    ) -> float:
        kc_data = crop_profile.get("kc", {})
        kc_ini = kc_data.get("initial", 0.35)
        kc_mid = kc_data.get("mid", 1.15)
        kc_end = kc_data.get("end", 0.50)

        stages = crop_profile.get("stages", {})
        ini_days = stages.get("initial", 20)
        dev_days = stages.get("development", 30)
        mid_days = stages.get("mid_season", 40)
        late_days = stages.get("late_season", 20)

        ini_end = ini_days
        dev_end = ini_end + dev_days
        mid_end = dev_end + mid_days
        total = mid_end + late_days

        if days_after_sowing <= 0:
            return kc_ini
        elif days_after_sowing <= ini_end:
            return kc_ini
        elif days_after_sowing <= dev_end:
            progress = (days_after_sowing - ini_end) / max(dev_days, 1)
            return kc_ini + progress * (kc_mid - kc_ini)
        elif days_after_sowing <= mid_end:
            return kc_mid
        elif days_after_sowing <= total:
            progress = (days_after_sowing - mid_end) / max(late_days, 1)
            return kc_mid + progress * (kc_end - kc_mid)
        else:
            return kc_end

    def calculate_water_status(
        self,
        crop_profile: Dict[str, Any],
        days_after_sowing: int,
        eto_mm: float,
        forecast_rain_mm: float = 0.0,
    ) -> Dict[str, Any]:
        kc = self.calculate_kc(crop_profile, days_after_sowing)
        etc_mm = round(kc * eto_mm, 2)  # Crop water demand
        effective_rain = round(forecast_rain_mm * 0.7, 2)
        net_irrigation_need = round(max(0, etc_mm - effective_rain), 1)

        supply_fraction = 1.0 if etc_mm <= 0 else effective_rain / etc_mm

        kc_status = crop_profile.get("kc_status", "established")
        kc_confidence = crop_profile.get("kc_confidence", "high")

        # 1. Rain sufficient condition
        if forecast_rain_mm >= RAIN_SUFFICIENT_MM and (supply_fraction >= WELL_SUPPLIED_THRESHOLD or net_irrigation_need <= 3.0):
            return self._build_response(
                status="rain_sufficient",
                display="Rain may cover need",
                irrigation_mm=0.0,
                description="No irrigation needed today",
                color="blue",
                eto_mm=eto_mm,
                kc=kc,
                etc_mm=etc_mm,
                effective_rain=effective_rain,
                irrigation_need=net_irrigation_need,
                kc_status=kc_status,
                kc_confidence=kc_confidence,
            )

        # 2. Well supplied / Good
        if supply_fraction >= WELL_SUPPLIED_THRESHOLD or net_irrigation_need <= 2.0:
            return self._build_response(
                status="good",
                display="Good",
                irrigation_mm=0.0,
                description="No irrigation needed today",
                color="green",
                eto_mm=eto_mm,
                kc=kc,
                etc_mm=etc_mm,
                effective_rain=effective_rain,
                irrigation_need=0.0,
                kc_status=kc_status,
                kc_confidence=kc_confidence,
            )

        # 3. Needs Soon
        elif supply_fraction >= NEEDS_SOON_THRESHOLD:
            irr_to_apply = net_irrigation_need if net_irrigation_need > 0 else 18.0
            return self._build_response(
                status="needs_soon",
                display="Needs Soon",
                irrigation_mm=irr_to_apply,
                description="Irrigation needed",
                color="yellow",
                eto_mm=eto_mm,
                kc=kc,
                etc_mm=etc_mm,
                effective_rain=effective_rain,
                irrigation_need=net_irrigation_need,
                kc_status=kc_status,
                kc_confidence=kc_confidence,
            )

        # 4. Irrigation Needed
        elif supply_fraction >= IRRIGATION_NEEDED_THRESHOLD:
            return self._build_response(
                status="irrigation_needed",
                display="Irrigation Needed",
                irrigation_mm=net_irrigation_need,
                description="Water your crop soon",
                color="orange",
                eto_mm=eto_mm,
                kc=kc,
                etc_mm=etc_mm,
                effective_rain=effective_rain,
                irrigation_need=net_irrigation_need,
                kc_status=kc_status,
                kc_confidence=kc_confidence,
            )

        # 5. Water Stress
        else:
            return self._build_response(
                status="high_stress",
                display="Water Stress",
                irrigation_mm=net_irrigation_need,
                description="Irrigation recommended",
                color="red",
                eto_mm=eto_mm,
                kc=kc,
                etc_mm=etc_mm,
                effective_rain=effective_rain,
                irrigation_need=net_irrigation_need,
                kc_status=kc_status,
                kc_confidence=kc_confidence,
            )

    def _build_response(
        self,
        status: str,
        display: str,
        irrigation_mm: float,
        description: str,
        color: str,
        eto_mm: float,
        kc: float,
        etc_mm: float,
        effective_rain: float,
        irrigation_need: float,
        kc_status: str = "established",
        kc_confidence: str = "high",
    ) -> Dict[str, Any]:
        return {
            "status": status,
            "status_display": display,
            "irrigation_mm": irrigation_mm,
            "description": description,
            "color": color,
            "kc_status": kc_status,
            "kc_confidence": kc_confidence,
            "calculation": {
                "crop_water_demand_etc_mm": etc_mm,
                "eto_mm": eto_mm,
                "kc": round(kc, 3),
                "effective_rainfall_mm": effective_rain,
                "net_irrigation_need_mm": irrigation_need,
            },
        }


water_service = WaterService()
