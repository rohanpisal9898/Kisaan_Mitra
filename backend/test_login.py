import asyncio
from app.database import connect_to_mongo, get_database, close_mongo_connection
from app.models.user import UserLoginRequest
from app.routers.users import login_user
from fastapi import BackgroundTasks

async def main():
    await connect_to_mongo()
    db = await get_database()
    req = UserLoginRequest(phone_number='1234567894', password='123456')
    bt = BackgroundTasks()
    try:
        user = await login_user(req, bt, db)
        print(f'Login success: {user.phone_number}')
        # execute background tasks
        for task in bt.tasks:
            await task.func(*task.args, **task.kwargs)
    except Exception as e:
        print(f'Login failed: {e}')
    finally:
        await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(main())
