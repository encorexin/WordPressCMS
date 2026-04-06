import { createContext, type ReactNode, useContext, useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import {
  login as authLogin,
  logout as authLogout,
  register as authRegister,
  getCurrentUser,
  type LocalUser,
  refreshSession,
} from "@/db/localAuth";
import {
  clearEncryptionKey,
  restoreEncryptionKey,
  setEncryptionKey,
} from "@/utils/encryptedStorage";
import { authLogger } from "@/utils/logger";

interface AuthContextType {
  user: LocalUser | null;
  loading: boolean;
  isDecrypted: boolean;
  login: (email: string, password: string) => Promise<{ error: string | null }>;
  register: (email: string, password: string) => Promise<{ error: string | null }>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within a LocalAuthProvider");
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
  const [isDecrypted, setIsDecrypted] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  // 初始化：检查现有会话
  useEffect(() => {
    const initAuth = async () => {
      try {
        // 首先检查 localStorage 中是否有会话
        const currentUser = getCurrentUser();
        if (currentUser) {
          // 立即设置用户（避免闪烁）
          setUser(currentUser);

          // 尝试恢复加密密钥（页面刷新后自动恢复）
          const restored = await restoreEncryptionKey(currentUser.id);
          if (restored) {
            setIsDecrypted(true);
            authLogger.debug("加密密钥已自动恢复");
          } else {
            authLogger.debug("无法恢复加密密钥，需要重新登录");
          }

          // 异步刷新会话以获取最新数据
          const refreshedUser = await refreshSession();
          if (refreshedUser) {
            setUser(refreshedUser);
          }
        }
      } catch (error) {
        authLogger.error("初始化认证失败:", error);
        const currentUser = getCurrentUser();
        if (currentUser) {
          setUser(currentUser);
        }
      } finally {
        setLoading(false);
      }
    };
    initAuth();
  }, []);

  // 路由保护
  useEffect(() => {
    if (!loading && !user && !whiteList.includes(location.pathname)) {
      navigate("/login");
    }
  }, [user, loading, location.pathname, whiteList, navigate]);

  const login = async (email: string, password: string) => {
    const result = await authLogin(email, password);
    if (result.user) {
      setUser(result.user);
      // 设置加密密钥
      await setEncryptionKey(result.user.id, password);
      setIsDecrypted(true);
    }
    return { error: result.error };
  };

  const register = async (email: string, password: string) => {
    const result = await authRegister(email, password);
    if (result.user) {
      setUser(result.user);
      // 设置加密密钥
      await setEncryptionKey(result.user.id, password);
      setIsDecrypted(true);
    }
    return { error: result.error };
  };

  const logout = () => {
    authLogout();
    clearEncryptionKey();
    setUser(null);
    setIsDecrypted(false);
    navigate("/login");
  };

  return (
    <AuthContext.Provider value={{ user, loading, isDecrypted, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
