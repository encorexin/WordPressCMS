import { useEffect, useState } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import {
  getWordPressSites,
  createWordPressSite,
  updateWordPressSite,
  deleteWordPressSite,
  updateSiteStatus,
} from "@/db/api";
import type { WordPressSite, WordPressSiteInput } from "@/types/types";
import { Plus, Globe, Trash2, Edit, CheckCircle, XCircle } from "lucide-react";
import { testWordPressConnection } from "@/utils/wordpress";
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

export default function Sites() {
  const { user } = useAuth();
  const [sites, setSites] = useState<WordPressSite[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingSite, setEditingSite] = useState<WordPressSite | null>(null);
  const [testingConnection, setTestingConnection] = useState<string | null>(
    null
  );

  const form = useForm<WordPressSiteInput>({
    defaultValues: {
      site_name: "",
      site_url: "",
      username: "",
      app_password: "",
    },
  });

  useEffect(() => {
    loadSites();
  }, [user]);

  useEffect(() => {
    if (editingSite) {
      form.reset({
        site_name: editingSite.site_name,
        site_url: editingSite.site_url,
        username: editingSite.username,
        app_password: editingSite.app_password,
      });
    } else {
      form.reset({
        site_name: "",
        site_url: "",
        username: "",
        app_password: "",
      });
    }
  }, [editingSite, form]);

  const loadSites = async () => {
    try {
      setLoading(true);
      const data = await getWordPressSites(user?.id);
      setSites(data);
    } catch (error) {
      toast.error("加载站点失败");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (data: WordPressSiteInput) => {
    try {
      if (editingSite) {
        await updateWordPressSite(editingSite.id, data);
        toast.success("站点更新成功");
      } else {
        if (!user?.id) {
          toast.error("用户未登录");
          return;
        }
        await createWordPressSite(user.id, data);
        toast.success("站点添加成功");
      }
      setDialogOpen(false);
      setEditingSite(null);
      form.reset();
      loadSites();
    } catch (error) {
      toast.error(editingSite ? "更新失败" : "添加失败");
      console.error(error);
    }
  };

  const handleDelete = async (siteId: string) => {
    try {
      await deleteWordPressSite(siteId);
      toast.success("站点删除成功");
      loadSites();
    } catch (error) {
      toast.error("删除失败");
      console.error(error);
    }
  };

  const handleTestConnection = async (site: WordPressSite) => {
    try {
      setTestingConnection(site.id);
      const result = await testWordPressConnection(site);
      if (result.success) {
        toast.success(result.message);
        await updateSiteStatus(site.id, "active");
      } else {
        toast.error(result.message);
        await updateSiteStatus(site.id, "inactive");
      }
      loadSites();
    } catch (error) {
      toast.error("测试连接失败");
      console.error(error);
    } finally {
      setTestingConnection(null);
    }
  };

  const handleEdit = (site: WordPressSite) => {
    setEditingSite(site);
    setDialogOpen(true);
  };

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open);
    if (!open) {
      setEditingSite(null);
      form.reset();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10">
      <div className="container mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-6 max-w-7xl">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
              WordPress站点管理
            </h1>
            <p className="text-sm sm:text-base text-muted-foreground mt-1">
              管理您的WordPress网站连接信息
            </p>
          </div>
          <Dialog open={dialogOpen} onOpenChange={handleDialogClose}>
            <DialogTrigger asChild>
              <Button className="w-full sm:w-auto bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-lg hover:shadow-xl transition-all">
                <Plus className="mr-2 h-4 w-4" />
                添加站点
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[500px]">
              <DialogHeader>
                <DialogTitle>
                  {editingSite ? "编辑站点" : "添加WordPress站点"}
                </DialogTitle>
                <DialogDescription>
                  填写WordPress网站的连接信息。应用程序密码可在WordPress后台生成。
                </DialogDescription>
              </DialogHeader>
              <Form {...form}>
                <form
                  onSubmit={form.handleSubmit(handleSubmit)}
                  className="space-y-4"
                >
                  <FormField
                    control={form.control}
                    name="site_name"
                    rules={{ required: "请输入站点名称" }}
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>站点名称</FormLabel>
                        <FormControl>
                          <Input placeholder="我的WordPress站点" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="site_url"
                    rules={{
                      required: "请输入站点地址",
                      pattern: {
                        value: /^https?:\/\/.+/,
                        message: "请输入有效的URL",
                      },
                    }}
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>站点地址</FormLabel>
                        <FormControl>
                          <Input
                            placeholder="https://example.com"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="username"
                    rules={{ required: "请输入用户名" }}
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>用户名</FormLabel>
                        <FormControl>
                          <Input placeholder="admin" {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="app_password"
                    rules={{ required: "请输入应用程序密码" }}
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>应用程序密码</FormLabel>
                        <FormControl>
                          <Input
                            type="password"
                            placeholder="xxxx xxxx xxxx xxxx xxxx xxxx"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <DialogFooter>
                    <Button
                      type="submit"
                      className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white"
                    >
                      {editingSite ? "更新" : "添加"}
                    </Button>
                  </DialogFooter>
                </form>
              </Form>
            </DialogContent>
          </Dialog>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {[1, 2, 3].map((i) => (
              <Card key={i} className="border-0 shadow-lg">
                <CardHeader>
                  <div className="h-5 sm:h-6 w-32 bg-muted animate-pulse rounded" />
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="h-4 w-full bg-muted animate-pulse rounded" />
                    <div className="h-4 w-3/4 bg-muted animate-pulse rounded" />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : sites.length === 0 ? (
          <Card className="border-0 shadow-lg bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
            <CardContent className="flex flex-col items-center justify-center py-12 sm:py-16">
              <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full bg-gradient-to-br from-blue-500/10 to-purple-500/10 flex items-center justify-center mb-4">
                <Globe className="h-8 w-8 sm:h-10 sm:w-10 text-blue-600 dark:text-blue-400" />
              </div>
              <h3 className="text-lg sm:text-xl font-semibold mb-2">暂无站点</h3>
              <p className="text-sm sm:text-base text-muted-foreground text-center mb-6 max-w-md">
                点击"添加站点"按钮开始添加您的WordPress网站
              </p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {sites.map((site) => (
              <Card
                key={site.id}
                className="border-0 shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-1 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm"
              >
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center space-x-2 flex-1 min-w-0">
                      <div className="p-2 rounded-lg bg-gradient-to-br from-blue-500/10 to-cyan-500/10 flex-shrink-0">
                        <Globe className="h-4 w-4 sm:h-5 sm:w-5 text-blue-600 dark:text-blue-400" />
                      </div>
                      <CardTitle className="text-base sm:text-lg truncate">
                        {site.site_name}
                      </CardTitle>
                    </div>
                    <Badge
                      variant={site.status === "active" ? "default" : "secondary"}
                      className="flex-shrink-0"
                    >
                      {site.status === "active" ? (
                        <>
                          <CheckCircle className="h-3 w-3 mr-1" />
                          已连接
                        </>
                      ) : (
                        <>
                          <XCircle className="h-3 w-3 mr-1" />
                          未连接
                        </>
                      )}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-3">
                    <div className="space-y-1">
                      <p className="text-xs sm:text-sm text-muted-foreground">站点地址</p>
                      <p className="text-xs sm:text-sm font-mono break-all bg-muted/50 p-2 rounded">
                        {site.site_url}
                      </p>
                    </div>
                    <div className="space-y-1">
                      <p className="text-xs sm:text-sm text-muted-foreground">用户名</p>
                      <p className="text-xs sm:text-sm font-medium">{site.username}</p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleTestConnection(site)}
                      disabled={testingConnection === site.id}
                      className="flex-1 min-w-[100px]"
                    >
                      {testingConnection === site.id ? "测试中..." : "测试连接"}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleEdit(site)}
                    >
                      <Edit className="h-4 w-4" />
                    </Button>
                    <AlertDialog>
                      <AlertDialogTrigger asChild>
                        <Button variant="outline" size="sm">
                          <Trash2 className="h-4 w-4 text-red-600 dark:text-red-400" />
                        </Button>
                      </AlertDialogTrigger>
                      <AlertDialogContent>
                        <AlertDialogHeader>
                          <AlertDialogTitle>确认删除</AlertDialogTitle>
                          <AlertDialogDescription>
                            确定要删除站点"{site.site_name}"吗？此操作无法撤销。
                          </AlertDialogDescription>
                        </AlertDialogHeader>
                        <AlertDialogFooter>
                          <AlertDialogCancel>取消</AlertDialogCancel>
                          <AlertDialogAction
                            onClick={() => handleDelete(site.id)}
                            className="bg-red-600 hover:bg-red-700"
                          >
                            删除
                          </AlertDialogAction>
                        </AlertDialogFooter>
                      </AlertDialogContent>
                    </AlertDialog>
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
