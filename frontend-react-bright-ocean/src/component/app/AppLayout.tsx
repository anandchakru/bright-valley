import { useAuth0 } from "@auth0/auth0-react";
import * as Separator from "@radix-ui/react-separator";
import { useEffect, useState } from "react";
import { useLocation } from "wouter";
import { APP_CONFIG } from "../../config";
import { ToastComponent } from "../../provider/ToastProvider";
import { useAppDispatch, useAppSelector } from "../../redux/hooks";
import { setUserProfile } from "../../redux/slice/appSlice";
import { setAuthenticated, setAuthLoading, setUnauthenticated } from "../../redux/slice/authSlice";
import { useGetUserProfileQuery } from "../../service/api";
import { parseApiError, type ErrorDetails } from "../../util/errorHandler";
import AppFooter from "./AppFooter";
import AppHeader from "./AppHeader";
import AppLoading from "./AppLoading";
import AppLoginButton from "./AppLogin";

interface AppLayoutProp {
  title?: string
  children: React.ReactNode
  authRequired?: boolean
  roleRequired?: string[]
}

const AppLayout = ({ title, children, authRequired = true, roleRequired }: AppLayoutProp): React.JSX.Element => {

  const { isAuthenticated, isLoading, user, getAccessTokenSilently, loginWithRedirect } = useAuth0();
  const dispatch = useAppDispatch();
  const [location] = useLocation();
  const [errorToast, setErrorToast] = useState<ErrorDetails | null>(null);
  const authState = useAppSelector(state => state.auth);
  const existingProfile = useAppSelector(state => state.app.userProfile);
  const { data: userProfile, error: profileError } = useGetUserProfileQuery(undefined, {
    skip: !authState.isAuthenticated || !authState.token || !!existingProfile
  });

  useEffect(() => {
    const updateAuthState = async () => {
      if (isLoading) {
        dispatch(setAuthLoading(true));
        return;
      }

      if (isAuthenticated && user) {
        try {
          const token = await getAccessTokenSilently();
          dispatch(setAuthenticated({
            user: {
              sub: user.sub!,
              email: user.email!,
              name: user.name!,
              picture: user.picture,
              roles: user[APP_CONFIG.auth0.roles] || []
            },
            token
          }));
        } catch (error) {
          console.warn('Failed to get access token silently:', error);
          if (error instanceof Error && error.message.includes('login_required')) {
            dispatch(setUnauthenticated());
          } else {
            dispatch(setAuthLoading(false));
          }
          throw new Error();
        }
      } else {
        dispatch(setUnauthenticated());
      }
    };

    if (authRequired) updateAuthState();
  }, [isAuthenticated, isLoading, user, getAccessTokenSilently, dispatch, authRequired]);

  useEffect(() => {
    if (userProfile && authRequired) {
      dispatch(setUserProfile(userProfile));
    }
  }, [userProfile, dispatch, authRequired]);

  useEffect(() => { setErrorToast(parseApiError(profileError)) }, [profileError]);

  if (isLoading) {
    return <AppLoading message="Loading application..." />;
  }

  // Check if user has required roles
  const hasRequiredRole = () => {
    if (!roleRequired || roleRequired.length === 0) return true;
    if (!isAuthenticated || !user) return false;

    const userRoles = user[APP_CONFIG.auth0.roles] || [];
    return roleRequired.some(role => userRoles.includes(role));
  };

  // Show login if auth is required but user is not authenticated
  if (authRequired && !authState.isAuthenticated) {
    return (
      <div className="min-h-screen flex flex-col bg-gray-50">
        <AppHeader />
        <main className="flex-1 container mx-auto px-4 py-2">
          <div className="max-w-screen-xl mx-auto">
            <AppLoginButton onClick={() => {
              loginWithRedirect({
                appState: { returnTo: location }
              });
            }} />
          </div>
        </main>
        <AppFooter />
      </div>
    );
  }

  // Show unauthorized message if user doesn't have required roles
  if (authRequired && authState.isAuthenticated && !hasRequiredRole()) {
    return (
      <div className="min-h-screen flex flex-col bg-gray-50">
        <AppHeader />
        <main className="flex-1 container mx-auto px-4 py-2">
          <div className="max-w-screen-xl mx-auto">
            <div className="p-6 text-center">
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Access Denied</h2>
              <p className="text-gray-600">You are not authorized to access this page.</p>
            </div>
          </div>
        </main>
        <AppFooter />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <AppHeader />
      <main className="flex-1 container mx-auto px-4 py-2">
        <div className="max-w-screen-xl mx-auto">
          <div className="p-6">
            {title && (
              <>
                <h1 className="text-2xl font-bold text-gray-900 mb-4">
                  {title}
                </h1>
                <Separator.Root className="bg-gray-200 h-px my-4" />
              </>
            )}
            {children}
          </div>
        </div>
      </main>
      <AppFooter />
      {errorToast && (<ToastComponent
        open={!!errorToast}
        onOpenChange={(open) => !open && setErrorToast(null)}
        title={errorToast.message}
        description={errorToast.details}
        variant="error"
      />
      )}
    </div>
  );
}

export default AppLayout;