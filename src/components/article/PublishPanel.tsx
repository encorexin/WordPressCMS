import { Globe, Loader2, Wand2 } from "lucide-react";
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
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { ArticleFormData } from "@/hooks/useArticleForm";
import type { WordPressCategory, WordPressSite } from "@/types/types";

export interface PublishPanelProps {
  form: UseFormReturn<ArticleFormData>;
  sites: WordPressSite[];
  wpCategories: WordPressCategory[];
  selectedCategories: number[];
  postSlug: string;
  generatingSlug: boolean;
  onSiteChange: (siteId: string) => void;
  onCategoriesChange: (categories: number[]) => void;
  onSlugChange: (slug: string) => void;
  onGenerateSlug: () => void;
}

export function PublishPanel({
  form,
  sites,
  wpCategories,
  selectedCategories,
  postSlug,
  generatingSlug,
  onSiteChange,
  onCategoriesChange,
  onSlugChange,
  onGenerateSlug,
}: PublishPanelProps) {
  return (
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
                      onSiteChange(value);
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
                  onClick={onGenerateSlug}
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
                onChange={(e) => onSlugChange(e.target.value)}
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
                            onCategoriesChange([...selectedCategories, cat.id]);
                          } else {
                            onCategoriesChange(selectedCategories.filter((id) => id !== cat.id));
                          }
                        }}
                        className="rounded border-gray-300"
                      />
                      <span className="text-sm">{cat.name}</span>
                      {cat.count > 0 && (
                        <span className="text-xs text-muted-foreground">({cat.count})</span>
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
  );
}
