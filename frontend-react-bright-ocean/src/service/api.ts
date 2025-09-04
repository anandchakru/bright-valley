import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'
import { APP_CONFIG } from '../config'
import type { UserProfile } from '../model/user'
import type { RootState } from '../redux/store'

const baseQuery = fetchBaseQuery({
  baseUrl: APP_CONFIG.api.base,
  prepareHeaders: (headers, { getState }) => {
    const token = (getState() as RootState).auth.token
    if (token) {
      headers.set('authorization', 'Bearer ' + token)
    }
    headers.set('content-type', 'application/json')
    return headers
  },
})

export const api = createApi({
  reducerPath: 'api',
  baseQuery,
  tagTypes: ['UserProfile', 'Config'],
  endpoints: (builder) => ({
    getUserProfile: builder.query<UserProfile, void>({
      query: () => APP_CONFIG.api.uri.profile,
      providesTags: ['UserProfile'],
    }),
    getAppInfo: builder.query<{ version: string; name: string }, void>({
      query: () => APP_CONFIG.api.uri.info,
    }),
    getHealthCheck: builder.query<{ status: string }, void>({
      query: () => APP_CONFIG.api.uri.health,
    }),
    getAdminConfig: builder.query<Record<string, unknown>[], void>({
      query: () => APP_CONFIG.api.uri.admin,
      providesTags: ['Config'],
    }),
  }),
})

export const {
  useGetUserProfileQuery,
  useGetAppInfoQuery,
  useGetHealthCheckQuery,
  useGetAdminConfigQuery,
} = api