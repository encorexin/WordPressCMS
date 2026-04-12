import { Loader2 } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import {
  AIGenerationPanel,
  ArticleContentCard,
  EditorToolbar,
  ImageGenerationDialog,
  PublishPanel,
} from "@/components/article";
import { VersionHistoryDialog } from "@/components/common/VersionHistoryDialog";
import { useAuth } from "@/context/LocalAuthProvider";
import {
  getAllAISettings,
  getEffectiveAISettings,
  getSlugSettings,
  type AISettings,
  type ArticleVersion,
} from "@/db/api";
import { downloadSingleArticle } from "@/db/dataExport";
import { useHotkeys } from "@/hooks/use-hotkeys";
import {
  useArticleAssets,
  useArticleForm,
  useArticleGenerator,
  useArticlePublisher,
  useImageGenerator,
  useVersionHistory,
} from "@/hooks/useArticle";
import { logger } from "@/utils/logger";

export default function ArticleEditor() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [currentContent, setCurrentContent] = useState("");
  const [useRichEditor, setUseRichEditor] = useState(false);
  const [aiSettingsList, setAiSettingsList] = useState<AISettings[]>([]);
  const [selectedAiSettingsId, setSelectedAiSettingsId] = useState<string>("");

  const { form, loading, sites, wpPostId, setWpPostId, isNew, articleId, handleSave, saveArticle } =
    useArticleForm();

  const {
    templates,
    topics,
    selectedTemplate,
    selectedTopic,
    setSelectedTemplate,
    selectTopic,
    clearSelectedTopic,
    loadTopics,
  } = useArticleAssets();

  const {
    generating,
    progress: generateProgress,
    generate,
    stop: stopGenerate,
  } = useArticleGenerator({
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
    userId: user?.id,
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
    openDialog,
    generate: generateImageAction,
    insertImage,
    updateSettings: updateImageSettings,
    providers: IMAGE_PROVIDERS,
  } = useImageGenerator();

  const {
    showDialog: showVersionDialog,
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
        const defaultSettings = settings.find((s) => s.is_default);
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
    const keywords = form.getValues("keywords") || "";
    const template = form.getValues("template") || "";
    generate(
      keywords,
      template,
      selectedTemplate?.system_prompt,
      selectedAiSettingsId || undefined
    );
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
      toast.success(
        `文章已下载为 ${format === "markdown" ? "Markdown" : format === "txt" ? "文本" : "HTML"} 格式`
      );
    },
    [form]
  );

  const handleSiteChange = useCallback(
    (siteId: string) => {
      const site = sites.find((s) => s.id === siteId);
      if (site) loadCategories(site);
      setSelectedCategories([]);
    },
    [sites, loadCategories, setSelectedCategories]
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
        <EditorToolbar
          isNew={isNew}
          publishing={publishing}
          onNavigateBack={() => navigate("/articles")}
          onSave={() => form.handleSubmit(handleSave)()}
          onPublish={handlePublish}
          onOpenVersionHistory={openVersionDialog}
          onDownload={handleDownload}
        />

        <div className="grid gap-4 sm:gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2 space-y-4 sm:space-y-6 min-w-0">
            <ArticleContentCard
              form={form}
              currentContent={currentContent}
              useRichEditor={useRichEditor}
              onContentChange={setCurrentContent}
              onEditorModeChange={setUseRichEditor}
            />
          </div>

          <div className="space-y-4 sm:space-y-6">
            <AIGenerationPanel
              form={form}
              topics={topics}
              selectedTopic={selectedTopic}
              templates={templates}
              selectedTemplate={selectedTemplate}
              aiSettingsList={aiSettingsList}
              selectedAiSettingsId={selectedAiSettingsId}
              generating={generating}
              generatingImage={generatingImage}
              generateProgress={generateProgress}
              onSelectTopic={handleSelectTopic}
              onSelectTemplate={setSelectedTemplate}
              onSelectAiSettings={setSelectedAiSettingsId}
              onGenerate={handleGenerate}
              onStopGenerate={stopGenerate}
              onOpenImageDialog={handleOpenImageDialog}
            />

            <PublishPanel
              form={form}
              sites={sites}
              wpCategories={wpCategories}
              selectedCategories={selectedCategories}
              postSlug={postSlug}
              generatingSlug={generatingSlug}
              onSiteChange={handleSiteChange}
              onCategoriesChange={setSelectedCategories}
              onSlugChange={setPostSlug}
              onGenerateSlug={handleGenerateSlug}
            />
          </div>
        </div>
      </div>

      <ImageGenerationDialog
        open={showImageDialog}
        onOpenChange={setShowImageDialog}
        prompt={imagePrompt}
        onPromptChange={setImagePrompt}
        settings={imageSettings}
        onUpdateSettings={updateImageSettings}
        generating={generatingImage}
        status={imageStatus}
        providers={IMAGE_PROVIDERS}
        onGenerate={handleGenerateImage}
      />

      <VersionHistoryDialog
        articleId={articleId ?? null}
        open={showVersionDialog}
        onOpenChange={closeVersionDialog}
        onRestore={restoreVersion}
        currentTitle={form.getValues("title") || ""}
        currentContent={form.getValues("content") || ""}
      />
    </div>
  );
}
