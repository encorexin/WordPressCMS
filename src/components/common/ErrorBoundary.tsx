import { Component, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { AlertTriangle, RefreshCw, Home, ChevronDown, ChevronUp } from "lucide-react";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: string | null;
  showDetails: boolean;
}

/**
 * React 错误边界组件
 * 捕获子组件渲染错误，防止白屏
 */
export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
      showDetails: false,
    };
  }

  static getDerivedStateFromError(error: Error): State {
    return {
      hasError: true,
      error,
      errorInfo: null,
      showDetails: false,
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // 记录错误信息
    console.error("ErrorBoundary 捕获到错误:", error, errorInfo);
    this.setState({
      errorInfo: errorInfo.componentStack,
    });

    // 可以在这里添加错误上报逻辑
    // 例如：发送到 Sentry、LogRocket 等
    this.reportError(error, errorInfo);
  }

  reportError(error: Error, errorInfo: React.ErrorInfo) {
    // 本地存储错误日志
    try {
      const errorLog = {
        message: error.message,
        stack: error.stack,
        componentStack: errorInfo.componentStack,
        timestamp: new Date().toISOString(),
        url: window.location.href,
        userAgent: navigator.userAgent,
      };

      // 存储到 localStorage（最多保留 10 条）
      const logs = JSON.parse(localStorage.getItem("error_logs") || "[]");
      logs.unshift(errorLog);
      if (logs.length > 10) {
        logs.pop();
      }
      localStorage.setItem("error_logs", JSON.stringify(logs));
    } catch {
      // 忽略存储错误
    }
  }

  handleRefresh = () => {
    window.location.reload();
  };

  handleGoHome = () => {
    window.location.href = "/";
  };

  toggleDetails = () => {
    this.setState((prev) => ({
      showDetails: !prev.showDetails,
    }));
  };

  render() {
    if (this.state.hasError) {
      // 自定义 fallback UI
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10 flex items-center justify-center p-4">
          <Card className="w-full max-w-lg shadow-xl">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center mb-4">
                <AlertTriangle className="h-8 w-8 text-red-600 dark:text-red-400" />
              </div>
              <CardTitle className="text-xl">出错了</CardTitle>
              <CardDescription>
                应用程序遇到了一个错误，请尝试刷新页面
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-muted rounded-lg p-3 text-sm">
                <p className="font-medium text-destructive">
                  {this.state.error?.message || "未知错误"}
                </p>
              </div>

              {/* 错误详情折叠面板 */}
              {this.state.errorInfo && (
                <div className="border rounded-lg overflow-hidden">
                  <button
                    onClick={this.toggleDetails}
                    className="w-full flex items-center justify-between p-3 text-sm font-medium hover:bg-muted/50 transition-colors"
                  >
                    <span>错误详情</span>
                    {this.state.showDetails ? (
                      <ChevronUp className="h-4 w-4" />
                    ) : (
                      <ChevronDown className="h-4 w-4" />
                    )}
                  </button>
                  {this.state.showDetails && (
                    <div className="p-3 bg-muted/30 border-t">
                      <pre className="text-xs text-muted-foreground overflow-auto max-h-48 whitespace-pre-wrap">
                        {this.state.error?.stack}
                        {"\n\n组件堆栈:\n"}
                        {this.state.errorInfo}
                      </pre>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
            <CardFooter className="flex gap-3 justify-center">
              <Button
                variant="outline"
                onClick={this.handleGoHome}
                className="flex items-center gap-2"
              >
                <Home className="h-4 w-4" />
                返回首页
              </Button>
              <Button
                onClick={this.handleRefresh}
                className="flex items-center gap-2"
              >
                <RefreshCw className="h-4 w-4" />
                刷新页面
              </Button>
            </CardFooter>
          </Card>
        </div>
      );
    }

    return this.props.children;
  }
}

/**
 * 页面级错误边界 - 用于包裹单个页面
 */
export function PageErrorBoundary({ children }: { children: ReactNode }) {
  return (
    <ErrorBoundary>
      {children}
    </ErrorBoundary>
  );
}
