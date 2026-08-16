import httpx
import logging
from typing import Dict, Any, Optional
from bson import ObjectId
from app.services.water_service import water_service
from app.services.crop_stage_service import crop_stage_service
from app.services.weather_service import weather_service

logger = logging.getLogger(__name__)

N8N_WEBHOOK_URL = "https://chickentandoori65.app.n8n.cloud/webhook/kisaan-mitra/farm-update"

def normalize_phone_number(phone_number: str) -> str:
    phone = str(phone_number).strip()

    if not phone:
        return ""

    if phone.startswith("+91"):
        return phone

    if phone.startswith("91") and len(phone) == 12:
        return f"+{phone}"

    return f"+91{phone}"

class N8nNotificationService:
    async def trigger_farmer_notification(self, db, farmer_id: str):
        """Background task to trigger n8n notification after login/signup."""
        try:
            # 1. Fetch farmer
            try:
                query = {"_id": ObjectId(farmer_id)}
            except Exception:
                query = {"id": farmer_id} # Fallback if UUID or string

            user = await db.users.find_one(query)
            if not user:
                # If lookup by _id failed, maybe user.id maps to phone_number? Let's fallback if necessary
                user = await db.users.find_one({"phone_number": farmer_id})
                if not user:
                    logger.error(f"N8N Notification Failed\nFarmer ID: {farmer_id}\nReason: User not found in DB")
                    return

            phone_number = normalize_phone_number(
                user.get("phone_number", "")
            )
            logger.info(f"Normalized phone number: {phone_number}")
            
            farmer_name = user.get("farmer_name", "Farmer")
            current_crop = user.get("current_crop")
            sowing_date_str = user.get("sowing_date")
            latitude = user.get("latitude", 19.9975)
            longitude = user.get("longitude", 73.7898)

            water_status = None

            # 2. Re-use internal dashboard functions to compute water_status locally
            if current_crop and sowing_date_str:
                try:
                    # Fetch crop profile
                    crop_profile = await crop_stage_service.get_crop_profile(db, current_crop)
                    
                    # Calculate stage
                    stage_res = crop_stage_service.calculate_stage(crop_profile or {}, sowing_date_str)
                    days_after_sowing = stage_res.get("days_after_sowing", 60)
                    
                    # Get weather for ET0 and rain
                    weather_res = await weather_service.get_weather(db, latitude, longitude)
                    rain_info = weather_res.get("rain", {})
                    forecast_list = weather_res.get("forecast", [])
                    
                    raw_et0 = weather_res.get("et0_mm")
                    if raw_et0 is None and forecast_list and len(forecast_list) > 0:
                        raw_et0 = forecast_list[0].get("eto_mm")
                    eto_mm = round(float(raw_et0), 2) if raw_et0 is not None else 4.5
                    forecast_rain_mm = float(rain_info.get("amount_mm") or 0.0)

                    # Compute water status
                    water_res = water_service.calculate_water_status(
                        crop_profile or {}, days_after_sowing, eto_mm, forecast_rain_mm
                    )
                    water_status = water_res.get("status")
                except Exception as e:
                    logger.warning(f"Could not compute water status for {farmer_id}: {e}")

            # 3. Build payload
            payload = self.build_notification_payload(
                farmer_id=str(user.get("_id", farmer_id)),
                farmer_name=farmer_name,
                phone_number=phone_number,
                crop=current_crop or "None",
                water_status=water_status
            )
            print(f"[N8N] Sending payload: {payload}")
            logger.info(f"N8N Payload: {payload}")

            # 4. Send webhook
            await self.send_notification_to_n8n(payload)
            
            print(f"[N8N] Notification sent successfully for {farmer_id}")
            logger.info(f"N8N Notification Sent Successfully: {farmer_id}")

        except Exception as e:
            print(f"[N8N] ERROR: {e}")
            logger.error(f"N8N Notification Failed: {str(e)}")

    def build_notification_payload(
        self,
        farmer_id: str,
        farmer_name: str,
        phone_number: str,
        crop: str,
        water_status: Optional[str]
    ) -> Dict[str, Any]:
        """Builds the notification payload and message text."""
        message = "Kisaan Mitra Advisory: Farm status updated. Open the app for latest recommendations."
        
        if water_status == "rain_sufficient":
            message = "Kisaan Mitra Advisory: Rain may cover water needs. No irrigation today."
        elif water_status == "good":
            message = "Kisaan Mitra Advisory: Water status is good. No irrigation today."
        elif water_status == "needs_soon":
            message = "Kisaan Mitra Advisory: Irrigation may be needed soon. Prepare to water."
        elif water_status == "irrigation_needed":
            message = "Kisaan Mitra Advisory: Irrigation recommended. Water your crop soon."
        elif water_status == "high_stress":
            message = "Kisaan Mitra Advisory: Water stress detected. Irrigate immediately."

        return {
            "farmer_name": farmer_name,
            "phone_number": phone_number,
            "crop": crop,
            "water_status": water_status or "unknown",
            "message": message
        }

    async def send_notification_to_n8n(self, payload: Dict[str, Any]):
        """Posts the notification to the n8n webhook asynchronously."""
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(N8N_WEBHOOK_URL, json=payload)
            response.raise_for_status()


n8n_notification_service = N8nNotificationService()
