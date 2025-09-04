import { useAuth0 } from '@auth0/auth0-react';
import * as NavigationMenu from '@radix-ui/react-navigation-menu';
import { ChevronDown, CircleDollarSign, Home, LogOut, Settings, User } from 'lucide-react';
import { useLocation } from 'wouter';
import { APP_CONFIG } from '../../config';

export const AppHeader = () => {
  const { user, logout, isAuthenticated } = useAuth0();
  const [_, navigate] = useLocation();

  const handleLogout = () => {
    logout({
      logoutParams: {
        returnTo: window.location.origin
      }
    });
  };

  const handleGoHome = () => {
    navigate('/home');
  };

  return (
    <header className="bg-white border-b border-gray-200 shadow-sm">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center">
            <h1 className="text-xl font-bold text-midnight-green cursor-pointer flex gap-x-2" onClick={handleGoHome}>
              <Home /> {APP_CONFIG.app.name}
            </h1>
          </div>

          <nav className="flex items-center space-x-4">
            <a href="/price" className="flex items-center space-x-2 text-gray-700 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium">
              <CircleDollarSign className="h-4 w-4" />
              <span>Price</span>
            </a>

            <NavigationMenu.Root className="relative">
              <NavigationMenu.List>
                <NavigationMenu.Item>
                  <NavigationMenu.Trigger className="flex items-center space-x-2 text-gray-700 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium bg-transparent border-0">
                    <User className="h-4 w-4" />
                    <span>{user?.name}</span>
                    <ChevronDown className="h-4 w-4" />
                  </NavigationMenu.Trigger>
                  {isAuthenticated && <NavigationMenu.Content className="absolute top-full right-0 bg-white border border-gray-200 rounded-md shadow-lg p-2 min-w-48 z-50">
                    <div className="space-y-1">
                      <a
                        href="/profile"
                        className="flex items-center space-x-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded"
                      >
                        <User className="h-4 w-4" />
                        <span>Profile</span>
                      </a>
                      <a
                        href="/settings"
                        className="flex items-center space-x-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded"
                      >
                        <Settings className="h-4 w-4" />
                        <span>Settings</span>
                      </a>
                      <button
                        onClick={handleLogout}
                        className="flex items-center space-x-2 w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded"
                      >
                        <LogOut className="h-4 w-4" />
                        <span>Logout</span>
                      </button>
                    </div>
                  </NavigationMenu.Content>}
                </NavigationMenu.Item>
              </NavigationMenu.List>
            </NavigationMenu.Root>
          </nav>
        </div>
      </div>
    </header>
  );
};

export default AppHeader;