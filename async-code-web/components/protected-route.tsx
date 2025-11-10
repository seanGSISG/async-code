'use client'

import { useAuth } from '@/contexts/auth-context'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

interface ProtectedRouteProps {
    children: React.ReactNode
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
    const { user, loading } = useAuth()
    const router = useRouter()

    // Check if auth is disabled via environment variable
    const isAuthDisabled = process.env.NEXT_PUBLIC_DISABLE_AUTH === 'true'

    useEffect(() => {
        // Skip authentication check if disabled
        if (isAuthDisabled) return

        if (!loading && !user) {
            router.push('/signin')
        }
    }, [user, loading, router, isAuthDisabled])

    if (loading && !isAuthDisabled) {
        return (
            <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-slate-900"></div>
            </div>
        )
    }

    // If auth is disabled, always render children
    if (isAuthDisabled) {
        return <>{children}</>
    }

    if (!user) {
        return null // Will redirect
    }

    return <>{children}</>
} 