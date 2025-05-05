// User type definition
export interface User {
  id: string;
  name: string;
  email: string;
  created_at: string;
}

export interface UserInput {
  name: string;
  email: string;
}

// API error handling
export class ApiError extends Error {
  status: number;
  
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
    this.name = 'ApiError';
  }
}

// Helper function to handle API responses
async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Unknown error' }));
    throw new ApiError(error.message || response.statusText, response.status);
  }
  
  // For 204 No Content responses
  if (response.status === 204) {
    return {} as T;
  }
  
  return response.json();
}

// Get all users
export async function fetchUsers(): Promise<User[]> {
  const res = await fetch("/api/users");
  return handleResponse<User[]>(res);
}

// Get a single user by ID
export async function fetchUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  return handleResponse<User>(res);
}

// Create a new user
export async function createUser(userData: UserInput): Promise<User> {
  const res = await fetch("/api/users", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(userData),
  });
  
  return handleResponse<User>(res);
}

// Update an existing user
export async function updateUser(id: string, userData: Partial<UserInput>): Promise<User> {
  const res = await fetch(`/api/users/${id}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(userData),
  });
  
  return handleResponse<User>(res);
}

// Delete a user
export async function deleteUser(id: string): Promise<void> {
  const res = await fetch(`/api/users/${id}`, {
    method: "DELETE",
  });
  
  return handleResponse<void>(res);
}
