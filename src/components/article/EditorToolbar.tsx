import { ArrowLeft, Download, History, Loader2, Save, Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export interface EditorToolbarProps {
  isNew: boolean;
  publishing: boolean;
  onNavigateBack: () => void;
  onSave: () => void;
  onPublish: () => void;
  onOpenVersionHistory: () => void;
  onDownload: (format: "markdown" | "txt" | "html") => void;
}

export function EditorToolbar({
  isNew,
  publishing,
  onNavigateBack,
  onSave,
  onPublish,
  onOpenVersionHistory,
  onDownload,
}: EditorToolbarProps) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4">
      <div className="flex items-center space-x-2 sm:space-x-4">
        <Button variant="ghost" size="sm" onClick={onNavigateBack}>
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
            onClick={onOpenVersionHistory}
            className="hidden sm:flex border-2 hover:bg-blue-50 dark:hover:bg-blue-950/50"
          >
            <History className="mr-2 h-4 w-4" />
            历史版本
          </Button>
        )}
        <Button
          variant="outline"
          onClick={onSave}
          className="flex-1 sm:flex-none border-2 hover:bg-blue-50 dark:hover:bg-blue-950/50"
        >
          <Save className="mr-2 h-4 w-4" />
          保存
        </Button>
        <Button
          onClick={onPublish}
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
              <DropdownMenuItem onClick={onOpenVersionHistory}>
                <History className="mr-2 h-4 w-4" />
                历史版本
              </DropdownMenuItem>
            )}
            <DropdownMenuItem onClick={() => onDownload("markdown")}>
              下载 Markdown (.md)
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => onDownload("txt")}>下载文本</DropdownMenuItem>
            <DropdownMenuItem onClick={() => onDownload("html")}>下载网页</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>
  );
}
