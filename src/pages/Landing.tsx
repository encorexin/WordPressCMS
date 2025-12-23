import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Globe,
  Sparkles,
  Zap,
  Shield,
  CheckCircle,
  ArrowRight,
  FileText,
  TrendingUp,
  Users,
  Clock,
} from "lucide-react";

export default function Landing() {
  const navigate = useNavigate();

  const features = [
    {
      icon: Sparkles,
      title: "AI智能生成",
      description: "基于关键词和模板，自动生成高质量文章内容，节省创作时间",
      gradient: "from-purple-500 to-pink-500",
      iconBg: "from-purple-500/10 to-pink-500/10",
      iconColor: "text-purple-600 dark:text-purple-400",
    },
    {
      icon: Globe,
      title: "多站点管理",
      description: "统一管理多个WordPress网站，轻松切换发布目标",
      gradient: "from-blue-500 to-cyan-500",
      iconBg: "from-blue-500/10 to-cyan-500/10",
      iconColor: "text-blue-600 dark:text-blue-400",
    },
    {
      icon: Zap,
      title: "一键发布",
      description: "编辑完成后，选择目标站点并一键发布到WordPress",
      gradient: "from-orange-500 to-amber-500",
      iconBg: "from-orange-500/10 to-amber-500/10",
      iconColor: "text-orange-600 dark:text-orange-400",
    },
    {
      icon: Shield,
      title: "安全可靠",
      description: "使用WordPress应用程序密码，确保账号安全",
      gradient: "from-green-500 to-emerald-500",
      iconBg: "from-green-500/10 to-emerald-500/10",
      iconColor: "text-green-600 dark:text-green-400",
    },
  ];

  const benefits = [
    {
      icon: Clock,
      title: "节省时间",
      description: "AI自动生成内容，大幅减少创作时间",
    },
    {
      icon: TrendingUp,
      title: "提升效率",
      description: "批量管理多个站点，提高工作效率",
    },
    {
      icon: FileText,
      title: "内容质量",
      description: "智能生成高质量文章，保证内容水准",
    },
    {
      icon: Users,
      title: "简单易用",
      description: "直观的界面设计，快速上手使用",
    },
  ];

  const steps = [
    {
      number: "01",
      title: "添加WordPress站点",
      description: "输入您的WordPress网站信息，包括网站地址、用户名和应用程序密码",
    },
    {
      number: "02",
      title: "创建或生成文章",
      description: "使用AI生成功能快速创建文章，或手动编写内容",
    },
    {
      number: "03",
      title: "一键发布",
      description: "选择目标站点，点击发布按钮即可将文章发布到WordPress",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10">
      {/* 导航栏 */}
      <header className="bg-white/80 dark:bg-gray-900/80 backdrop-blur-md shadow-sm sticky top-0 z-50 border-b border-gray-200 dark:border-gray-800">
        <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-14 sm:h-16">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
                <Globe className="h-4 w-4 sm:h-5 sm:w-5 text-white" />
              </div>
              <span className="text-base sm:text-lg font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
                WordPress CMS
              </span>
            </div>
            <div className="flex items-center">
              <Button
                onClick={() => navigate("/login")}
                className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-lg hover:shadow-xl transition-all"
              >
                免费使用
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </div>
          </div>
        </nav>
      </header>
      {/* 主内容区域 */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 sm:py-16 lg:py-20">
        {/* Hero区域 */}
        <div className="text-center space-y-6 sm:space-y-8 mb-16 sm:mb-20">
          <div className="inline-flex items-center space-x-2 px-4 py-2 rounded-full bg-blue-50 dark:bg-blue-950/50 border border-blue-200 dark:border-blue-800">
            <Sparkles className="h-4 w-4 text-blue-600 dark:text-blue-400" />
            <span className="text-sm font-medium text-blue-600 dark:text-blue-400">
              AI驱动的内容管理系统
            </span>
          </div>
          <h1 className="text-3xl sm:text-4xl lg:text-6xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 dark:from-blue-400 dark:via-purple-400 dark:to-pink-400 bg-clip-text text-transparent leading-tight">
            WordPress内容管理
            <br />
            从未如此简单
          </h1>
          <p className="text-base sm:text-lg lg:text-xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
            通过AI智能生成高质量文章，统一管理多个WordPress站点，
            <br className="hidden sm:block" />
            让内容创作和发布变得轻松高效
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
            <Button
              size="lg"
              onClick={() => navigate("/login")}
              className="w-full sm:w-auto bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-xl hover:shadow-2xl transition-all text-base"
            >
              立即开始使用
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="w-full sm:w-auto text-base border-2 border-blue-200 dark:border-blue-800 hover:bg-blue-50 dark:hover:bg-blue-950/50 hover:border-blue-300 dark:hover:border-blue-700 bg-[#9d9df8ff] bg-none text-[#394343ff]"
              onClick={() => {
                document
                  .getElementById("features")
                  ?.scrollIntoView({ behavior: "smooth" });
              }}
            >
              了解更多
            </Button>
          </div>
        </div>

        {/* 核心功能 */}
        <div id="features" className="mb-16 sm:mb-20">
          <div className="text-center mb-10 sm:mb-12">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-3 sm:mb-4">
              核心功能
            </h2>
            <p className="text-sm sm:text-base text-muted-foreground">
              强大的功能，助力您的内容创作
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <Card
                  key={index}
                  className="border-0 shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-2 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm group"
                >
                  <CardContent className="p-6 space-y-4">
                    <div
                      className={`w-12 h-12 sm:w-14 sm:h-14 rounded-xl bg-gradient-to-br ${feature.iconBg} flex items-center justify-center group-hover:scale-110 transition-transform duration-300`}
                    >
                      <Icon className={`h-6 w-6 sm:h-7 sm:w-7 ${feature.iconColor}`} />
                    </div>
                    <h3 className="text-lg sm:text-xl font-semibold">
                      {feature.title}
                    </h3>
                    <p className="text-sm sm:text-base text-muted-foreground leading-relaxed">
                      {feature.description}
                    </p>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>

        {/* 使用步骤 */}
        <div className="mb-16 sm:mb-20">
          <div className="text-center mb-10 sm:mb-12">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-3 sm:mb-4">
              三步开始使用
            </h2>
            <p className="text-sm sm:text-base text-muted-foreground">
              简单快捷，轻松上手
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8">
            {steps.map((step, index) => (
              <div key={index} className="relative group">
                <Card className="border-0 shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm h-full">
                  <CardContent className="p-6 sm:p-8 space-y-4">
                    <div className="text-5xl sm:text-6xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent opacity-20 group-hover:opacity-30 transition-opacity">
                      {step.number}
                    </div>
                    <h3 className="text-lg sm:text-xl font-semibold">
                      {step.title}
                    </h3>
                    <p className="text-sm sm:text-base text-muted-foreground leading-relaxed">
                      {step.description}
                    </p>
                  </CardContent>
                </Card>
                {index < steps.length - 1 && (
                  <div className="hidden md:block absolute top-1/2 -right-4 transform -translate-y-1/2">
                    <ArrowRight className="h-6 w-6 text-blue-600 dark:text-blue-400 group-hover:translate-x-1 transition-transform" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* 优势特点 */}
        <div className="mb-16 sm:mb-20">
          <div className="text-center mb-10 sm:mb-12">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-3 sm:mb-4">
              为什么选择我们
            </h2>
            <p className="text-sm sm:text-base text-muted-foreground">
              专业、高效、易用的内容管理解决方案
            </p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            {benefits.map((benefit, index) => {
              const Icon = benefit.icon;
              return (
                <Card
                  key={index}
                  className="border-0 shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-950/30 dark:to-purple-950/30 backdrop-blur-sm group"
                >
                  <CardContent className="p-6 space-y-3 text-center">
                    <div className="flex justify-center">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                        <Icon className="h-6 w-6 text-white" />
                      </div>
                    </div>
                    <h3 className="text-base sm:text-lg font-semibold">
                      {benefit.title}
                    </h3>
                    <p className="text-xs sm:text-sm text-muted-foreground">
                      {benefit.description}
                    </p>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>

        {/* CTA区域 */}
        <div className="text-center">
          <Card className="border-0 shadow-2xl bg-gradient-to-br from-blue-600 to-purple-600 dark:from-blue-700 dark:to-purple-700">
            <CardContent className="p-8 sm:p-12 lg:p-16 space-y-6">
              <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-white">
                准备好开始了吗？
              </h2>
              <p className="text-base sm:text-lg text-blue-100 max-w-2xl mx-auto">
                立即注册，免费使用WordPress内容管理系统，
                <br className="hidden sm:block" />
                让AI助力您的内容创作
              </p>
              <Button
                size="lg"
                onClick={() => navigate("/login")}
                className="bg-white text-blue-600 hover:bg-gray-100 shadow-xl hover:shadow-2xl transition-all text-base"
              >
                免费开始使用
                <ArrowRight className="ml-2 h-5 w-5" />
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
      {/* 页脚 */}
      <footer className="border-t border-gray-200 dark:border-gray-800 mt-16 sm:mt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
          <div className="text-center space-y-4">
            <div className="flex items-center justify-center space-x-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
                <Globe className="h-4 w-4 text-white" />
              </div>
              <span className="text-lg font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
                WordPress CMS
              </span>
            </div>
            <p className="text-sm text-muted-foreground">
              2025 WordPress内容管理系统
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
