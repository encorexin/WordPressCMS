import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import type { ImageSettings } from "@/hooks/useImageGenerator";

export interface ImageGenerationDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  prompt: string;
  onPromptChange: (prompt: string) => void;
  settings: ImageSettings;
  onUpdateSettings: (settings: Partial<ImageSettings>) => void;
  generating: boolean;
  status: string;
  providers:
    | Record<string, string>
    | Array<{ value: string; label: string; [key: string]: unknown }>;
  onGenerate: () => void;
}

export function ImageGenerationDialog({
  open,
  onOpenChange,
  prompt,
  onPromptChange,
  settings,
  onUpdateSettings,
  generating,
  status,
  providers,
  onGenerate,
}: ImageGenerationDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
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
              value={prompt}
              onChange={(e) => onPromptChange(e.target.value)}
              className="min-h-[80px]"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>服务商</Label>
              <Select
                value={settings.provider}
                onValueChange={(value) => onUpdateSettings({ provider: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(providers).map(([key, name]) => (
                    <SelectItem key={key} value={key}>
                      {name as string}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>模型</Label>
              <Input
                placeholder="默认模型"
                value={settings.model}
                onChange={(e) => onUpdateSettings({ model: e.target.value })}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label>API Key</Label>
            <Input
              type="password"
              placeholder="输入 API Key"
              value={settings.apiKey}
              onChange={(e) => onUpdateSettings({ apiKey: e.target.value })}
            />
          </div>
          {settings.provider === "custom" && (
            <div className="space-y-2">
              <Label>API 端点</Label>
              <Input
                placeholder="https://api.example.com/v1/images/generations"
                value={settings.endpoint}
                onChange={(e) => onUpdateSettings({ endpoint: e.target.value })}
              />
            </div>
          )}
          {status && <p className="text-sm text-muted-foreground">{status}</p>}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            取消
          </Button>
          <Button onClick={onGenerate} disabled={generating}>
            {generating ? (
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
  );
}
