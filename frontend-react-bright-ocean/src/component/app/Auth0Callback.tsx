import { useAuth0 } from '@auth0/auth0-react'
import { useEffect } from 'react'
import { useLocation } from 'wouter'
import AppLoading from './AppLoading'

const Auth0Callback = () => {
  const { handleRedirectCallback, isLoading, error } = useAuth0()
  const [, setLocation] = useLocation()

  useEffect(() => {
    const processCallback = async () => {
      try {
        const result = await handleRedirectCallback()
        const returnTo = result?.appState?.returnTo || '/home'
        setLocation(returnTo)
      } catch (error) {
        console.error('Auth callback error:', error)
        setLocation('/home')
      }
    }

    if (!isLoading && !error) {
      processCallback()
    }
  }, [handleRedirectCallback, isLoading, error, setLocation])

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl font-semibold text-red-600 mb-2">Authentication Error</h2>
          <p className="text-gray-600">{error.message}</p>
        </div>
      </div>
    )
  }

  return <AppLoading message="Completing authentication..." />
}

export default Auth0Callback