interface AppLoadingProps {
  message?: string
}

const AppLoading = ({ message = 'Loading...' }: AppLoadingProps): React.JSX.Element => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
        <p className="text-gray-600">{message}</p>
      </div>
    </div>
  )
}

export default AppLoading