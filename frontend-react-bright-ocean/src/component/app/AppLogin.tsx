import { useAuth0 } from "@auth0/auth0-react";
import { PartyPopper } from "lucide-react";
import { APP_CONFIG } from "../../config";

interface AppLoginButtonProps {
  onClick?: () => void;
}

const AppLoginButton = ({ onClick }: AppLoginButtonProps) => {
  const { loginWithRedirect } = useAuth0();

  return (
    <div className="text-center space-y-6 my-8">
      <div className="flex justify-center">
        <div className="w-16 h-16 bg-gray-900 rounded-full flex items-center justify-center">
          <span className="text-green-400 font-bold text-2xl"><PartyPopper /></span>
        </div>
      </div>
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Welcome to {APP_CONFIG.app.name}</h1>
        <p className="mt-2 text-gray-600">Sign in to proceed</p>
      </div>
      <button
        onClick={onClick || (() => loginWithRedirect())}
        className="w-64 bg-gray-800 text-white py-3 px-4 rounded-md hover:bg-gray-700 transition-colors font-medium"
      >
        Sign In
      </button>
    </div>
  );
};


export default AppLoginButton