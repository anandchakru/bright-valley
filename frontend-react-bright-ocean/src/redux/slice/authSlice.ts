import { createSlice, type PayloadAction } from '@reduxjs/toolkit'

interface User {
  sub: string
  email: string
  name: string
  picture?: string
  roles?: string[]
}

interface AuthState {
  isAuthenticated: boolean
  isLoading: boolean
  user: User | null
  token: string | null
  error: string | null
}

const initialState: AuthState = {
  isAuthenticated: false,
  isLoading: true,
  user: null,
  token: null,
  error: null,
}

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setAuthLoading: (state, action: PayloadAction<boolean>) => {
      state.isLoading = action.payload
    },
    setAuthenticated: (state, action: PayloadAction<{ user: User; token: string }>) => {
      state.isAuthenticated = true
      state.user = action.payload.user
      state.token = action.payload.token
      state.error = null
      state.isLoading = false
    },
    setUnauthenticated: (state) => {
      state.isAuthenticated = false
      state.user = null
      state.token = null
      state.error = null
      state.isLoading = false
    },
    setAuthError: (state, action: PayloadAction<string>) => {
      state.error = action.payload
      state.isLoading = false
    },
  },
})

export const { setAuthLoading, setAuthenticated, setUnauthenticated, setAuthError } = authSlice.actions
export default authSlice.reducer