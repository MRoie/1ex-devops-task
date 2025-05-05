// Import testing-library utilities
import '@testing-library/jest-dom';
import { vi, afterEach } from 'vitest';

// Make sure vi is available globally
global.vi = vi;

// Reset all mocks after each test
afterEach(() => {
  vi.resetAllMocks();
});

// Global beforeAll, afterEach, and afterAll hooks can be defined here if needed