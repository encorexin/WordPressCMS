import { BrowserRouter as Router, Routes, Route, Navigate, useLocation, HashRouter } from "react-router-dom";
import { LocalAuthProvider } from "@/context/LocalAuthProvider";
import { ThemeProvider } from "@/context/ThemeProvider";
import { Toaster } from "@/components/ui/sonner";
import Header from "@/components/common/Header";
import { ErrorBoundary } from "@/components/common/ErrorBoundary";
import routes from "./routes";

const AppContent = () => {
  const location = useLocation();
  const showHeader = location.pathname !== "/" && location.pathname !== "/login";

  return (
    <div className="flex flex-col min-h-screen">
      {showHeader && <Header />}
      <main className={`flex-grow ${showHeader ? "bg-gray-50 dark:bg-gray-900" : ""}`}>
        <Routes>
          {routes.map((route, index) => (
            <Route
              key={index}
              path={route.path}
              element={
                <ErrorBoundary>
                  {route.element}
                </ErrorBoundary>
              }
            />
          ))}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
};

// 检查是否在扩展环境中
const isExtension = typeof window !== 'undefined' && window.__IS_EXTENSION__;

const App = () => {
  // 扩展环境使用 HashRouter，普通环境使用 BrowserRouter
  const RouterComponent = isExtension ? HashRouter : Router;

  return (
    <ThemeProvider>
      <ErrorBoundary>
        <RouterComponent>
          <LocalAuthProvider whiteList={["/", "/login"]}>
            <Toaster />
            <AppContent />
          </LocalAuthProvider>
        </RouterComponent>
      </ErrorBoundary>
    </ThemeProvider>
  );
};

export default App;
