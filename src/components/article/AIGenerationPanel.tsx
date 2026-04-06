import { ImagePlus, Lightbulb, Loader2, Settings, Sparkles } from "lucide-react";
import type { UseFormReturn } from "react-hook-form";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { AISettings, ArticleTemplate, Topic } from "@/db/database";
import type { ArticleFormData } from "@/hooks/useArticleForm";

export interface AIGenerationPanelProps {
  form: UseFormReturn<ArticleFormData>;
  topics: Topic[];
  selectedTopic: Topic | null;
  templates: ArticleTemplate[];
  selectedTemplate: ArticleTemplate | null;
  aiSettingsList: AISettings[];
  selectedAiSettingsId: string;
  generating: boolean;
  generatingImage: boolean;
  generateProgress: number;
  onSelectTopic: (topic: {
    id: string;
    title: string;
    keywords?: string;
    description?: string;
  }) => void;
  onSelectTemplate: (template: ArticleTemplate | null) => void;
  onSelectAiSettings: (id: string) => void;
  onGenerate: () => void;
  onStopGenerate: () => void;
  onOpenImageDialog: () => void;
}

export function AIGenerationPanel({
  form,
  topics,
  selectedTopic,
  templates,
  selectedTemplate,
  aiSettingsList,
  selectedAiSettingsId,
  generating,
  generatingImage,
  generateProgress,
  onSelectTopic,
  onSelectTemplate,
  onSelectAiSettings,
  onGenerate,
  onStopGenerate,
  onOpenImageDialog,
}: AIGenerationPanelProps) {
  return (
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
                      onSelectTopic(topic);
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
                <Select value={selectedAiSettingsId} onValueChange={onSelectAiSettings}>
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
                  {aiSettingsList.find((s) => s.id === selectedAiSettingsId)?.model || "选择配置"}
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
                      onSelectTemplate(template || null);
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
                onClick={generating ? onStopGenerate : onGenerate}
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
              onClick={onOpenImageDialog}
              disabled={generating || generatingImage}
            >
              <ImagePlus className="mr-2 h-4 w-4" />
              生成配图
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
