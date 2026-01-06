from fastapi import FastAPI, HTTPException, Depends, status
from pydantic import BaseModel
from typing import Optional, List
import psycopg2
from psycopg2.extras import RealDictCursor
from passlib.context import CryptContext
from pydantic import BaseModel
import uvicorn
import hashlib

app = FastAPI()

# ---------------------------------------------------------
# 🔐 Database & Security Config
# ---------------------------------------------------------
DB_CONNECTION_STRING = "postgresql://neondb_owner:npg_GaVfJ9jwl7cL@ep-flat-wave-a1a03jce-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ---------------------------------------------------------
# 📝 Pydantic Models (Request Bodies)
# ---------------------------------------------------------
class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class Recipe(BaseModel):
    title: str
    description: Optional[str] = None
    cooking_method: Optional[str] = None
    image_url: Optional[str] = None
    prep_time: Optional[int] = None

# ---------------------------------------------------------
# 🛠️ Helper Functions
# ---------------------------------------------------------
def get_db_connection():
    try:
        conn = psycopg2.connect(DB_CONNECTION_STRING, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        print(f"Error connecting to DB: {e}")
        return None

def verify_password(plain_password, hashed_password):
    # Pre-hash with SHA256 to support passwords > 72 bytes
    if plain_password is None:
        return False
    # Use hexdigest to get a consistent string representation, or digest for bytes.
    # Passing the sha256 hex string to bcrypt is a standard workaround.
    # It ensures the input to bcrypt is always 64 bytes (hex) which is < 72.
    password_hash = hashlib.sha256(plain_password.encode('utf-8')).hexdigest()
    return pwd_context.verify(password_hash, hashed_password)

def get_password_hash(password):
    # Pre-hash with SHA256 to support passwords > 72 bytes
    password_hash = hashlib.sha256(password.encode('utf-8')).hexdigest()
    return pwd_context.hash(password_hash)

# ---------------------------------------------------------
# 🚀 API Endpoints
# ---------------------------------------------------------

@app.get("/")
def read_root():
    return {"message": "Find My Food Backend is running!"}

@app.post("/register", status_code=status.HTTP_201_CREATED)
def register(user: UserRegister):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    try:
        cur = conn.cursor()
        
        # Check if email already exists
        cur.execute("SELECT user_id FROM users WHERE email = %s", (user.email,))
        if cur.fetchone():
            cur.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Email already registered")

        # Hash password and insert
        hashed_pw = get_password_hash(user.password)
        cur.execute("""
            INSERT INTO users (username, email, password_hash, created_at)
            VALUES (%s, %s, %s, NOW())
            RETURNING user_id, username, email
        """, (user.username, user.email, hashed_pw))
        
        new_user = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return {"message": "User created successfully", "user": new_user}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/login")
def login(user: UserLogin):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE email = %s", (user.email,))
        db_user = cur.fetchone()
        cur.close()
        conn.close()

        if not db_user or not verify_password(user.password, db_user['password_hash']):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Return user info (In a real app, you'd return a JWT token here)
        return {
            "message": "Login successful",
            "user": {
                "user_id": db_user["user_id"],
                "username": db_user["username"],
                "email": db_user["email"],
                "profile_image": db_user["profile_image"]
            }
        }

    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ---------------------------------------------------------
# 🍲 Recipes Endpoints
# ---------------------------------------------------------

@app.get("/recipes")
def get_recipes(search: Optional[str] = None):
    conn = get_db_connection()
    if conn is None:
        raise HTTPException(status_code=500, detail="Cannot connect to Database")
    
    try:
        cur = conn.cursor()
        query = "SELECT * FROM recipes WHERE is_public = TRUE"
        params = []

        if search:
            query += " AND (LOWER(title) LIKE %s OR LOWER(description) LIKE %s)"
            search_term = f"%{search.lower()}%"
            params = [search_term, search_term]
        
        cur.execute(query, tuple(params))
        recipes = cur.fetchall()
        
        cur.close()
        conn.close()
        return recipes

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ---------------------------------------------------------
# ❤️ Favorites Endpoints
# ---------------------------------------------------------
class FavoriteItem(BaseModel):
    user_id: int
    recipe_id: int

@app.get("/favorites/{user_id}")
def get_favorites(user_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        # Join recipes to show details
        cur.execute("""
            SELECT r.* FROM favorites f
            JOIN recipes r ON f.recipe_id = r.recipe_id
            WHERE f.user_id = %s
        """, (user_id,))
        favorites = cur.fetchall()
        cur.close()
        conn.close()
        return favorites
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/favorites")
def add_favorite(fav: FavoriteItem):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO favorites (user_id, recipe_id, liked_at)
            VALUES (%s, %s, NOW())
            ON CONFLICT (user_id, recipe_id) DO NOTHING
        """, (fav.user_id, fav.recipe_id))
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Added to favorites"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/favorites/{user_id}/{recipe_id}")
def remove_favorite(user_id: int, recipe_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM favorites WHERE user_id = %s AND recipe_id = %s", (user_id, recipe_id))
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Removed from favorites"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ---------------------------------------------------------
# 🛒 Shopping List Endpoints
# ---------------------------------------------------------
class ShoppingItem(BaseModel):
    user_id: int
    item_name: str

@app.get("/shopping_list/{user_id}")
def get_shopping_list(user_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM shopping_list WHERE user_id = %s ORDER BY created_at DESC", (user_id,))
        items = cur.fetchall()
        cur.close()
        conn.close()
        return items
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/shopping_list")
def add_shopping_item(item: ShoppingItem):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO shopping_list (user_id, item_name, is_checked, created_at)
            VALUES (%s, %s, FALSE, NOW())
            RETURNING id
        """, (item.user_id, item.item_name))
        new_id = cur.fetchone()['id']
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Item added", "id": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/shopping_list/{item_id}/toggle")
def toggle_shopping_item(item_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("UPDATE shopping_list SET is_checked = NOT is_checked WHERE id = %s", (item_id,))
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Toggled status"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/shopping_list/{item_id}")
def delete_shopping_item(item_id: int):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM shopping_list WHERE id = %s", (item_id,))
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Deleted item"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ---------------------------------------------------------
# 🥦 Ingredients Endpoints (For Scanner)
# ---------------------------------------------------------
@app.get("/ingredients")
def get_ingredients():
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="DB Connection failed")
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM ingredients")
        ingredients = cur.fetchall()
        cur.close()
        conn.close()
        return ingredients
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
