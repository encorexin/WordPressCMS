import { ArrowLeft, Download, FileText, Globe, History, ImagePlus, Lightbulb, Loader2, PenTool, Save, Send, Sparkles, Wand2, Settings } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { Streamdown } from "streamdown";
import { RichTextEditor } from "@/components/common/RichTextEditor";
import { VersionHistoryDialog } from "@/components/common/VersionHistoryDialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { useAuth } from "@/context/LocalAuthProvider";
import { downloadSingleArticle } from "@/db/dataExport";
import type { ArticleVersion, AISettings } from "@/db/database";
import { useHotkeys } from "@/hooks/use-hotkeys";
import {
  useArticleForm,
  useArticleGenerator,
  useArticlePublisher,
  useImageGenerator,
  useArticleAssets,
  useVersionHistory,
} from "@/hooks/useArticle";
import { getAllAISettings, getEffectiveAISettings, getSlugSettings } from "@/db/aiSettings";
import { logger } from "@/utils/logger";

export default function ArticleEditor() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [currentContent, setCurrentContent] = useState("");
  const [useRichEditor, setUseRichEditor] = useState(false);
  const [aiSettingsList, setAiSettingsList] = useState<AISettings[]>([]);
  const [selectedAiSettingsId, setSelectedAiSettingsId] = useState<string>("");

  const {
    form,
    loading,
    sites,
    wpPostId,
    setWpPostId,
    isNew,
    articleId,
    handleSave,
    saveArticle,
  } = useArticleForm();

  const {
    templates,
    topics,
    selectedTemplate,
    selectedTopic,
    setSelectedTemplate,
    selectTopic,
    clearSelectedTopic,
    useTopic,
    loadTopics,
  } = useArticleAssets();

  const { generating, progress: generateProgress, generate, stop: stopGenerate } = useArticleGenerator({
    onUpdate: (content) => {
      setCurrentContent(content);
      form.setValue("content", content);
    },
    selectedTopic,
    onTopicUsed: () => {
      clearSelectedTopic();
      loadTopics();
    },
  });

  const {
    publishing,
    categories: wpCategories,
    selectedCategories,
    setSelectedCategories,
    postSlug,
    setPostSlug,
    generatingSlug,
    loadCategories,
    publish,
    generateSlug,
  } = useArticlePublisher({
    articleId,
    wpPostId,
    onPublished: (postId) => setWpPostId(postId),
    onUpdated: () => navigate("/articles"),
  });

  const {
    generating: generatingImage,
    status: imageStatus,
    showDialog: showImageDialog,
    setShowDialog: setShowImageDialog,
    prompt: imagePrompt,
    setPrompt: setImagePrompt,
    settings: imageSettings,
    loadSettings: loadImageSettings,
    openDialog,
    generate: generateImageAction,
    insertImage,
    updateSettings: updateImageSettings,
    providers: IMAGE_PROVIDERS,
  } = useImageGenerator();

  const {
    versions,
    showDialog: showVersionDialog,
    loading: loadingVersions,
    openDialog: openVersionDialog,
    closeDialog: closeVersionDialog,
    restore: restoreVersion,
  } = useVersionHistory({
    articleId,
    userId: user?.id,
    onRestore: (version: ArticleVersion) => {
      form.setValue("title", version.title);
      form.setValue("content", version.content || "");
      form.setValue("keywords", version.keywords || "");
      form.setValue("template", version.template || "");
      setCurrentContent(version.content || "");
    },
  });

  const handleSelectTopic = useCallback(
    (topic: { id: string; title: string; keywords?: string; description?: string }) => {
      selectTopic(topic as Parameters<typeof selectTopic>[0]);
      if (topic.keywords) {
        form.setValue("keywords", topic.keywords);
      }
      if (topic.title) {
        form.setValue("title", topic.title);
      }
    },
    [selectTopic, form]
  );

  useEffect(() => {
    const loadAiSettings = async () => {
      if (!user?.id) return;
      try {
        const settings = await getAllAISettings(user.id);
        setAiSettingsList(settings);
        const defaultSettings = settings.find(s => s.is_default);
        if (defaultSettings) {
          setSelectedAiSettingsId(defaultSettings.id);
        } else if (settings.length > 0) {
          setSelectedAiSettingsId(settings[0].id);
        }
      } catch (error) {
        logger.error("加载 AI 配置失败:", error);
      }
    };
    loadAiSettings();
  }, [user?.id]);

  const handleGenerateSlug = useCallback(async () => {
    const title = form.getValues("title");
    if (!title) {
      toast.error("请先输入文章标题");
      return;
    }

    if (!user?.id) {
      toast.error("请先登录");
      return;
    }

    try {
      const settings = await getEffectiveAISettings(user.id);
      const slugSettings = await getSlugSettings(user.id);

      if (slugSettings && !slugSettings.enabled) {
        toast.error("文章别名生成功能已禁用，请在 AI 设置中启用");
        return;
      }

      const slugModelToUse = slugSettings?.model || settings.model;

      if (!settings.api_key || !settings.api_endpoint) {
        toast.error("请先在 AI 设置中配置 API");
        return;
      }

      await generateSlug(title, {
        api_endpoint: settings.api_endpoint,
        api_key: settings.api_key,
        model: slugModelToUse,
      });
    } catch (error) {
      logger.error("生成别名失败:", error);
    }
  }, [form, user?.id, generateSlug]);

  const handleOpenImageDialog = useCallback(() => {
    const keywords = form.getValues("keywords");
    const title = form.getValues("title");
    openDialog(keywords || "", title || "");
  }, [form, openDialog]);

  const handleGenerateImage = useCallback(async () => {
    const result = await generateImageAction();
    if (result) {
      const currentContentValue = form.getValues("content") || "";
      const newContent = insertImage(currentContentValue, result.url, result.alt);
      form.setValue("content", newContent);
      setCurrentContent(newContent);
    }
  }, [generateImageAction, form, insertImage]);

  const handlePublish = useCallback(async () => {
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

    const saved = await saveArticle(form.getValues());
    if (!saved) return;

    const result = await publish(site, title, content);
    if (result.success) {
      navigate("/articles");
    }
  }, [form, sites, saveArticle, publish, navigate]);

  const handleGenerate = useCallback(() => {
    const keywords = form.getValues("keywords");
    const template = form.getValues("template");
    generate(keywords, template, selectedTemplate?.system_prompt, selectedAiSettingsId || undefined);
  }, [form, generate, selectedTemplate, selectedAiSettingsId]);

  const handleDownload = useCallback(
    (format: "markdown" | "txt" | "html") => {
      const article = {
        title: form.getValues("title") || "无标题",
        content: form.getValues("content") || "",
        keywords: form.getValues("keywords"),
        template: form.getValues("template"),
        status: "draft",
      };
      downloadSingleArticle(article, format);
      toast.success(`文章已下载为 ${format === "markdown" ? "Markdown" : format === "txt" ? "文本" : "HTML"} 格式`);
    },
    [form]
  );

  useHotkeys([
    {
      key: "s",
      ctrl: true,
      handler: () => form.handleSubmit(handleSave)(),
    },
    {
      key: "p",
      ctrl: true,
      handler: () => {
        if (window.confirm("确定要发布这篇文章吗？")) {
          handlePublish();
        }
      },
    },
  ]);

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
            {!isNew && (
              <Button
                variant="outline"
                onClick={openVersionDialog}
                className="hidden sm:flex border-2 hover:bg-blue-50 dark:hover:bg-blue-950/50"
              >
                <History className="mr-2 h-4 w-4" />
                历史版本
              </Button>
            )}
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
                {!isNew && (
                  <DropdownMenuItem onClick={openVersionDialog}>
                    <History className="mr-2 h-4 w-4" />
                    历史版本
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem onClick={() => handleDownload("markdown")}>
                  下载 Markdown (.md)
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleDownload("txt")}>
                  下载文本
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleDownload("html")}>
                  下载网页
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>

        <div className="grid gap-4 sm:gap-6 lg:grid-cols-3">
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
                          <div className="flex items-center justify-between mb-2">
                            <FormLabel>内容</FormLabel>
                            <div className="flex items-center gap-2">
                              <Switch
                                id="editor-mode"
                                checked={useRichEditor}
                                onCheckedChange={setUseRichEditor}
                              />
                              <Label htmlFor="editor-mode" className="text-sm cursor-pointer flex items-center gap-1">
                                {useRichEditor ? (
                                  <><PenTool className="h-3 w-3" /> 富文本</>
                                ) : (
                                  <><FileText className="h-3 w-3" /> Markdown</>
                                )}
                              </Label>
                            </div>
                          </div>
                          <FormControl>
                            {useRichEditor ? (
                              <RichTextEditor
                                content={currentContent || field.value || ""}
                                onChange={(content) => {
                                  field.onChange(content);
                                  setCurrentContent(content);
                                }}
                                placeholder="开始写作..."
                              />
                            ) : (
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
                            )}
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

          <div className="space-y-4 sm:space-y-6">
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
                    {topics.length > 0 && (
                      <div className="space-y-2">
                        <label className="text-sm font-medium flex items-center gap-2">
                          <Lightbulb className="h-4 w-4 text-amber-500" />
                          从主题库选择
                        </label>
                        <Select
                          onValueChange={(value) => {
                            const topic = topics.find((t) => t.id === value);
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
                    {aiSettingsList.length > 0 && (
                      <div className="space-y-2">
                        <label className="text-sm font-medium flex items-center gap-2">
                          <Settings className="h-4 w-4 text-purple-500" />
                          AI 配置
                        </label>
                        <Select
                          value={selectedAiSettingsId}
                          onValueChange={setSelectedAiSettingsId}
                        >
                          <SelectTrigger className="text-sm">
                            <SelectValue placeholder="选择 AI 配置" />
                          </SelectTrigger>
                          <SelectContent>
                            {aiSettingsList.map((setting) => (
                              <SelectItem key={setting.id} value={setting.id}>
                                <div className="flex items-center gap-2">
                                  {setting.name}
                                  {setting.is_default && (
                                    <span className="text-xs text-muted-foreground">(默认)</span>
                                  )}
                                </div>
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <p className="text-xs text-muted-foreground">
                          {aiSettingsList.find(s => s.id === selectedAiSettingsId)?.model || "选择配置"}
                        </p>
                      </div>
                    )}
                    <FormField
                      control={form.control}
                      name="keywords"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel className="text-sm">关键词</FormLabel>
                          <FormControl>
                            <Input placeholder="输入关键词，用逗号分隔" {...field} className="text-sm" />
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
                              const template = templates.find((t) => t.name === value);
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
                    <div className="space-y-2">
                      <Button
                        type="button"
                        className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white shadow-lg"
                        onClick={generating ? stopGenerate : handleGenerate}
                      >
                        {generating ? (
                          <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            停止生成
                          </>
                        ) : (
                          <>
                            <Sparkles className="mr-2 h-4 w-4" />
                            AI生成文章
                          </>
                        )}
                      </Button>
                      {generating && (
                        <div className="space-y-1">
                          <div className="h-2 bg-muted rounded-full overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-purple-500 to-pink-500 transition-all duration-300"
                              style={{ width: `${Math.min(generateProgress, 100)}%` }}
                            />
                          </div>
                          <p className="text-xs text-center text-muted-foreground">
                            正在生成... {Math.round(Math.min(generateProgress, 100))}%
                          </p>
                        </div>
                      )}
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      className="w-full"
                      onClick={handleOpenImageDialog}
                      disabled={generating || generatingImage}
                    >
                      <ImagePlus className="mr-2 h-4 w-4" />
                      生成配图
                    </Button>
                  </form>
                </Form>
              </CardContent>
            </Card>

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
                              const site = sites.find((s) => s.id === value);
                              if (site) loadCategories(site);
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

                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <Label className="text-sm">文章别名</Label>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={handleGenerateSlug}
                          disabled={generatingSlug}
                          className="h-6 px-2 text-xs"
                        >
                          {generatingSlug ? (
                            <Loader2 className="h-3 w-3 animate-spin mr-1" />
                          ) : (
                            <Wand2 className="h-3 w-3 mr-1" />
                          )}
                          AI 生成
                        </Button>
                      </div>
                      <Input
                        placeholder="留空自动生成，如: my-article-title"
                        value={postSlug}
                        onChange={(e) => setPostSlug(e.target.value)}
                        className="text-sm"
                      />
                      <p className="text-xs text-muted-foreground">
                        用于生成 SEO 友好的 URL，点击 AI 生成可根据标题自动生成
                      </p>
                    </div>

                    {wpCategories.length > 0 && (
                      <div className="space-y-2">
                        <Label className="text-sm">文章分类</Label>
                        <div className="border rounded-md p-3 max-h-40 overflow-y-auto space-y-2 bg-white/50 dark:bg-gray-900/50">
                          {wpCategories.map((cat) => (
                            <label
                              key={cat.id}
                              className="flex items-center space-x-2 cursor-pointer hover:bg-muted/50 p-1 rounded"
                            >
                              <input
                                type="checkbox"
                                checked={selectedCategories.includes(cat.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedCategories([...selectedCategories, cat.id]);
                                  } else {
                                    setSelectedCategories(
                                      selectedCategories.filter((id) => id !== cat.id)
                                    );
                                  }
                                }}
                                className="rounded border-gray-300"
                              />
                              <span className="text-sm">{cat.name}</span>
                              {cat.count > 0 && (
                                <span className="text-xs text-muted-foreground">
                                  ({cat.count})
                                </span>
                              )}
                            </label>
                          ))}
                        </div>
                      </div>
                    )}
                  </form>
                </Form>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      <Dialog open={showImageDialog} onOpenChange={setShowImageDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>生成配图</DialogTitle>
            <DialogDescription>使用 AI 生成文章配图</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>图片描述</Label>
              <Textarea
                placeholder="描述你想要生成的图片..."
                value={imagePrompt}
                onChange={(e) => setImagePrompt(e.target.value)}
                className="min-h-[80px]"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>服务商</Label>
                <Select
                  value={imageSettings.provider}
                  onValueChange={(value) => updateImageSettings({ provider: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(IMAGE_PROVIDERS).map(([key, name]) => (
                      <SelectItem key={key} value={key}>
                        {name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>模型</Label>
                <Input
                  placeholder="默认模型"
                  value={imageSettings.model}
                  onChange={(e) => updateImageSettings({ model: e.target.value })}
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>API Key</Label>
              <Input
                type="password"
                placeholder="输入 API Key"
                value={imageSettings.apiKey}
                onChange={(e) => updateImageSettings({ apiKey: e.target.value })}
              />
            </div>
            {imageSettings.provider === "custom" && (
              <div className="space-y-2">
                <Label>API 端点</Label>
                <Input
                  placeholder="https://api.example.com/v1/images/generations"
                  value={imageSettings.endpoint}
                  onChange={(e) => updateImageSettings({ endpoint: e.target.value })}
                />
              </div>
            )}
            {imageStatus && (
              <p className="text-sm text-muted-foreground">{imageStatus}</p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowImageDialog(false)}>
              取消
            </Button>
            <Button onClick={handleGenerateImage} disabled={generatingImage}>
              {generatingImage ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  生成中...
                </>
              ) : (
                "生成图片"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <VersionHistoryDialog
        open={showVersionDialog}
        onOpenChange={closeVersionDialog}
        versions={versions}
        onRestore={restoreVersion}
        loading={loadingVersions}
      />
    </div>
  );
}
