import { createSlice, type PayloadAction } from '@reduxjs/toolkit'
import type { UserProfile } from '../../model/user'

interface AppState {
  isLoading: boolean
  error: string | null
  theme: 'light' | 'dark'
  sidebarOpen: boolean
  userProfile: UserProfile | null
}

const initialState: AppState = {
  isLoading: false,
  error: null,
  theme: 'light',
  sidebarOpen: false,
  userProfile: null,
}

const appSlice = createSlice({
  name: 'app',
  initialState,
  reducers: {
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.isLoading = action.payload
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload
    },
    setTheme: (state, action: PayloadAction<'light' | 'dark'>) => {
      state.theme = action.payload
    },
    toggleSidebar: (state) => {
      state.sidebarOpen = !state.sidebarOpen
    },
    setSidebarOpen: (state, action: PayloadAction<boolean>) => {
      state.sidebarOpen = action.payload
    },
    setUserProfile: (state, action: PayloadAction<UserProfile>) => {
      state.userProfile = action.payload
    },
  },
})

export const { setLoading, setError, setTheme, toggleSidebar, setSidebarOpen, setUserProfile } = appSlice.actions
export default appSlice.reducer