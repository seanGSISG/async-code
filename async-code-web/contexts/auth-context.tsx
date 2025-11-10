'use client'

import React, { createContext, useContext, useEffect, useState } from 'react'
import { User, Session } from '@supabase/supabase-js'
import { getSupabase } from '@/lib/supabase'

interface AuthContextType {
    user: User | null
    session: Session | null
    loading: boolean
    signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function useAuth() {
    const context = useContext(AuthContext)
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider')
    }
    return context
}

interface AuthProviderProps {
    children: React.ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
    const [user, setUser] = useState<User | null>(null)
    const [session, setSession] = useState<Session | null>(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        // Check if auth is disabled
        const isAuthDisabled = process.env.NEXT_PUBLIC_DISABLE_AUTH === 'true'

        if (isAuthDisabled) {
            // Create a mock user for development when auth is disabled
            // Using a valid UUID format: 00000000-0000-0000-0000-000000000000
            const mockUser = {
                id: '00000000-0000-0000-0000-000000000000',
                email: 'demo@localhost',
                app_metadata: {},
                user_metadata: {},
                aud: 'authenticated',
                created_at: new Date().toISOString(),
            } as User

            setUser(mockUser)
            setLoading(false)
            return
        }

        const supabase = getSupabase()

        // Get initial session
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session)
            setUser(session?.user ?? null)
            setLoading(false)
        })

        // Listen for auth changes
        const {
            data: { subscription },
        } = supabase.auth.onAuthStateChange(async (event, session) => {
            setSession(session)
            setUser(session?.user ?? null)
            setLoading(false)
        })

        return () => subscription.unsubscribe()
    }, [])

    const signOut = async () => {
        const supabase = getSupabase()
        await supabase.auth.signOut()
    }

    const value = {
        user,
        session,
        loading,
        signOut,
    }

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
} 