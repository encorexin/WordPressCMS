import { lazy, type ReactNode, Suspense } from "react";
import { DashboardSkeleton, ListPageSkeleton, PageSkeleton } from "@/components/common/PageSkeleton";

// 同步加载核心页面
import Landing from "./pages/Landing";
import Login from "./pages/Login";

// 懒加载其他页面
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Sites = lazy(() => import("./pages/Sites"));
const Articles = lazy(() => import("./pages/Articles"));
const ArticleEditor = lazy(() => import("./pages/ArticleEditor"));
const Admin = lazy(() => import("./pages/Admin"));
const AISettings = lazy(() => import("./pages/AISettings"));
const DataManagement = lazy(() => import("./pages/DataManagement"));
const Templates = lazy(() => import("./pages/Templates"));
const Keywords = lazy(() => import("./pages/Keywords"));
const Topics = lazy(() => import("./pages/Topics"));
const NotFound = lazy(() => import("./pages/NotFound"));

export interface RouteConfig {
  name: string;
  path: string;
  element: ReactNode;
  visible?: boolean;
  requireAuth?: boolean;
}

// 包装懒加载组件，添加骨架屏
function withSuspense(
  Component: React.LazyExoticComponent<React.ComponentType>,
  fallback: ReactNode
) {
  return (
    <Suspense fallback={fallback}>
      <Component />
    </Suspense>
  );
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
    element: withSuspense(Dashboard, <DashboardSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "站点管理",
    path: "/sites",
    element: withSuspense(Sites, <ListPageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "文章管理",
    path: "/articles",
    element: withSuspense(Articles, <ListPageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "文章编辑",
    path: "/articles/:id",
    element: withSuspense(ArticleEditor, <PageSkeleton />),
    visible: false,
    requireAuth: true,
  },
  {
    name: "主题库",
    path: "/topics",
    element: withSuspense(Topics, <ListPageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "模板库",
    path: "/templates",
    element: withSuspense(Templates, <ListPageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "关键词库",
    path: "/keywords",
    element: withSuspense(Keywords, <ListPageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "AI 设置",
    path: "/ai-settings",
    element: withSuspense(AISettings, <PageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "数据管理",
    path: "/data",
    element: withSuspense(DataManagement, <PageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "管理员",
    path: "/admin",
    element: withSuspense(Admin, <PageSkeleton />),
    visible: true,
    requireAuth: true,
  },
  {
    name: "404",
    path: "*",
    element: withSuspense(NotFound, <PageSkeleton />),
    visible: false,
    requireAuth: false,
  },
];

export default routes;
