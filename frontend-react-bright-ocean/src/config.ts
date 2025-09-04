export const APP_CONFIG = {
  auth0: {
    domain: import.meta.env.VITE_AUTH0_DOMAIN,
    clientId: import.meta.env.VITE_AUTH0_CLIENT_ID,
    audience: import.meta.env.VITE_AUTH0_AUDIENCE,
    scope: 'openid profile email admin',
    redirectUri: import.meta.env.VITE_APP_HOST + '/auth0/callback',
    logoutUri: import.meta.env.VITE_APP_HOST,
    roles: import.meta.env.VITE_AUTH0_NAMESPACE,
  },
  api: {
    base: import.meta.env.VITE_API_BASE,
    uri: {
      health: '/app/v1/health',
      info: '/app/v1/info',
      profile: '/api/v1/user/profile',
      admin: '/admin/v1/check',
    },
  },
  app: {
    name: import.meta.env.VITE_APP_NAME,
    host: import.meta.env.VITE_APP_HOST,
  },
  environment: import.meta.env.MODE || 'development',
  hash: import.meta.env.VITE_GIT_HASH,
  name: import.meta.env.VITE_APP_NAME,
} as const;

export const APP_THEME_COLORS = {
  darkGreen: '#002626',
  midnightGreen: '#0e4749',
  yellowGreen: '#95c623',
  persimmon: '#e55812',
  alabaster: '#efe7da'
} as const;