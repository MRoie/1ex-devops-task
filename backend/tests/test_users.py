import pytest
import uuid
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base
from app.main import app, get_db
from app.models import User

# Always use SQLite for tests
TEST_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False}
)

# Create the session factory for tests
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def test_db():
    # Create test database tables
    Base.metadata.create_all(bind=engine)
    yield
    # Drop test database tables after tests
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client(test_db):
    # Override the get_db dependency to use the test database
    def override_get_db():
        try:
            db = TestingSessionLocal()
            yield db
        finally:
            db.close()
    
    # Override the get_db dependency in the app
    app.dependency_overrides[get_db] = override_get_db
    
    # Create test client
    with TestClient(app) as client:
        yield client
    
    # Clear overrides after testing
    app.dependency_overrides.clear()

@pytest.fixture
def test_user(client):
    # Create a test user
    user_data = {
        "name": "Test User",
        "email": "test@example.com"
    }
    response = client.post("/api/users", json=user_data)
    return response.json()

def test_create_user(client):
    """Test creating a new user"""
    # Arrange
    user_data = {
        "name": "John Doe",
        "email": "john@example.com"
    }
    
    # Act
    response = client.post("/api/users", json=user_data)
    
    # Assert
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == user_data["name"]
    assert data["email"] == user_data["email"]
    assert "id" in data
    assert "created_at" in data

def test_create_user_duplicate_email(client, test_user):
    """Test creating a user with a duplicate email"""
    # Arrange
    user_data = {
        "name": "Another User",
        "email": test_user["email"]  # Use the same email as the test user
    }
    
    # Act
    response = client.post("/api/users", json=user_data)
    
    # Assert
    assert response.status_code == 400
    assert "Email already registered" in response.text

def test_get_users(client, test_user):
    """Test getting all users"""
    # Act
    response = client.get("/api/users")
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    assert any(user["id"] == test_user["id"] for user in data)

def test_get_user(client, test_user):
    """Test getting a specific user by ID"""
    # Act
    response = client.get(f"/api/users/{test_user['id']}")
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == test_user["id"]
    assert data["name"] == test_user["name"]
    assert data["email"] == test_user["email"]

def test_get_user_not_found(client):
    """Test getting a non-existent user"""
    # Act
    non_existent_id = str(uuid.uuid4())
    response = client.get(f"/api/users/{non_existent_id}")
    
    # Assert
    assert response.status_code == 404
    assert "User not found" in response.text

def test_update_user(client, test_user):
    """Test updating a user"""
    # Arrange
    update_data = {
        "name": "Updated Name",
        "email": "updated@example.com"
    }
    
    # Act
    response = client.put(f"/api/users/{test_user['id']}", json=update_data)
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == test_user["id"]
    assert data["name"] == update_data["name"]
    assert data["email"] == update_data["email"]

def test_update_user_partial(client, test_user):
    """Test partially updating a user"""
    # Arrange
    update_data = {
        "name": "Partial Update"
        # No email provided
    }
    
    # Act
    response = client.put(f"/api/users/{test_user['id']}", json=update_data)
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == test_user["id"]
    assert data["name"] == update_data["name"]
    assert data["email"] == test_user["email"]  # Email should remain unchanged

def test_update_user_not_found(client):
    """Test updating a non-existent user"""
    # Arrange
    update_data = {
        "name": "Update Non-existent",
        "email": "nonexistent@example.com"
    }
    
    # Act
    non_existent_id = str(uuid.uuid4())
    response = client.put(f"/api/users/{non_existent_id}", json=update_data)
    
    # Assert
    assert response.status_code == 404
    assert "User not found" in response.text

def test_delete_user(client, test_user):
    """Test deleting a user"""
    # Act
    response = client.delete(f"/api/users/{test_user['id']}")
    
    # Assert
    assert response.status_code == 204
    
    # Verify the user is actually deleted
    get_response = client.get(f"/api/users/{test_user['id']}")
    assert get_response.status_code == 404

def test_delete_user_not_found(client):
    """Test deleting a non-existent user"""
    # Act
    non_existent_id = str(uuid.uuid4())
    response = client.delete(f"/api/users/{non_existent_id}")
    
    # Assert
    assert response.status_code == 404
    assert "User not found" in response.text