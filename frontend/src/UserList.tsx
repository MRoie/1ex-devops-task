import React, { useState, useEffect } from 'react';
import { User, fetchUsers, deleteUser, ApiError } from './api';
import UserForm from './UserForm';

const UserList: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [isAddingUser, setIsAddingUser] = useState(false);
  const [optimisticDeletes, setOptimisticDeletes] = useState<Set<string>>(new Set());

  // Format the date to a readable format
  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  };

  // Load users from API
  const loadUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchUsers();
      setUsers(data);
    } catch (err) {
      // Instead of setting error, just log it and continue with empty users array
      console.error('Failed to load users:', err);
      // Leave users as an empty array
    } finally {
      setLoading(false);
    }
  };

  // Load users on component mount
  useEffect(() => {
    loadUsers();
  }, []);

  // Handle user deletion with optimistic update
  const handleDeleteUser = async (user: User) => {
    if (!confirm(`Are you sure you want to delete ${user.name}?`)) {
      return;
    }

    // Add to optimistic deletes set
    setOptimisticDeletes(prev => new Set(prev).add(user.id));

    try {
      await deleteUser(user.id);
      // Remove user from the list after successful deletion
      setUsers(currentUsers => currentUsers.filter(u => u.id !== user.id));
    } catch (err) {
      const apiError = err as ApiError;
      setError(`Failed to delete user: ${apiError.message}`);
      
      // Remove from optimistic deletes if the API call failed
      setOptimisticDeletes(prev => {
        const newSet = new Set(prev);
        newSet.delete(user.id);
        return newSet;
      });
    }
  };

  // Handle successful user creation or update
  const handleUserSuccess = (user: User) => {
    if (editingUser) {
      // Update existing user
      setUsers(currentUsers => 
        currentUsers.map(u => u.id === user.id ? user : u)
      );
      setEditingUser(null);
    } else {
      // Add new user
      setUsers(currentUsers => [...currentUsers, user]);
      setIsAddingUser(false);
    }
  };

  // Render the user list UI
  return (
    <div className="container mx-auto px-4 py-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-[#001424]">Users</h1>
        <div className="flex space-x-2">
          <button
            onClick={() => setIsAddingUser(true)}
            className="bg-[#001424] hover:bg-[#002c4a] text-white px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-[#003a61]"
            disabled={isAddingUser}
          >
            Add User
          </button>
          <button
            onClick={loadUsers}
            className="bg-gray-200 hover:bg-gray-300 text-[#001424] px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-gray-500"
          >
            Refresh
          </button>
        </div>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border-l-4 border-red-500 p-4 text-red-700">
          <p className="font-medium">Error</p>
          <p>{error}</p>
          <button 
            onClick={() => setError(null)}
            className="mt-2 text-red-700 hover:text-red-900 font-medium"
          >
            Dismiss
          </button>
        </div>
      )}

      {isAddingUser && (
        <UserForm
          onSuccess={handleUserSuccess}
          onCancel={() => setIsAddingUser(false)}
        />
      )}

      {editingUser && (
        <UserForm
          user={editingUser}
          onSuccess={handleUserSuccess}
          onCancel={() => setEditingUser(null)}
        />
      )}

      {loading ? (
        <div className="flex justify-center items-center py-8">
          <svg className="animate-spin h-8 w-8 text-[#001424]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="ml-2 text-gray-700">Loading users...</span>
        </div>
      ) : users.length === 0 ? (
        <div className="bg-white shadow-md rounded-lg p-8 text-center">
          <svg xmlns="http://www.w3.org/2000/svg" className="h-16 w-16 mx-auto text-[#001424] mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
          <h3 className="text-lg font-medium text-[#001424] mb-2">No users found</h3>
          <p className="text-gray-600 mb-6">Get started by creating your first user</p>
          <button
            onClick={() => setIsAddingUser(true)}
            className="bg-[#001424] hover:bg-[#002c4a] text-white px-6 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-[#003a61]"
          >
            Create New User
          </button>
        </div>
      ) : (
        <div className="bg-white shadow-md rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-[#001424] text-white">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider">Name</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider">Email</th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider">Created At</th>
                <th scope="col" className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {users
                .filter(user => !optimisticDeletes.has(user.id))
                .map(user => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{user.name}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{user.email}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{formatDate(user.created_at)}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      onClick={() => setEditingUser(user)}
                      className="text-[#0054aa] hover:text-[#003a61] mr-4"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDeleteUser(user)}
                      className="text-red-600 hover:text-red-900"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default UserList;