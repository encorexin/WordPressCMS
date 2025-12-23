import { createContext, useContext, useEffect, useState } from "react";

type Theme = "dark" | "light" | "system";

interface ThemeProviderState {
    theme: Theme;
    setTheme: (theme: Theme) => void;
    resolvedTheme: "dark" | "light";
}

const ThemeProviderContext = createContext<ThemeProviderState | undefined>(undefined);

const STORAGE_KEY = "wordpress-cms-theme";

export function ThemeProvider({ children }: { children: React.ReactNode }) {
    const [theme, setThemeState] = useState<Theme>(() => {
        if (typeof window !== "undefined") {
            return (localStorage.getItem(STORAGE_KEY) as Theme) || "system";
        }
        return "system";
    });

    const [resolvedTheme, setResolvedTheme] = useState<"dark" | "light">("light");

    useEffect(() => {
        const root = window.document.documentElement;

        const updateTheme = () => {
            let resolved: "dark" | "light";

            if (theme === "system") {
                resolved = window.matchMedia("(prefers-color-scheme: dark)").matches
                    ? "dark"
                    : "light";
            } else {
                resolved = theme;
            }

            setResolvedTheme(resolved);

            root.classList.remove("light", "dark");
            root.classList.add(resolved);
        };

        updateTheme();

        // 监听系统主题变化
        const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
        const handleChange = () => {
            if (theme === "system") {
                updateTheme();
            }
        };

        mediaQuery.addEventListener("change", handleChange);
        return () => mediaQuery.removeEventListener("change", handleChange);
    }, [theme]);

    const setTheme = (newTheme: Theme) => {
        localStorage.setItem(STORAGE_KEY, newTheme);
        setThemeState(newTheme);
    };

    return (
        <ThemeProviderContext.Provider value={{ theme, setTheme, resolvedTheme }}>
            {children}
        </ThemeProviderContext.Provider>
    );
}

export function useTheme() {
    const context = useContext(ThemeProviderContext);
    if (context === undefined) {
        throw new Error("useTheme must be used within a ThemeProvider");
    }
    return context;
}
