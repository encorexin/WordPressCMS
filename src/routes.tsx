import Landing from "./pages/Landing";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Sites from "./pages/Sites";
import Articles from "./pages/Articles";
import ArticleEditor from "./pages/ArticleEditor";
import Admin from "./pages/Admin";
import AISettings from "./pages/AISettings";
import DataManagement from "./pages/DataManagement";
import Templates from "./pages/Templates";
import Keywords from "./pages/Keywords";
import type { ReactNode } from "react";

export interface RouteConfig {
  name: string;
  path: string;
  element: ReactNode;
  visible?: boolean;
  requireAuth?: boolean;
}

const routes: RouteConfig[] = [
  {
    name: "首页",
    path: "/",
    element: <Landing />,
    visible: false,
    requireAuth: false,
  },
  {
    name: "登录",
    path: "/login",
    element: <Login />,
    visible: false,
    requireAuth: false,
  },
  {
    name: "仪表板",
    path: "/dashboard",
    element: <Dashboard />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "站点管理",
    path: "/sites",
    element: <Sites />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "文章管理",
    path: "/articles",
    element: <Articles />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "文章编辑",
    path: "/articles/:id",
    element: <ArticleEditor />,
    visible: false,
    requireAuth: true,
  },
  {
    name: "模板库",
    path: "/templates",
    element: <Templates />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "关键词库",
    path: "/keywords",
    element: <Keywords />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "AI 设置",
    path: "/ai-settings",
    element: <AISettings />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "数据管理",
    path: "/data",
    element: <DataManagement />,
    visible: true,
    requireAuth: true,
  },
  {
    name: "管理员",
    path: "/admin",
    element: <Admin />,
    visible: true,
    requireAuth: true,
  },
];

export default routes;