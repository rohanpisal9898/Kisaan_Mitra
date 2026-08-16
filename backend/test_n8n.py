import asyncio
from app.database import connect_to_mongo, get_database, close_mongo_connection
from app.services.n8n_notifications import n8n_notification_service

async def main():
    await connect_to_mongo()
    db = await get_database()
    # Find a user first
    user = await db.users.find_one({'phone_number': '1234567894'})
    if not user:
        user = await db.users.find_one()
    if user:
        print(f"Testing for user {user.get('phone_number')}")
        await n8n_notification_service.trigger_farmer_notification(db, str(user['_id']))
    else:
        print('No user found in DB')
    await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(main())
