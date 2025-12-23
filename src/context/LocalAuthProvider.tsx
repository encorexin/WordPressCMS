import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
    getCurrentUser,
    login as authLogin,
    logout as authLogout,
    register as authRegister,
    refreshSession,
    type LocalUser
} from '@/db/localAuth';

interface AuthContextType {
    user: LocalUser | null;
    loading: boolean;
    login: (email: string, password: string) => Promise<{ error: string | null }>;
    register: (email: string, password: string) => Promise<{ error: string | null }>;
    logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function useAuth() {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within a LocalAuthProvider');
    }
    return context;
}

interface LocalAuthProviderProps {
    children: ReactNode;
    whiteList?: string[];
}

export function LocalAuthProvider({ children, whiteList = [] }: LocalAuthProviderProps) {
    const [user, setUser] = useState<LocalUser | null>(null);
    const [loading, setLoading] = useState(true);
    const navigate = useNavigate();
    const location = useLocation();

    // 初始化：检查现有会话
    useEffect(() => {
        const initAuth = async () => {
            const currentUser = getCurrentUser();
            if (currentUser) {
                // 刷新会话以验证用户仍然有效
                const refreshedUser = await refreshSession();
                setUser(refreshedUser);
            }
            setLoading(false);
        };
        initAuth();
    }, []);

    // 路由保护
    useEffect(() => {
        if (!loading && !user && !whiteList.includes(location.pathname)) {
            navigate('/login');
        }
    }, [user, loading, location.pathname, whiteList, navigate]);

    const login = async (email: string, password: string) => {
        const result = await authLogin(email, password);
        if (result.user) {
            setUser(result.user);
        }
        return { error: result.error };
    };

    const register = async (email: string, password: string) => {
        const result = await authRegister(email, password);
        if (result.user) {
            setUser(result.user);
        }
        return { error: result.error };
    };

    const logout = () => {
        authLogout();
        setUser(null);
        navigate('/login');
    };

    return (
        <AuthContext.Provider value={{ user, loading, login, register, logout }}>
            {children}
        </AuthContext.Provider>
    );
}
