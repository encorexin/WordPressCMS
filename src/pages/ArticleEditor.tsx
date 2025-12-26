import { useEffect, useState } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { useNavigate, useParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import {
  getArticle,
  createArticle,
  updateArticle,
  updateArticleStatus,
  getWordPressSites,
} from "@/db/api";
import { getEffectiveAISettings, getImageSettings } from "@/db/aiSettings";
import { getTemplates, initDefaultTemplates, type ArticleTemplate } from "@/db/templateService";
import { getUnusedTopics, markTopicAsUsed, type Topic } from "@/db/topicService";
import type { ArticleInput, WordPressSite } from "@/types/types";
import { ArrowLeft, Save, Send, Sparkles, Loader2, Globe, Lightbulb, ImagePlus, Download } from "lucide-react";
import { sendChatStream } from "@/utils/aiChat";
import { publishToWordPress, updateWordPressPost, getWordPressCategories, type WordPressCategory } from "@/utils/wordpress";
import { generateImage, insertImageToContent, generateImagePrompt, IMAGE_PROVIDERS, type ImageGenerationConfig } from "@/utils/imageGeneration";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Streamdown } from "streamdown";
import { downloadSingleArticle } from "@/db/dataExport";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";


export default function ArticleEditor() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { id } = useParams();
  const isNew = id === "new";

  const [sites, setSites] = useState<WordPressSite[]>([]);
  const [templates, setTemplates] = useState<ArticleTemplate[]>([]);
  const [topics, setTopics] = useState<Topic[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<ArticleTemplate | null>(null);
  const [selectedTopic, setSelectedTopic] = useState<Topic | null>(null);
  const [loading, setLoading] = useState(!isNew);
  const [generating, setGenerating] = useState(false);
  const [generatingImage, setGeneratingImage] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [currentContent, setCurrentContent] = useState("");
  const [showImageDialog, setShowImageDialog] = useState(false);
  const [imagePrompt, setImagePrompt] = useState("");
  const [imageProvider, setImageProvider] = useState<string>("openai");
  const [imageApiKey, setImageApiKey] = useState("");
  const [imageEndpoint, setImageEndpoint] = useState("");
  const [imageModel, setImageModel] = useState("");
  const [imageStatus, setImageStatus] = useState("");
  const [wpPostId, setWpPostId] = useState<string | null>(null);
  const [wpCategories, setWpCategories] = useState<WordPressCategory[]>([]);
  const [selectedCategories, setSelectedCategories] = useState<number[]>([]);
  const [postSlug, setPostSlug] = useState("");

  const form = useForm<ArticleInput>({
    defaultValues: {
      title: "",
      content: "",
      keywords: "",
      template: "",
      site_id: "",
    },
  });

  useEffect(() => {
    loadSites();
    loadTemplates();
    loadTopics();
    loadImageSettings();
    if (!isNew && id) {
      loadArticle(id);
    }
  }, [id, isNew, user]);

  const loadTemplates = async () => {
    if (!user?.id) return;
    try {
      await initDefaultTemplates(user.id);
      const data = await getTemplates(user.id);
      setTemplates(data);
      // 默认选择第一个模板
      if (data.length > 0 && !selectedTemplate) {
        setSelectedTemplate(data[0]);
        form.setValue("template", data[0].name);
      }
    } catch (error) {
      console.error("加载模板失败:", error);
    }
  };

  const loadTopics = async () => {
    if (!user?.id) return;
    try {
      const data = await getUnusedTopics(user.id);
      setTopics(data);
    } catch (error) {
      console.error("加载主题失败:", error);
    }
  };

  const handleSelectTopic = (topic: Topic) => {
    setSelectedTopic(topic);
    // 自动填充关键词
    if (topic.keywords) {
      form.setValue("keywords", topic.keywords);
    }
    // 自动填充标题
    if (topic.title) {
      form.setValue("title", topic.title);
    }
    toast.success(`已选择主题: ${topic.title}`);
  };

  const loadSites = async () => {
    try {
      const data = await getWordPressSites(user?.id);
      setSites(data);
    } catch (error) {
      console.error("加载站点失败:", error);
    }
  };

  // 加载 WordPress 分类
  const loadCategories = async (siteId: string) => {
    const site = sites.find(s => s.id === siteId);
    if (!site) return;

    try {
      const result = await getWordPressCategories(site);
      if (result.success) {
        setWpCategories(result.categories);
      } else {
        console.error("加载分类失败:", result.message);
        setWpCategories([]);
      }
    } catch (error) {
      console.error("加载分类失败:", error);
      setWpCategories([]);
    }
  };

  // 加载保存的图片生成设置
  const loadImageSettings = async () => {
    if (!user?.id) return;
    try {
      const settings = await getImageSettings(user.id);
      if (settings && settings.enabled) {
        setImageProvider(settings.provider);
        setImageApiKey(settings.apiKey);
        setImageEndpoint(settings.endpoint);
        setImageModel(settings.model);
      }
    } catch (error) {
      console.error("加载图片设置失败:", error);
    }
  };

  const openImageDialog = () => {
    const keywords = form.getValues("keywords");
    const title = form.getValues("title");
    const prompt = generateImagePrompt(keywords || "", title || "");
    setImagePrompt(prompt);
    setShowImageDialog(true);
  };

  const handleGenerateImage = async () => {
    if (!imageApiKey) {
      toast.error("请输入图片生成 API Key");
      return;
    }

    if (!imagePrompt) {
      toast.error("请输入图片描述");
      return;
    }

    if (imageProvider === 'custom' && !imageEndpoint) {
      toast.error("自定义端点需要提供 API 端点");
      return;
    }

    try {
      setGeneratingImage(true);
      setImageStatus("正在生成图片...");

      const config: ImageGenerationConfig = {
        provider: imageProvider as ImageGenerationConfig["provider"],
        apiKey: imageApiKey,
        apiEndpoint: imageEndpoint || undefined,
        model: imageModel || undefined,
      };

      const result = await generateImage(imagePrompt, config, setImageStatus);

      // 将图片插入到文章内容中
      const currentContent = form.getValues("content") || "";
      const newContent = insertImageToContent(currentContent, result.url, result.alt);
      form.setValue("content", newContent);
      setCurrentContent(newContent);

      toast.success("图片已插入到文章开头");
      setShowImageDialog(false);
    } catch (error) {
      const message = error instanceof Error ? error.message : "图片生成失败";
      toast.error(message);
      setImageStatus(`错误: ${message}`);
    } finally {
      setGeneratingImage(false);
    }
  };


  const loadArticle = async (articleId: string) => {
    try {
      setLoading(true);
      const article = await getArticle(articleId);
      if (article) {
        form.reset({
          title: article.title,
          content: article.content || "",
          keywords: article.keywords || "",
          template: article.template || "默认模板",
          site_id: article.site_id || "",
        });
        setCurrentContent(article.content || "");
        // 加载WordPress文章ID用于后续更新
        if (article.wordpress_post_id) {
          setWpPostId(article.wordpress_post_id);
        }
      }
    } catch (error) {
      toast.error("加载文章失败");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (data: ArticleInput) => {
    try {
      if (!user?.id) {
        toast.error("用户未登录");
        return;
      }

      if (isNew) {
        await createArticle(user.id, data);
        toast.success("文章创建成功");
      } else if (id) {
        await updateArticle(id, data);
        toast.success("文章保存成功");
      }
      navigate("/articles");
    } catch (error) {
      toast.error("保存失败");
      console.error(error);
    }
  };

  const handleGenerate = async () => {
    const keywords = form.getValues("keywords");
    const template = form.getValues("template");

    if (!keywords) {
      toast.error("请输入关键词");
      return;
    }

    if (!user?.id) {
      toast.error("用户未登录");
      return;
    }

    try {
      setGenerating(true);
      setCurrentContent("");

      // 获取用户的 AI 设置
      const aiSettings = await getEffectiveAISettings(user.id);

      if (!aiSettings.api_key) {
        toast.error("请先在 AI 设置中配置 API Key");
        setGenerating(false);
        return;
      }

      // 优先使用选中模板的提示词，否则使用 AI 设置中的默认提示词
      const basePrompt = selectedTemplate?.system_prompt || aiSettings.system_prompt;

      // 处理系统提示词中的占位符
      const systemPrompt = basePrompt
        .replace(/\{keywords\}/g, keywords)
        .replace(/\{template\}/g, template || "默认模板");

      // 用户消息：简洁的生成请求
      const userMessage = `关键词：${keywords}\n模板风格：${template || "默认模板"}\n\n请直接输出文章内容：`;

      await sendChatStream({
        endpoint: aiSettings.api_endpoint,
        apiKey: aiSettings.api_key,
        model: aiSettings.model,
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: userMessage,
          },
        ],
        onUpdate: (content: string) => {
          setCurrentContent(content);
          form.setValue("content", content);
        },
        onComplete: async () => {
          toast.success("文章生成完成");
          setGenerating(false);
          // 如果选择了主题，标记为已使用
          if (selectedTopic) {
            await markTopicAsUsed(selectedTopic.id);
            setSelectedTopic(null);
            await loadTopics(); // 刷新主题列表
          }
        },
        onError: (error: Error) => {
          toast.error("生成失败: " + error.message);
          setGenerating(false);
        },
      });
    } catch (error) {
      toast.error("生成失败");
      console.error(error);
      setGenerating(false);
    }
  };

  const handlePublish = async () => {
    const title = form.getValues("title");
    const content = form.getValues("content");
    const siteId = form.getValues("site_id");

    if (!title || !content) {
      toast.error("请填写标题和内容");
      return;
    }

    if (!siteId) {
      toast.error("请选择发布站点");
      return;
    }

    const site = sites.find((s) => s.id === siteId);
    if (!site) {
      toast.error("站点不存在");
      return;
    }

    try {
      setPublishing(true);

      // 先保存文章
      if (!user?.id) {
        toast.error("用户未登录");
        return;
      }

      let articleId = id;
      if (isNew) {
        const article = await createArticle(user.id, {
          title,
          content,
          keywords: form.getValues("keywords"),
          template: form.getValues("template"),
          site_id: siteId,
        });
        articleId = article.id;
      } else if (id) {
        await updateArticle(id, {
          title,
          content,
          site_id: siteId,
        });
      }

      // 发布到WordPress - 检查是否需要更新现有文章
      const publishOptions = {
        categories: selectedCategories.length > 0 ? selectedCategories : undefined,
        slug: postSlug || undefined,
      };

      let result;
      if (wpPostId) {
        // 已有WordPress文章ID，更新现有文章
        result = await updateWordPressPost(site, wpPostId, title, content, publishOptions);
        if (result.success && articleId) {
          await updateArticleStatus(articleId, "published");
          toast.success("更新发布成功");
          navigate("/articles");
        } else {
          toast.error(result.message);
        }
      } else {
        // 新发布
        result = await publishToWordPress(site, title, content, publishOptions);
        if (result.success && articleId) {
          await updateArticleStatus(articleId, "published", result.postId);
          setWpPostId(result.postId || null);
          toast.success("发布成功");
          navigate("/articles");
        } else {
          toast.error(result.message);
        }
      }
    } catch (error) {
      toast.error("发布失败");
      console.error(error);
    } finally {
      setPublishing(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600 dark:text-blue-400" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10">
      <div className="container mx-auto px-4 sm:px-6 py-4 sm:py-6 space-y-4 sm:space-y-6 max-w-7xl">
        {/* 头部操作栏 */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4">
          <div className="flex items-center space-x-2 sm:space-x-4">
            <Button variant="ghost" size="sm" onClick={() => navigate("/articles")}>
              <ArrowLeft className="h-4 w-4 mr-1 sm:mr-2" />
              返回
            </Button>
            <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
              {isNew ? "创建文章" : "编辑文章"}
            </h1>
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={form.handleSubmit(handleSave)}
              className="flex-1 sm:flex-none border-2 hover:bg-blue-50 dark:hover:bg-blue-950/50"
            >
              <Save className="mr-2 h-4 w-4" />
              保存
            </Button>
            <Button
              onClick={handlePublish}
              disabled={publishing}
              className="flex-1 sm:flex-none bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white shadow-lg"
            >
              {publishing ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : (
                <Send className="mr-2 h-4 w-4" />
              )}
              发布
            </Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="icon" className="border-2">
                  <Download className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => {
                  const article = {
                    title: form.getValues("title") || "无标题",
                    content: form.getValues("content") || "",
                    keywords: form.getValues("keywords"),
                    template: form.getValues("template"),
                    status: "draft",
                  };
                  downloadSingleArticle(article, 'markdown');
                  toast.success("文章已下载为 Markdown 格式");
                }}>
                  下载 Markdown (.md)
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => {
                  const article = {
                    title: form.getValues("title") || "无标题",
                    content: form.getValues("content") || "",
                    keywords: form.getValues("keywords"),
                    template: form.getValues("template"),
                    status: "draft",
                  };
                  downloadSingleArticle(article, 'txt');
                  toast.success("文章已下载为文本格式");
                }}>
                  下载文本 (.txt)
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => {
                  const article = {
                    title: form.getValues("title") || "无标题",
                    content: form.getValues("content") || "",
                    keywords: form.getValues("keywords"),
                    template: form.getValues("template"),
                    status: "draft",
                  };
                  downloadSingleArticle(article, 'html');
                  toast.success("文章已下载为 HTML 格式");
                }}>
                  下载网页 (.html)
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>

        <div className="grid gap-4 sm:gap-6 lg:grid-cols-3">
          {/* 主编辑区域 */}
          <div className="lg:col-span-2 space-y-4 sm:space-y-6 min-w-0">
            <Card className="border-0 shadow-lg bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
              <CardHeader>
                <CardTitle className="text-lg sm:text-xl">文章内容</CardTitle>
              </CardHeader>
              <CardContent>
                <Form {...form}>
                  <form className="space-y-4">
                    <FormField
                      control={form.control}
                      name="title"
                      rules={{ required: "请输入文章标题" }}
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>标题</FormLabel>
                          <FormControl>
                            <Input placeholder="输入文章标题" {...field} className="text-base" />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                    <FormField
                      control={form.control}
                      name="content"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>内容</FormLabel>
                          <FormControl>
                            <Tabs defaultValue="edit" className="w-full">
                              <TabsList className="grid w-full grid-cols-2">
                                <TabsTrigger value="edit">编辑</TabsTrigger>
                                <TabsTrigger value="preview">预览</TabsTrigger>
                              </TabsList>
                              <TabsContent value="edit">
                                <Textarea
                                  placeholder="输入文章内容（支持Markdown格式）"
                                  className="min-h-[300px] sm:min-h-[400px] font-mono text-sm sm:text-base"
                                  {...field}
                                  value={currentContent || field.value}
                                  onChange={(e) => {
                                    field.onChange(e);
                                    setCurrentContent(e.target.value);
                                  }}
                                />
                              </TabsContent>
                              <TabsContent value="preview">
                                <div className="min-h-[300px] sm:min-h-[400px] p-3 sm:p-4 border rounded-md prose prose-sm max-w-none dark:prose-invert overflow-x-auto overflow-y-auto break-words [&_pre]:overflow-x-auto [&_pre]:max-w-full [&_code]:break-all [&_pre_code]:break-normal [&_table]:block [&_table]:overflow-x-auto">
                                  <Streamdown>
                                    {currentContent || field.value || "暂无内容"}
                                  </Streamdown>
                                </div>
                              </TabsContent>
                            </Tabs>
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </form>
                </Form>
              </CardContent>
            </Card>
          </div>

          {/* 侧边栏 */}
          <div className="space-y-4 sm:space-y-6">
            {/* AI生成 */}
            <Card className="border-0 shadow-lg bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-950/30 dark:to-pink-950/30 backdrop-blur-sm">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2 text-base sm:text-lg">
                  <Sparkles className="h-4 w-4 sm:h-5 sm:w-5 text-purple-600 dark:text-purple-400" />
                  <span>AI生成</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Form {...form}>
                  <form className="space-y-4">
                    {/* 主题选择 */}
                    {topics.length > 0 && (
                      <div className="space-y-2">
                        <label className="text-sm font-medium flex items-center gap-2">
                          <Lightbulb className="h-4 w-4 text-amber-500" />
                          从主题库选择
                        </label>
                        <Select
                          onValueChange={(value) => {
                            const topic = topics.find(t => t.id === value);
                            if (topic) {
                              handleSelectTopic(topic);
                            }
                          }}
                          value={selectedTopic?.id || ""}
                        >
                          <SelectTrigger className="text-sm">
                            <SelectValue placeholder="选择一个主题（可选）" />
                          </SelectTrigger>
                          <SelectContent>
                            {topics.map((topic) => (
                              <SelectItem key={topic.id} value={topic.id}>
                                <div className="truncate max-w-[200px]">{topic.title}</div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        {selectedTopic && (
                          <p className="text-xs text-muted-foreground line-clamp-2">
                            {selectedTopic.description}
                          </p>
                        )}
                      </div>
                    )}
                    <FormField
                      control={form.control}
                      name="keywords"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel className="text-sm">关键词</FormLabel>
                          <FormControl>
                            <Input
                              placeholder="输入关键词，用逗号分隔"
                              {...field}
                              className="text-sm"
                            />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                    <FormField
                      control={form.control}
                      name="template"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel className="text-sm">模板风格</FormLabel>
                          <Select
                            onValueChange={(value) => {
                              field.onChange(value);
                              const template = templates.find(t => t.name === value);
                              setSelectedTemplate(template || null);
                            }}
                            value={field.value}
                          >
                            <FormControl>
                              <SelectTrigger className="text-sm">
                                <SelectValue placeholder="选择模板风格" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              {templates.map((template) => (
                                <SelectItem key={template.id} value={template.name}>
                                  {template.name}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                          {selectedTemplate && (
                            <p className="text-xs text-muted-foreground mt-1">
                              {selectedTemplate.description}
                            </p>
                          )}
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                    <Button
                      type="button"
                      className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white shadow-lg"
                      onClick={handleGenerate}
                      disabled={generating}
                    >
                      {generating ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          生成中...
                        </>
                      ) : (
                        <>
                          <Sparkles className="mr-2 h-4 w-4" />
                          AI生成文章
                        </>
                      )}
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      className="w-full"
                      onClick={openImageDialog}
                      disabled={generating || generatingImage}
                    >
                      <ImagePlus className="mr-2 h-4 w-4" />
                      生成配图
                    </Button>
                  </form>
                </Form>
              </CardContent>
            </Card>

            {/* 发布设置 */}
            <Card className="border-0 shadow-lg bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-blue-950/30 dark:to-cyan-950/30 backdrop-blur-sm">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2 text-base sm:text-lg">
                  <Globe className="h-4 w-4 sm:h-5 sm:w-5 text-blue-600 dark:text-blue-400" />
                  <span>发布设置</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Form {...form}>
                  <form className="space-y-4">
                    <FormField
                      control={form.control}
                      name="site_id"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel className="text-sm">目标站点</FormLabel>
                          <Select
                            onValueChange={(value) => {
                              field.onChange(value);
                              loadCategories(value);
                              setSelectedCategories([]);
                            }}
                            value={field.value}
                          >
                            <FormControl>
                              <SelectTrigger className="text-sm">
                                <SelectValue placeholder="选择WordPress站点" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              {sites.map((site) => (
                                <SelectItem key={site.id} value={site.id}>
                                  {site.site_name}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                          <FormMessage />
                        </FormItem>
                      )}
                    />

                    {/* 文章别名 */}
                    <div className="space-y-2">
                      <Label className="text-sm">文章别名 (Slug)</Label>
                      <Input
                        placeholder="留空自动生成，如: my-article-title"
                        value={postSlug}
                        onChange={(e) => setPostSlug(e.target.value)}
                        className="text-sm"
                      />
                      <p className="text-xs text-muted-foreground">
                        用于生成 SEO 友好的 URL
                      </p>
                    </div>

                    {/* 文章分类 */}
                    {wpCategories.length > 0 && (
                      <div className="space-y-2">
                        <Label className="text-sm">文章分类</Label>
                        <div className="border rounded-md p-3 max-h-40 overflow-y-auto space-y-2 bg-white/50 dark:bg-gray-900/50">
                          {wpCategories.map((cat) => (
                            <label
                              key={cat.id}
                              className="flex items-center space-x-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 p-1 rounded text-sm"
                            >
                              <input
                                type="checkbox"
                                checked={selectedCategories.includes(cat.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedCategories([...selectedCategories, cat.id]);
                                  } else {
                                    setSelectedCategories(selectedCategories.filter(id => id !== cat.id));
                                  }
                                }}
                                className="rounded border-gray-300"
                              />
                              <span>{cat.name}</span>
                              <span className="text-xs text-muted-foreground">({cat.count})</span>
                            </label>
                          ))}
                        </div>
                        {selectedCategories.length > 0 && (
                          <p className="text-xs text-muted-foreground">
                            已选择 {selectedCategories.length} 个分类
                          </p>
                        )}
                      </div>
                    )}
                  </form>
                </Form>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* 图片生成对话框 */}
      <Dialog open={showImageDialog} onOpenChange={setShowImageDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <ImagePlus className="h-5 w-5" />
              AI 生成配图
            </DialogTitle>
            <DialogDescription>
              使用 AI 为文章生成配图
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>图片生成服务</Label>
              <Select value={imageProvider} onValueChange={(v) => {
                setImageProvider(v);
                // 设置默认端点
                const provider = IMAGE_PROVIDERS.find(p => p.value === v);
                if (provider && provider.endpoint) {
                  setImageEndpoint(provider.endpoint);
                }
              }}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {IMAGE_PROVIDERS.map((provider) => (
                    <SelectItem key={provider.value} value={provider.value}>
                      {provider.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                {IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.description}
              </p>
            </div>

            {/* 自定义端点输入 */}
            <div className="space-y-2">
              <Label>API 端点 {imageProvider === 'custom' ? '*' : '(可选)'}</Label>
              <Input
                placeholder={IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.endpoint || "输入 API 端点"}
                value={imageEndpoint}
                onChange={(e) => setImageEndpoint(e.target.value)}
              />
            </div>

            {/* 模型选择 */}
            <div className="space-y-2">
              <Label>模型 (可选)</Label>
              <Input
                placeholder={IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.models?.[0] || "使用默认模型"}
                value={imageModel}
                onChange={(e) => setImageModel(e.target.value)}
              />
              {IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.models?.length ? (
                <p className="text-xs text-muted-foreground">
                  可用模型: {IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.models?.join(', ')}
                </p>
              ) : null}
            </div>

            <div className="space-y-2">
              <Label>API Key</Label>
              <Input
                type="password"
                placeholder="输入对应服务的 API Key"
                value={imageApiKey}
                onChange={(e) => setImageApiKey(e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label>图片描述</Label>
              <Textarea
                placeholder="描述你想要的图片..."
                value={imagePrompt}
                onChange={(e) => setImagePrompt(e.target.value)}
                className="min-h-[100px]"
              />
            </div>

            {imageStatus && (
              <div className="text-sm text-muted-foreground bg-gray-100 dark:bg-gray-800 p-2 rounded">
                {imageStatus}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowImageDialog(false)}>
              取消
            </Button>
            <Button
              onClick={handleGenerateImage}
              disabled={generatingImage}
              className="bg-gradient-to-r from-green-500 to-teal-500"
            >
              {generatingImage ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  生成中...
                </>
              ) : (
                <>
                  <ImagePlus className="mr-2 h-4 w-4" />
                  生成图片
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

