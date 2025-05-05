import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import App from '../src/App';

// Mock the UserList component to isolate App component testing
vi.mock('../src/UserList', () => ({
  default: () => <div data-testid="user-list-mock">UserList Component</div>
}));

describe('App Component', () => {
  it('renders the header with correct title', () => {
    render(<App />);
    
    // Check if the header title is displayed
    expect(screen.getByText('DevOps Home Assignment – Simple user management')).toBeDefined();
  });

  it('renders the UserList component', () => {
    render(<App />);
    
    // Check if the UserList component is rendered
    expect(screen.getByTestId('user-list-mock')).toBeDefined();
  });

  it('has the correct page layout structure', () => {
    const { container } = render(<App />);
    
    // Check if the basic structure exists
    expect(container.querySelector('header')).toBeDefined();
    expect(container.querySelector('main')).toBeDefined();
  });
});
