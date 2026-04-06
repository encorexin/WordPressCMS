import { FileText, PenTool } from "lucide-react";
import type { UseFormReturn } from "react-hook-form";
import { Streamdown } from "streamdown";
import { RichTextEditor } from "@/components/common/RichTextEditor";
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
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import type { ArticleFormData } from "@/hooks/useArticleForm";

export interface ArticleContentCardProps {
  form: UseFormReturn<ArticleFormData>;
  currentContent: string;
  useRichEditor: boolean;
  onContentChange: (content: string) => void;
  onEditorModeChange: (useRich: boolean) => void;
}

export function ArticleContentCard({
  form,
  currentContent,
  useRichEditor,
  onContentChange,
  onEditorModeChange,
}: ArticleContentCardProps) {
  return (
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
                        onCheckedChange={onEditorModeChange}
                      />
                      <Label
                        htmlFor="editor-mode"
                        className="text-sm cursor-pointer flex items-center gap-1"
                      >
                        {useRichEditor ? (
                          <>
                            <PenTool className="h-3 w-3" /> 富文本
                          </>
                        ) : (
                          <>
                            <FileText className="h-3 w-3" /> Markdown
                          </>
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
                          onContentChange(content);
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
                              onContentChange(e.target.value);
                            }}
                          />
                        </TabsContent>
                        <TabsContent value="preview">
                          <div className="min-h-[300px] sm:min-h-[400px] p-3 sm:p-4 border rounded-md prose prose-sm max-w-none dark:prose-invert overflow-x-auto overflow-y-auto break-words [&_pre]:overflow-x-auto [&_pre]:max-w-full [&_code]:break-all [&_pre_code]:break-normal [&_table]:block [&_table]:overflow-x-auto">
                            <Streamdown>{currentContent || field.value || "暂无内容"}</Streamdown>
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
  );
}
