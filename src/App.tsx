import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from "react-router-dom";
import { LocalAuthProvider } from "@/context/LocalAuthProvider";
import { ThemeProvider } from "@/context/ThemeProvider";
import { Toaster } from "@/components/ui/sonner";
import Header from "@/components/common/Header";
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
            <Route key={index} path={route.path} element={route.element} />
          ))}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
};

const App = () => {
  return (
    <ThemeProvider>
      <Router>
        <LocalAuthProvider whiteList={["/", "/login"]}>
          <Toaster />
          <AppContent />
        </LocalAuthProvider>
      </Router>
    </ThemeProvider>
  );
};

export default App;

