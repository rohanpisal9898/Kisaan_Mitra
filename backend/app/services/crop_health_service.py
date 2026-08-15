"""
Phenology-Aware Crop Health Scoring Service for Kisaan Mitra.

Compares real satellite observations against evidence-tagged crop- and stage-specific
phenological benchmarks (NDVI, NDRE, EVI, NDMI, Sentinel-1 VV/VH).

Health Categories:
  80–100 → Good
  60–79  → Monitor (renamed from Watch)
  40–59  → Needs Attention
  0–39   → Poor
  score=None → Unavailable (stale >30 days or missing satellite data)
"""

import json
from pathlib import Path
from typing import Dict, Any, Optional, List
from datetime import date, timedelta
from app.config import get_settings
from app.services.crop_stage_service import crop_stage_service

settings = get_settings()

INDEX_WEIGHTS = {
    "NDVI": 0.30,
    "NDRE": 0.20,
    "EVI": 0.20,
    "NDMI": 0.15,
    "S1_VV": 0.08,
    "S1_VH": 0.07,
}

HEALTH_DISPLAY = {
    "good": "Good",
    "monitor": "Monitor",
    "needs_attention": "Needs Attention",
    "poor": "Poor",
    "unavailable": "Unavailable",
}

HEALTH_DESC = {
    "good": "Your crop is growing normally",
    "monitor": "Your crop needs regular monitoring.",
    "needs_attention": "Your crop needs attention",
    "poor": "Your crop needs immediate attention",
    "unavailable": "Latest satellite image is unavailable or too old to assess crop health",
}

# Static JSON benchmark data loader
_BENCHMARK_CACHE: Optional[Dict[str, Any]] = None


def _load_json_benchmarks() -> Dict[str, Any]:
    global _BENCHMARK_CACHE
    if _BENCHMARK_CACHE is not None:
        return _BENCHMARK_CACHE

    json_path = Path(__file__).parent.parent.parent / "data" / "crop_health_benchmarks.json"
    if json_path.exists():
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                _BENCHMARK_CACHE = json.load(f)
                return _BENCHMARK_CACHE
        except Exception as e:
            print(f"[CROP HEALTH WARNING] Failed to load JSON benchmarks: {e}")

    _BENCHMARK_CACHE = {}
    return _BENCHMARK_CACHE


class CropHealthService:
    def get_benchmark(
        self, crop_id: str, stage_id: str, db: Optional[Any] = None
    ) -> Optional[Dict[str, Any]]:
        """Retrieves evidence-tagged benchmark for specific crop_id and stage_id."""
        normalized_crop = crop_stage_service._normalize_crop_id(crop_id)
        normalized_stage = stage_id.lower().strip()

        json_b = _load_json_benchmarks()
        if normalized_crop in json_b and normalized_stage in json_b[normalized_crop]:
            return json_b[normalized_crop][normalized_stage]

        # Fallback to soybean benchmark if crop specific benchmark is missing
        if "soybean" in json_b and normalized_stage in json_b["soybean"]:
            return json_b["soybean"][normalized_stage]

        return None

    def calculate_health(
        self,
        crop_profile: Dict[str, Any],
        stage_id: str,
        satellite_data: Optional[Dict[str, float]] = None,
        satellite_date: Optional[str] = None,
        is_baseline: bool = False,
        previous_satellite_data: Optional[Dict[str, float]] = None,
        db: Optional[Any] = None,
    ) -> Dict[str, Any]:

        crop_name = crop_profile.get("crop_id", "soybean") if crop_profile else "soybean"
        normalized_crop = crop_stage_service._normalize_crop_id(crop_name)
        normalized_stage = stage_id.lower().strip() if stage_id else "early_growth"

        # Default handling when no satellite data is provided
        if not satellite_data:
            if settings.use_mock_data:
                mock_dt = (date.today() - timedelta(days=4)).isoformat()
                return {
                    "status": "good",
                    "status_display": "Good",
                    "score": 86.0,
                    "description": "Your crop is growing normally",
                    "satellite_available": True,
                    "satellite_date": mock_dt,
                    "satellite_days_old": 4,
                    "satellite_note": None,
                    "crop_id": normalized_crop,
                    "stage_id": normalized_stage,
                    "available_indices": ["NDVI", "NDRE", "EVI", "NDMI"],
                    "missing_indices": ["S1_VV", "S1_VH"],
                    "index_scores": {"NDVI": 90.0, "NDRE": 85.0, "EVI": 88.0, "NDMI": 80.0},
                    "benchmark_metadata": {"evidence_level": "literature_supported"},
                }
            return {
                "status": "unavailable",
                "status_display": "Unavailable",
                "score": None,
                "description": "Latest satellite image is unavailable to assess current crop health.",
                "satellite_available": False,
                "satellite_date": None,
                "satellite_days_old": None,
                "satellite_note": "Satellite update is delayed",
                "crop_id": normalized_crop,
                "stage_id": normalized_stage,
                "available_indices": [],
                "missing_indices": ["NDVI", "NDRE", "EVI", "NDMI", "S1_VV", "S1_VH"],
                "index_scores": {},
                "benchmark_metadata": {},
            }

        # Calculate observation age and check freshness (>30 days)
        days_old = 0
        sat_note = None
        if satellite_date:
            try:
                days_old = (date.today() - date.fromisoformat(satellite_date[:10])).days
                if is_baseline:
                    sat_note = f"Pre-sowing baseline image from {satellite_date}"
                elif days_old > 30:
                    return {
                        "status": "unavailable",
                        "status_display": "Unavailable",
                        "score": None,
                        "description": "Latest satellite image is too old (>30 days) to assess current crop health.",
                        "satellite_available": False,
                        "satellite_date": satellite_date,
                        "satellite_days_old": days_old,
                        "satellite_note": "Satellite update is delayed",
                        "crop_id": normalized_crop,
                        "stage_id": normalized_stage,
                        "available_indices": [],
                        "missing_indices": ["NDVI", "NDRE", "EVI", "NDMI", "S1_VV", "S1_VH"],
                        "index_scores": {},
                        "benchmark_metadata": {},
                    }
                elif days_old > 14:
                    sat_note = f"Based on data from {satellite_date} (may be stale)"
                elif days_old > 7:
                    sat_note = f"Based on data from {satellite_date}"
            except (ValueError, TypeError):
                pass

        # Fetch evidence-tagged benchmark record for (normalized_crop, normalized_stage)
        bench_doc = self.get_benchmark(normalized_crop, normalized_stage, db=db)
        indices_bench = bench_doc.get("indices", {}) if bench_doc else {}
        evidence_meta = bench_doc.get("evidence", {}) if bench_doc else {}

        # Normalize key lookup for satellite_data (support case variations e.g. 'ndvi' vs 'NDVI')
        sat_keys_normalized = {k.upper(): v for k, v in satellite_data.items()}

        # Index mapping dictionary
        index_map = {
            "NDVI": ["NDVI", "ndvi"],
            "NDRE": ["NDRE", "ndre"],
            "EVI": ["EVI", "evi"],
            "NDMI": ["NDMI", "ndmi"],
            "S1_VV": ["S1_VV", "VV", "vv"],
            "S1_VH": ["S1_VH", "VH", "vh"],
        }

        available_indices: List[str] = []
        missing_indices: List[str] = []
        index_scores: Dict[str, float] = {}

        total_weight = 0.0
        weighted_score_sum = 0.0

        for canonical_idx, possible_keys in index_map.items():
            bench_item = indices_bench.get(canonical_idx, {})
            evidence_level = bench_item.get("evidence_level")

            # Exclude uncalibrated indices from weighted scoring
            if bench_item.get("status") == "calibration_required" or evidence_level == "insufficient":
                missing_indices.append(canonical_idx)
                continue

            # Find actual value in satellite_data
            actual_val = None
            for pkey in possible_keys:
                if pkey.upper() in sat_keys_normalized:
                    actual_val = sat_keys_normalized[pkey.upper()]
                    break

            if actual_val is None:
                missing_indices.append(canonical_idx)
                continue

            # Compute smooth continuous sub-score for supported index
            min_val = bench_item.get("min", 0.2)
            opt_min = bench_item.get("optimal_min", 0.4)
            opt_max = bench_item.get("optimal_max", 0.8)
            max_val = bench_item.get("max", 0.95)

            if opt_min <= actual_val <= opt_max:
                sub_score = 100.0
            elif actual_val < opt_min:
                denom = max(opt_min - min_val, 0.01)
                sub_score = max(0.0, 100.0 - ((opt_min - actual_val) / denom) * 80.0)
            else:
                denom = max(max_val - opt_max, 0.01)
                sub_score = max(20.0, 100.0 - ((actual_val - opt_max) / denom) * 40.0)

            sub_score = round(sub_score, 1)
            index_scores[canonical_idx] = sub_score
            available_indices.append(canonical_idx)

            w = INDEX_WEIGHTS.get(canonical_idx, 0.15)
            weighted_score_sum += sub_score * w
            total_weight += w

        # Return unavailable if no valid indices could be scored
        if total_weight == 0.0 or not index_scores:
            return {
                "status": "unavailable",
                "status_display": "Unavailable",
                "score": None,
                "description": "Insufficient satellite indices to compute crop health score.",
                "satellite_available": False,
                "satellite_date": satellite_date,
                "satellite_days_old": days_old,
                "satellite_note": sat_note,
                "crop_id": normalized_crop,
                "stage_id": normalized_stage,
                "available_indices": [],
                "missing_indices": missing_indices,
                "index_scores": {},
                "benchmark_metadata": evidence_meta,
            }

        # Renormalize weighted score
        condition_score = weighted_score_sum / total_weight

        # Optional Temporal Trend Calculation (15% weight max if prior observation exists)
        final_health_score = condition_score
        trend_applied = False
        if previous_satellite_data and "NDVI" in previous_satellite_data and "NDVI" in sat_keys_normalized:
            prev_ndvi = previous_satellite_data["NDVI"]
            curr_ndvi = sat_keys_normalized["NDVI"]
            delta = curr_ndvi - prev_ndvi
            expected_trend = bench_doc.get("trend", {}).get("NDVI", "increasing")

            trend_score = 80.0
            if expected_trend == "increasing" and delta >= -0.02:
                trend_score = 100.0
            elif expected_trend == "peak" and abs(delta) <= 0.05:
                trend_score = 100.0
            elif expected_trend == "decreasing" and delta <= 0.02:
                trend_score = 100.0

            final_health_score = 0.85 * condition_score + 0.15 * trend_score
            trend_applied = True

        health_score = round(final_health_score, 1)

        # Map to Health Status (using 'monitor' instead of 'watch')
        if health_score >= 80:
            status = "good"
        elif health_score >= 60:
            status = "monitor"
        elif health_score >= 40:
            status = "needs_attention"
        else:
            status = "poor"

        # Detailed Debug Log Output
        log_parts = [
            f"[CROP HEALTH DEBUG] crop={normalized_crop} stage={normalized_stage} obs_date={satellite_date} age_days={days_old}"
        ]
        for idx in ["NDVI", "NDRE", "EVI", "NDMI", "S1_VV", "S1_VH"]:
            if idx in index_scores:
                b_item = indices_bench.get(idx, {})
                log_parts.append(
                    f"{idx}={sat_keys_normalized.get(idx)} expected=[{b_item.get('optimal_min')}-{b_item.get('optimal_max')}] score={index_scores[idx]}"
                )
            elif idx in missing_indices:
                log_parts.append(f"{idx}=uncalibrated_or_missing")
        log_parts.append(f"final_score={health_score} status={status}")
        print(" ".join(log_parts))

        return {
            "status": status,
            "status_display": HEALTH_DISPLAY[status],
            "score": health_score,
            "description": HEALTH_DESC[status],
            "satellite_available": True,
            "satellite_date": satellite_date,
            "satellite_days_old": days_old,
            "satellite_note": sat_note,
            "crop_id": normalized_crop,
            "stage_id": normalized_stage,
            "available_indices": available_indices,
            "missing_indices": missing_indices,
            "index_scores": index_scores,
            "benchmark_metadata": evidence_meta,
        }


crop_health_service = CropHealthService()
