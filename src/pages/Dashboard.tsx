import { useEffect, useState } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { getStatistics } from "@/db/api";
import { FileText, Globe, CheckCircle, FileEdit, Plus, ArrowRight, Sparkles } from "lucide-react";

export default function Dashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    totalSites: 0,
    totalArticles: 0,
    publishedArticles: 0,
    draftArticles: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStatistics();
  }, [user]);

  const loadStatistics = async () => {
    try {
      setLoading(true);
      const data = await getStatistics(user?.id);
      setStats(data);
    } catch (error) {
      console.error("加载统计数据失败:", error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: "WordPress站点",
      value: stats.totalSites,
      icon: Globe,
      gradient: "from-blue-500 to-cyan-500",
      iconBg: "bg-gradient-to-br from-blue-500/10 to-cyan-500/10",
      iconColor: "text-blue-600 dark:text-blue-400",
    },
    {
      title: "总文章数",
      value: stats.totalArticles,
      icon: FileText,
      gradient: "from-purple-500 to-pink-500",
      iconBg: "bg-gradient-to-br from-purple-500/10 to-pink-500/10",
      iconColor: "text-purple-600 dark:text-purple-400",
    },
    {
      title: "已发布",
      value: stats.publishedArticles,
      icon: CheckCircle,
      gradient: "from-green-500 to-emerald-500",
      iconBg: "bg-gradient-to-br from-green-500/10 to-emerald-500/10",
      iconColor: "text-green-600 dark:text-green-400",
    },
    {
      title: "草稿",
      value: stats.draftArticles,
      icon: FileEdit,
      gradient: "from-orange-500 to-amber-500",
      iconBg: "bg-gradient-to-br from-orange-500/10 to-amber-500/10",
      iconColor: "text-orange-600 dark:text-orange-400",
    },
  ];

  const quickActions = [
    {
      title: "添加站点",
      description: "连接新的WordPress网站",
      icon: Globe,
      color: "text-blue-600 dark:text-blue-400",
      bgColor: "bg-blue-50 dark:bg-blue-950/50",
      action: () => navigate("/sites"),
    },
    {
      title: "创建文章",
      description: "开始撰写新内容",
      icon: Plus,
      color: "text-purple-600 dark:text-purple-400",
      bgColor: "bg-purple-50 dark:bg-purple-950/50",
      action: () => navigate("/articles/new"),
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10">
      <div className="container mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-6 sm:space-y-8 max-w-7xl">
        {/* 头部欢迎区域 */}
        <div className="space-y-2">
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
            欢迎回来 👋
          </h1>
          <p className="text-sm sm:text-base text-muted-foreground">
            查看您的内容管理概览，开始创作精彩内容
          </p>
        </div>

        {/* 统计卡片 */}
        {loading ? (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 lg:gap-6">
            {[1, 2, 3, 4].map((i) => (
              <Card key={i} className="border-0 shadow-lg">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <div className="h-3 sm:h-4 w-16 sm:w-24 bg-muted animate-pulse rounded" />
                  <div className="h-8 sm:h-10 w-8 sm:w-10 bg-muted animate-pulse rounded-lg" />
                </CardHeader>
                <CardContent>
                  <div className="h-6 sm:h-8 w-12 sm:w-16 bg-muted animate-pulse rounded" />
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 lg:gap-6">
            {statCards.map((stat) => {
              const Icon = stat.icon;
              return (
                <Card
                  key={stat.title}
                  className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-1 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm"
                >
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 px-4 sm:px-6 pt-4 sm:pt-6">
                    <CardTitle className="text-xs sm:text-sm font-medium text-muted-foreground">
                      {stat.title}
                    </CardTitle>
                    <div className={`p-2 sm:p-2.5 rounded-lg ${stat.iconBg}`}>
                      <Icon className={`h-4 w-4 sm:h-5 sm:w-5 ${stat.iconColor}`} />
                    </div>
                  </CardHeader>
                  <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
                    <div className={`text-2xl sm:text-3xl font-bold bg-gradient-to-r ${stat.gradient} bg-clip-text text-transparent`}>
                      {stat.value}
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        )}

        {/* 快速操作 */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 lg:gap-6">
          {quickActions.map((action) => {
            const Icon = action.icon;
            return (
              <Card
                key={action.title}
                className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 cursor-pointer group bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm"
                onClick={action.action}
              >
                <CardContent className="p-4 sm:p-6">
                  <div className="flex items-start space-x-4">
                    <div className={`p-3 sm:p-4 rounded-xl ${action.bgColor} group-hover:scale-110 transition-transform duration-300`}>
                      <Icon className={`h-5 w-5 sm:h-6 sm:w-6 ${action.color}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-base sm:text-lg font-semibold mb-1 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                        {action.title}
                      </h3>
                      <p className="text-xs sm:text-sm text-muted-foreground">
                        {action.description}
                      </p>
                    </div>
                    <ArrowRight className="h-5 w-5 text-muted-foreground group-hover:text-blue-600 dark:group-hover:text-blue-400 group-hover:translate-x-1 transition-all flex-shrink-0" />
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* 功能介绍 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6">
          <Card className="border-0 shadow-lg bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-blue-950/30 dark:to-cyan-950/30 backdrop-blur-sm">
            <CardHeader>
              <CardTitle className="flex items-center space-x-2 text-lg sm:text-xl">
                <Sparkles className="h-5 w-5 sm:h-6 sm:w-6 text-blue-600 dark:text-blue-400" />
                <span>快速开始</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 sm:space-y-5">
              <div className="flex items-start space-x-3 sm:space-x-4 group">
                <div className="flex-shrink-0 w-6 h-6 sm:w-7 sm:h-7 rounded-full bg-blue-600 dark:bg-blue-500 text-white flex items-center justify-center text-xs sm:text-sm font-bold group-hover:scale-110 transition-transform">
                  1
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm sm:text-base mb-1">添加WordPress站点</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                    在"站点管理"页面添加您的WordPress网站信息，包括网站地址、用户名和应用程序密码
                  </p>
                </div>
              </div>
              <div className="flex items-start space-x-3 sm:space-x-4 group">
                <div className="flex-shrink-0 w-6 h-6 sm:w-7 sm:h-7 rounded-full bg-purple-600 dark:bg-purple-500 text-white flex items-center justify-center text-xs sm:text-sm font-bold group-hover:scale-110 transition-transform">
                  2
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm sm:text-base mb-1">创建文章</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                    在"文章管理"页面创建新文章，使用AI生成功能快速生成高质量内容
                  </p>
                </div>
              </div>
              <div className="flex items-start space-x-3 sm:space-x-4 group">
                <div className="flex-shrink-0 w-6 h-6 sm:w-7 sm:h-7 rounded-full bg-green-600 dark:bg-green-500 text-white flex items-center justify-center text-xs sm:text-sm font-bold group-hover:scale-110 transition-transform">
                  3
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm sm:text-base mb-1">发布到WordPress</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                    编辑完成后，选择目标站点并一键发布到您的WordPress网站
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-0 shadow-lg bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-950/30 dark:to-pink-950/30 backdrop-blur-sm">
            <CardHeader>
              <CardTitle className="flex items-center space-x-2 text-lg sm:text-xl">
                <CheckCircle className="h-5 w-5 sm:h-6 sm:w-6 text-purple-600 dark:text-purple-400" />
                <span>功能特性</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 sm:space-y-5">
              <div className="flex items-start space-x-3 sm:space-x-4 p-3 sm:p-4 rounded-xl bg-white/50 dark:bg-gray-900/50 hover:bg-white/80 dark:hover:bg-gray-900/80 transition-colors">
                <CheckCircle className="h-5 w-5 sm:h-6 sm:w-6 text-green-600 dark:text-green-400 mt-0.5 flex-shrink-0" />
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm sm:text-base mb-1">AI智能生成</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                    基于关键词和模板自动生成高质量文章内容
                  </p>
                </div>
              </div>
              <div className="flex items-start space-x-3 sm:space-x-4 p-3 sm:p-4 rounded-xl bg-white/50 dark:bg-gray-900/50 hover:bg-white/80 dark:hover:bg-gray-900/80 transition-colors">
                <CheckCircle className="h-5 w-5 sm:h-6 sm:w-6 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm sm:text-base mb-1">多站点管理</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                    统一管理多个WordPress网站，轻松切换发布目标
                  </p>
                </div>
              </div>
              <div className="flex items-start space-x-3 sm:space-x-4 p-3 sm:p-4 rounded-xl bg-white/50 dark:bg-gray-900/50 hover:bg-white/80 dark:hover:bg-gray-900/80 transition-colors">
                <CheckCircle className="h-5 w-5 sm:h-6 sm:w-6 text-purple-600 dark:text-purple-400 mt-0.5 flex-shrink-0" />
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm sm:text-base mb-1">实时预览</h3>
                  <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                    支持文章编辑和预览，确保内容质量后再发布
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
