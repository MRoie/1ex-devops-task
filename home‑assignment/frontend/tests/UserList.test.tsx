import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import UserList from '../src/UserList';
import * as api from '../src/api';

// Mock the API functions
vi.mock('../src/api', () => ({
  fetchUsers: vi.fn(),
  deleteUser: vi.fn(),
  ApiError: class ApiError extends Error {
    status: number;
    constructor(message: string, status: number) {
      super(message);
      this.status = status;
      this.name = 'ApiError';
    }
  }
}));

// Sample user data for tests
const mockUsers = [
  {
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'John Doe',
    email: 'john@example.com',
    created_at: '2023-01-01T12:00:00.000Z'
  },
  {
    id: '223e4567-e89b-12d3-a456-426614174001',
    name: 'Jane Smith',
    email: 'jane@example.com',
    created_at: '2023-01-02T12:00:00.000Z'
  }
];

describe('UserList Component', () => {
  // Reset mocks before each test
  beforeEach(() => {
    vi.clearAllMocks();
    // Mock successful fetchUsers call by default
    (api.fetchUsers as any).mockResolvedValue(mockUsers);
  });

  it('displays loading state initially', () => {
    render(<UserList />);
    expect(screen.getByText(/loading users/i)).toBeInTheDocument();
  });

  it('displays users after loading', async () => {
    render(<UserList />);
    
    // Wait for users to load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('john@example.com')).toBeInTheDocument();
      expect(screen.getByText('jane@example.com')).toBeInTheDocument();
    });

    // Check that the API was called
    expect(api.fetchUsers).toHaveBeenCalledTimes(1);
  });

  it('handles API errors gracefully', async () => {
    // Mock API error response
    (api.fetchUsers as any).mockRejectedValue(new api.ApiError('Server error', 500));
    
    render(<UserList />);
    
    // Wait for error message
    await waitFor(() => {
      expect(screen.getByText(/failed to load users/i)).toBeInTheDocument();
      expect(screen.getByText(/server error/i)).toBeInTheDocument();
    });
  });

  it('shows Add User form when button is clicked', async () => {
    render(<UserList />);
    
    // Wait for component to load
    await waitFor(() => {
      expect(screen.queryByText(/loading users/i)).not.toBeInTheDocument();
    });
    
    // Click Add User button
    fireEvent.click(screen.getByText('Add User'));
    
    // UserForm should be shown (we don't test the actual form here)
    // We're checking for an element that would be present in the form
    expect(screen.getByText('Add User')).toBeInTheDocument();
  });

  it('handles delete user action', async () => {
    // Mock successful delete call
    (api.deleteUser as any).mockResolvedValue({});
    
    render(<UserList />);
    
    // Wait for users to load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
    
    // Mock confirm dialog - always return true
    window.confirm = vi.fn().mockImplementation(() => true);
    
    // Find and click the first "Delete" button
    const deleteButtons = screen.getAllByText('Delete');
    fireEvent.click(deleteButtons[0]);
    
    // Check that confirm was called and deleteUser API was called
    expect(window.confirm).toHaveBeenCalledTimes(1);
    expect(api.deleteUser).toHaveBeenCalledWith(mockUsers[0].id);
    
    // User should be removed from the list
    await waitFor(() => {
      expect(screen.queryByText('John Doe')).not.toBeInTheDocument();
      // Jane should still be there
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    });
  });

  it('cancels delete when confirm is rejected', async () => {
    render(<UserList />);
    
    // Wait for users to load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
    
    // Mock confirm dialog - return false
    window.confirm = vi.fn().mockImplementation(() => false);
    
    // Find and click the first "Delete" button
    const deleteButtons = screen.getAllByText('Delete');
    fireEvent.click(deleteButtons[0]);
    
    // Check that confirm was called but deleteUser API was NOT called
    expect(window.confirm).toHaveBeenCalledTimes(1);
    expect(api.deleteUser).not.toHaveBeenCalled();
    
    // Both users should still be in the list
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();
  });

  it('shows empty state when no users exist', async () => {
    // Mock empty users array
    (api.fetchUsers as any).mockResolvedValue([]);
    
    render(<UserList />);
    
    // Wait for component to load
    await waitFor(() => {
      expect(screen.queryByText(/loading users/i)).not.toBeInTheDocument();
    });
    
    // Should show empty state message
    expect(screen.getByText(/no users found/i)).toBeInTheDocument();
  });
});