export interface ErrorDetails {
  message: string
  details?: string
  code?: string
}

export const parseApiError = (error: unknown): ErrorDetails | null => {
  if (!error) return null

  if (typeof error === 'object' && error !== null) {
    const errorObj = error as Record<string, unknown>
    
    if ('status' in errorObj && 'data' in errorObj) {
      const data = errorObj.data as Record<string, unknown>
      return {
        message: (data?.message as string) || 'API Error',
        details: (data?.details as string) || `Status: ${errorObj.status}`,
        code: data?.code as string
      }
    }

    if ('message' in errorObj) {
      return {
        message: errorObj.message as string,
        details: (errorObj as { stack?: string }).stack
      }
    }
  }

  return {
    message: 'Unknown error occurred',
    details: JSON.stringify(error)
  }
}