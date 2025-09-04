import { Auth0Provider } from '@auth0/auth0-react'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { Provider } from 'react-redux'
import App from './App.tsx'
import ErrorBoundary from './component/app/ErrorBoundary.tsx'
import { APP_CONFIG } from './config'
import './index.css'
import { ToastProvider } from './provider/ToastProvider.tsx'
import { store } from './redux/store.ts'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary>
      <Provider store={store}>
        <Auth0Provider
          domain={APP_CONFIG.auth0.domain}
          clientId={APP_CONFIG.auth0.clientId}
          authorizationParams={{
            redirect_uri: APP_CONFIG.auth0.redirectUri,
            audience: APP_CONFIG.auth0.audience,
            scope: APP_CONFIG.auth0.scope,
          }}
          cacheLocation="localstorage"
          useRefreshTokens={true}
        >
          <ToastProvider>
            <App />
          </ToastProvider>
        </Auth0Provider>
      </Provider>
    </ErrorBoundary>
  </StrictMode>,
)