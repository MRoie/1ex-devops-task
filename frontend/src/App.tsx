import UserList from './UserList';

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hero section with logo */}
      <div className="bg-[#001424] w-full py-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-center">
          <img 
            src="https://1etx.com/wp-content/uploads/2022/10/logo.svg" 
            alt="1etx Logo" 
            className="h-12"
          />
        </div>
      </div>
      
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-bold text-[#001424]">
            DevOps Home Assignment – Simple user management
          </h1>
        </div>
      </header>
      <main>
        <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
          <UserList />
        </div>
      </main>
    </div>
  );
}
