import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import UserForm from '../src/UserForm';
import * as api from '../src/api';

// Mock the API functions
vi.mock('../src/api', () => ({
  createUser: vi.fn(),
  updateUser: vi.fn(),
  ApiError: class ApiError extends Error {
    status: number;
    constructor(message: string, status: number) {
      super(message);
      this.status = status;
      this.name = 'ApiError';
    }
  }
}));

describe('UserForm Component', () => {
  const mockUser = {
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'John Doe',
    email: 'john@example.com',
    created_at: '2023-01-01T12:00:00.000Z'
  };

  const mockSuccessHandler = vi.fn();
  const mockCancelHandler = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    (api.createUser as any).mockResolvedValue(mockUser);
    (api.updateUser as any).mockResolvedValue({
      ...mockUser,
      name: 'Updated John',
      email: 'updated@example.com'
    });
  });

  it('renders empty form for creating a new user', () => {
    render(
      <UserForm 
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );

    // Title should indicate creation mode
    expect(screen.getByText('Add New User')).toBeInTheDocument();
    
    // Inputs should be empty
    const nameInput = screen.getByLabelText('Name') as HTMLInputElement;
    const emailInput = screen.getByLabelText('Email') as HTMLInputElement;
    
    expect(nameInput.value).toBe('');
    expect(emailInput.value).toBe('');
    
    // Buttons should be present
    expect(screen.getByText('Save')).toBeInTheDocument();
    expect(screen.getByText('Cancel')).toBeInTheDocument();
  });

  it('renders form with user data for editing', () => {
    render(
      <UserForm 
        user={mockUser}
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );

    // Title should indicate edit mode
    expect(screen.getByText('Edit User')).toBeInTheDocument();
    
    // Inputs should have the user's data
    const nameInput = screen.getByLabelText('Name') as HTMLInputElement;
    const emailInput = screen.getByLabelText('Email') as HTMLInputElement;
    
    expect(nameInput.value).toBe(mockUser.name);
    expect(emailInput.value).toBe(mockUser.email);
  });

  it('handles form submission for new user', async () => {
    render(
      <UserForm 
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );

    // Fill in the form
    const nameInput = screen.getByLabelText('Name');
    const emailInput = screen.getByLabelText('Email');
    
    fireEvent.change(nameInput, { target: { value: 'New User' } });
    fireEvent.change(emailInput, { target: { value: 'new@example.com' } });
    
    // Submit the form
    fireEvent.click(screen.getByText('Save'));
    
    // Check API call was made with correct data
    expect(api.createUser).toHaveBeenCalledWith({
      name: 'New User',
      email: 'new@example.com'
    });
    
    // Check success callback was called
    await waitFor(() => {
      expect(mockSuccessHandler).toHaveBeenCalledWith(mockUser);
    });
  });

  it('handles form submission for updating user', async () => {
    render(
      <UserForm 
        user={mockUser}
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );

    // Update form fields
    const nameInput = screen.getByLabelText('Name');
    const emailInput = screen.getByLabelText('Email');
    
    fireEvent.change(nameInput, { target: { value: 'Updated John' } });
    fireEvent.change(emailInput, { target: { value: 'updated@example.com' } });
    
    // Submit the form
    fireEvent.click(screen.getByText('Save'));
    
    // Check API call was made with correct data
    expect(api.updateUser).toHaveBeenCalledWith(mockUser.id, {
      name: 'Updated John',
      email: 'updated@example.com'
    });
    
    // Check success callback was called
    await waitFor(() => {
      expect(mockSuccessHandler).toHaveBeenCalledWith({
        ...mockUser,
        name: 'Updated John',
        email: 'updated@example.com'
      });
    });
  });

  it('handles form validation', async () => {
    render(
      <UserForm 
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );

    // Submit with empty fields
    fireEvent.click(screen.getByText('Save'));
    
    // Check for validation errors
    await waitFor(() => {
      expect(screen.getByText(/name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
    });
    
    // API should not be called
    expect(api.createUser).not.toHaveBeenCalled();
    
    // Fill only name and submit
    const nameInput = screen.getByLabelText('Name');
    fireEvent.change(nameInput, { target: { value: 'New User' } });
    fireEvent.click(screen.getByText('Save'));
    
    // Should still show email validation error
    await waitFor(() => {
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
      expect(screen.queryByText(/name is required/i)).not.toBeInTheDocument();
    });
    
    // Fill invalid email format
    const emailInput = screen.getByLabelText('Email');
    fireEvent.change(emailInput, { target: { value: 'invalid-email' } });
    fireEvent.click(screen.getByText('Save'));
    
    // Should show email format error
    await waitFor(() => {
      expect(screen.getByText(/invalid email format/i)).toBeInTheDocument();
    });
  });

  it('handles API errors during form submission', async () => {
    // Mock API error
    (api.createUser as any).mockRejectedValue(new api.ApiError('Email already taken', 400));
    
    render(
      <UserForm 
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );

    // Fill in the form
    const nameInput = screen.getByLabelText('Name');
    const emailInput = screen.getByLabelText('Email');
    
    fireEvent.change(nameInput, { target: { value: 'New User' } });
    fireEvent.change(emailInput, { target: { value: 'new@example.com' } });
    
    // Submit the form
    fireEvent.click(screen.getByText('Save'));
    
    // Check error message is displayed
    await waitFor(() => {
      expect(screen.getByText(/email already taken/i)).toBeInTheDocument();
    });
    
    // Success handler should not be called
    expect(mockSuccessHandler).not.toHaveBeenCalled();
  });

  it('calls onCancel when cancel button is clicked', () => {
    render(
      <UserForm 
        onSuccess={mockSuccessHandler} 
        onCancel={mockCancelHandler} 
      />
    );
    
    // Click cancel button
    fireEvent.click(screen.getByText('Cancel'));
    
    // Check cancel handler was called
    expect(mockCancelHandler).toHaveBeenCalled();
  });
});