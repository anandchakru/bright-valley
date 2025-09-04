import * as Toast from '@radix-ui/react-toast'
import { type ReactNode, useState } from 'react'
import { ToastContext } from './ToastContext'

interface ToastProviderProps {
  children: ReactNode
}

export const ToastProvider = ({ children }: ToastProviderProps): React.JSX.Element => {
  const [toasts, setToasts] = useState<Array<{
    id: string
    title: string
    description?: string
    variant: 'success' | 'error' | 'info'
  }>>([])

  const showToast = (title: string, description?: string, variant: 'success' | 'error' | 'info' = 'info') => {
    const id = Date.now().toString()
    setToasts(prev => [...prev, { id, title, description, variant }])

    setTimeout(() => {
      setToasts(prev => prev.filter(toast => toast.id !== id))
    }, 5000)
  }

  const removeToast = (id: string) => {
    setToasts(prev => prev.filter(toast => toast.id !== id))
  }

  return (
    <ToastContext.Provider value={{ showToast, removeToast }}>
      <Toast.Provider>
        {children}
        {toasts.map(toast => (
          <Toast.Root key={toast.id} className="ToastRoot" onOpenChange={() => removeToast(toast.id)}>
            <Toast.Title className="ToastTitle">{toast.title}</Toast.Title>
            {toast.description && (
              <Toast.Description className="ToastDescription">{toast.description}</Toast.Description>
            )}
            <Toast.Close className="ToastClose">×</Toast.Close>
          </Toast.Root>
        ))}
        <Toast.Viewport className="ToastViewport" />
      </Toast.Provider>
    </ToastContext.Provider>
  )
}

interface ToastComponentProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description?: string
  variant?: 'success' | 'error' | 'info'
}

export const ToastComponent = ({
  open,
  onOpenChange,
  title,
  description,
  variant = 'info'
}: ToastComponentProps) => {
  return (
    <Toast.Provider>
      <Toast.Root
        className={`ToastRoot ToastRoot--${variant}`}
        open={open}
        onOpenChange={onOpenChange}
      >
        <Toast.Title className="ToastTitle">{title}</Toast.Title>
        {description && (
          <Toast.Description className="ToastDescription">{description}</Toast.Description>
        )}
        <Toast.Close className="ToastClose">×</Toast.Close>
      </Toast.Root>
      <Toast.Viewport className="ToastViewport" />
    </Toast.Provider>
  )
}