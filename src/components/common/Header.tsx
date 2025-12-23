import { useState, useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import { Menu, X, LogOut, Shield, Globe, Sun, Moon, Monitor } from "lucide-react";
import { useAuth } from "@/context/LocalAuthProvider";
import { useTheme } from "@/context/ThemeProvider";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import routes from "../../routes";
import { getProfile } from "@/db/api";
import type { Profile } from "@/types/types";

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const location = useLocation();
  const { user, logout } = useAuth();
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [profile, setProfile] = useState<Profile | null>(null);

  useEffect(() => {
    if (user?.id) {
      loadProfile();
    }
  }, [user]);

  const loadProfile = async () => {
    try {
      if (user?.id) {
        const data = await getProfile(user.id);
        setProfile(data);
      }
    } catch (error) {
      console.error("加载用户信息失败:", error);
    }
  };

  const navigation = routes.filter((route) => {
    if (route.visible === false) return false;
    if (route.path === "/admin" && profile?.role !== "admin") return false;
    return true;
  });

  const ThemeIcon = resolvedTheme === "dark" ? Moon : Sun;

  return (
    <header className="bg-white/80 dark:bg-gray-900/80 backdrop-blur-md shadow-sm sticky top-0 z-50 border-b border-gray-200 dark:border-gray-800">
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-14 sm:h-16">
          <div className="flex items-center">
            <Link to="/dashboard" className="flex-shrink-0 flex items-center space-x-2">
              <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
                <Globe className="h-4 w-4 sm:h-5 sm:w-5 text-white" />
              </div>
              <span className="text-base sm:text-lg font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent hidden sm:inline">
                WordPress CMS
              </span>
            </Link>
          </div>

          <div className="hidden md:flex items-center space-x-1">
            {navigation.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className={`px-3 py-2 text-sm font-medium rounded-lg transition-all duration-200 ${location.pathname === item.path
                  ? "text-blue-600 bg-blue-50 dark:bg-blue-950/50 dark:text-blue-400"
                  : "text-gray-700 dark:text-gray-300 hover:text-blue-600 hover:bg-gray-50 dark:hover:bg-gray-800"
                  }`}
              >
                {item.name}
              </Link>
            ))}
            {profile?.role === "admin" && (
              <Link
                to="/admin"
                className={`px-3 py-2 text-sm font-medium rounded-lg flex items-center space-x-1 transition-all duration-200 ${location.pathname === "/admin"
                  ? "text-blue-600 bg-blue-50 dark:bg-blue-950/50 dark:text-blue-400"
                  : "text-gray-700 dark:text-gray-300 hover:text-blue-600 hover:bg-gray-50 dark:hover:bg-gray-800"
                  }`}
              >
                <Shield className="h-4 w-4" />
                <span>管理员</span>
              </Link>
            )}

            {/* 主题切换 */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="ml-1">
                  <ThemeIcon className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => setTheme("light")} className={theme === "light" ? "bg-accent" : ""}>
                  <Sun className="mr-2 h-4 w-4" />
                  浅色
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => setTheme("dark")} className={theme === "dark" ? "bg-accent" : ""}>
                  <Moon className="mr-2 h-4 w-4" />
                  深色
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => setTheme("system")} className={theme === "system" ? "bg-accent" : ""}>
                  <Monitor className="mr-2 h-4 w-4" />
                  跟随系统
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>

            <Button variant="ghost" size="sm" onClick={logout} className="ml-2">
              <LogOut className="h-4 w-4 mr-2" />
              退出
            </Button>
          </div>

          <div className="md:hidden flex items-center space-x-1">
            {/* 移动端主题切换 */}
            <Button variant="ghost" size="icon" onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}>
              <ThemeIcon className="h-4 w-4" />
            </Button>
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="inline-flex items-center justify-center p-2 rounded-lg text-gray-700 dark:text-gray-300 hover:text-blue-600 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              {isMenuOpen ? (
                <X className="h-5 w-5" />
              ) : (
                <Menu className="h-5 w-5" />
              )}
            </button>
          </div>
        </div>

        {isMenuOpen && (
          <div className="md:hidden py-3 border-t border-gray-200 dark:border-gray-800">
            <div className="flex flex-col space-y-1">
              {navigation.map((item) => (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={() => setIsMenuOpen(false)}
                  className={`px-3 py-2.5 text-sm font-medium rounded-lg transition-all duration-200 ${location.pathname === item.path
                    ? "text-blue-600 bg-blue-50 dark:bg-blue-950/50 dark:text-blue-400"
                    : "text-gray-700 dark:text-gray-300 hover:text-blue-600 hover:bg-gray-50 dark:hover:bg-gray-800"
                    }`}
                >
                  {item.name}
                </Link>
              ))}
              {profile?.role === "admin" && (
                <Link
                  to="/admin"
                  onClick={() => setIsMenuOpen(false)}
                  className={`px-3 py-2.5 text-sm font-medium rounded-lg flex items-center space-x-2 transition-all duration-200 ${location.pathname === "/admin"
                    ? "text-blue-600 bg-blue-50 dark:bg-blue-950/50 dark:text-blue-400"
                    : "text-gray-700 dark:text-gray-300 hover:text-blue-600 hover:bg-gray-50 dark:hover:bg-gray-800"
                    }`}
                >
                  <Shield className="h-4 w-4" />
                  <span>管理员</span>
                </Link>
              )}
              <button
                onClick={() => {
                  logout();
                  setIsMenuOpen(false);
                }}
                className="px-3 py-2.5 text-sm font-medium rounded-lg flex items-center space-x-2 text-gray-700 dark:text-gray-300 hover:text-blue-600 hover:bg-gray-50 dark:hover:bg-gray-800 transition-all duration-200 text-left"
              >
                <LogOut className="h-4 w-4" />
                <span>退出</span>
              </button>
            </div>
          </div>
        )}
      </nav>
    </header>
  );
};

export default Header;