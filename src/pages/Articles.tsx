import { useEffect, useState, useMemo } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { toast } from "sonner";
import { getArticles, deleteArticle } from "@/db/api";
import type { ArticleWithSite } from "@/types/types";
import { Plus, FileText, Edit, Trash2, Calendar, Globe, Eye, Filter } from "lucide-react";
import { format } from "date-fns";
import { zhCN } from "date-fns/locale";

export default function Articles() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [articles, setArticles] = useState<ArticleWithSite[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSite, setSelectedSite] = useState<string>("all");

  useEffect(() => {
    loadArticles();
  }, [user]);

  const loadArticles = async () => {
    try {
      setLoading(true);
      const data = await getArticles(user?.id);
      setArticles(data);
    } catch (error) {
      toast.error("加载文章失败");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (articleId: string) => {
    try {
      await deleteArticle(articleId);
      toast.success("文章删除成功");
      loadArticles();
    } catch (error) {
      toast.error("删除失败");
      console.error(error);
    }
  };

  const handleEdit = (articleId: string) => {
    navigate(`/articles/${articleId}`);
  };

  const handleCreate = () => {
    navigate("/articles/new");
  };

  const handlePreview = (article: ArticleWithSite) => {
    if (article.wordpress_post_id && article.site) {
      const siteUrl = article.site.site_url.replace(/\/$/, "");
      const previewUrl = `${siteUrl}/?p=${article.wordpress_post_id}`;
      window.open(previewUrl, "_blank");
    } else {
      toast.error("该文章尚未发布到WordPress");
    }
  };

  // 获取所有唯一的站点
  const sites = useMemo(() => {
    const uniqueSites = new Map();
    articles.forEach((article) => {
      if (article.site) {
        uniqueSites.set(article.site.id, article.site);
      }
    });
    return Array.from(uniqueSites.values());
  }, [articles]);

  // 筛选文章
  const filteredArticles = useMemo(() => {
    if (selectedSite === "all") {
      return articles;
    }
    return articles.filter((article) => article.site_id === selectedSite);
  }, [articles, selectedSite]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10">
      <div className="container mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-6 max-w-7xl">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
              文章管理
            </h1>
            <p className="text-sm sm:text-base text-muted-foreground mt-1">
              管理您的文章内容，支持AI生成和发布到WordPress
            </p>
          </div>
          <Button
            onClick={handleCreate}
            className="w-full sm:w-auto bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-lg hover:shadow-xl transition-all"
          >
            <Plus className="mr-2 h-4 w-4" />
            创建文章
          </Button>
        </div>

        {/* 筛选器 */}
        {sites.length > 0 && (
          <Card className="border-0 shadow-lg bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <Filter className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm font-medium">按站点筛选：</span>
                <Select value={selectedSite} onValueChange={setSelectedSite}>
                  <SelectTrigger className="w-full sm:w-64">
                    <SelectValue placeholder="选择站点" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">全部站点</SelectItem>
                    {sites.map((site) => (
                      <SelectItem key={site.id} value={site.id}>
                        {site.site_name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {selectedSite !== "all" && (
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setSelectedSite("all")}
                  >
                    清除筛选
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>
        )}

        {loading ? (
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <Card key={i} className="border-0 shadow-lg">
                <CardContent className="p-4 sm:p-6">
                  <div className="space-y-3">
                    <div className="h-5 sm:h-6 w-2/3 bg-muted animate-pulse rounded" />
                    <div className="h-4 w-full bg-muted animate-pulse rounded" />
                    <div className="h-4 w-1/2 bg-muted animate-pulse rounded" />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : filteredArticles.length === 0 ? (
          <Card className="border-0 shadow-lg bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
            <CardContent className="flex flex-col items-center justify-center py-12 sm:py-16">
              <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full bg-gradient-to-br from-purple-500/10 to-pink-500/10 flex items-center justify-center mb-4">
                <FileText className="h-8 w-8 sm:h-10 sm:w-10 text-purple-600 dark:text-purple-400" />
              </div>
              <h3 className="text-lg sm:text-xl font-semibold mb-2">
                {selectedSite === "all" ? "暂无文章" : "该站点暂无文章"}
              </h3>
              <p className="text-sm sm:text-base text-muted-foreground text-center mb-6 max-w-md">
                {selectedSite === "all"
                  ? '点击"创建文章"按钮开始创建您的第一篇文章'
                  : "该站点下还没有文章，点击创建文章开始"}
              </p>
              <Button
                onClick={handleCreate}
                className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-lg"
              >
                <Plus className="mr-2 h-4 w-4" />
                创建文章
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-4">
            {filteredArticles.map((article) => (
              <Card
                key={article.id}
                className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm"
              >
                <CardContent className="p-4 sm:p-6">
                  <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                    <div className="flex-1 space-y-3 min-w-0">
                      <div className="flex flex-wrap items-center gap-2 sm:gap-3">
                        <h3 className="text-lg sm:text-xl font-semibold break-words">
                          {article.title}
                        </h3>
                        <Badge
                          variant={
                            article.status === "published" ? "default" : "secondary"
                          }
                          className="flex-shrink-0"
                        >
                          {article.status === "published" ? "已发布" : "草稿"}
                        </Badge>
                      </div>
                      {article.content && (
                        <p className="text-sm sm:text-base text-muted-foreground line-clamp-2 leading-relaxed">
                          {article.content.substring(0, 200)}
                          {article.content.length > 200 ? "..." : ""}
                        </p>
                      )}
                      <div className="flex flex-wrap items-center gap-3 sm:gap-4 text-xs sm:text-sm text-muted-foreground">
                        {article.keywords && (
                          <div className="flex items-center gap-1.5 bg-muted/50 px-2 py-1 rounded">
                            <span className="font-medium">关键词:</span>
                            <span>{article.keywords}</span>
                          </div>
                        )}
                        {article.site && (
                          <div className="flex items-center gap-1.5 bg-muted/50 px-2 py-1 rounded">
                            <Globe className="h-3 w-3" />
                            <span>{article.site.site_name}</span>
                          </div>
                        )}
                        <div className="flex items-center gap-1.5">
                          <Calendar className="h-3 w-3" />
                          <span>
                            {format(
                              new Date(article.created_at),
                              "yyyy年MM月dd日",
                              { locale: zhCN }
                            )}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="flex lg:flex-col gap-2 lg:ml-4">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEdit(article.id)}
                        className="flex-1 lg:flex-none lg:w-24"
                      >
                        <Edit className="h-4 w-4 mr-1" />
                        编辑
                      </Button>
                      {article.status === "published" && article.wordpress_post_id && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handlePreview(article)}
                          className="flex-1 lg:flex-none lg:w-24"
                        >
                          <Eye className="h-4 w-4 mr-1" />
                          预览
                        </Button>
                      )}
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button variant="outline" size="sm" className="flex-shrink-0">
                            <Trash2 className="h-4 w-4 text-red-600 dark:text-red-400" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>确认删除</AlertDialogTitle>
                            <AlertDialogDescription>
                              确定要删除文章"{article.title}"吗？此操作无法撤销。
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>取消</AlertDialogCancel>
                            <AlertDialogAction
                              onClick={() => handleDelete(article.id)}
                              className="bg-red-600 hover:bg-red-700"
                            >
                              删除
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
