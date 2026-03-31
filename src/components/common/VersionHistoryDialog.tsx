import { format } from "date-fns";
import { zhCN } from "date-fns/locale";
import {
  ChevronDown,
  ChevronUp,
  Clock,
  FileText,
  History,
  RotateCcw,
  Trash2,
  X,
} from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { useAuth } from "@/context/LocalAuthProvider";
import {
  type ArticleVersion,
  deleteArticleVersion,
  getArticleVersions,
} from "@/db/versionService";

interface VersionHistoryDialogProps {
  articleId: string | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onRestore: (version: ArticleVersion) => void;
  currentTitle: string;
  currentContent: string;
}

export function VersionHistoryDialog({
  articleId,
  open,
  onOpenChange,
  onRestore,
  currentTitle,
  currentContent,
}: VersionHistoryDialogProps) {
  const { user } = useAuth();
  const [versions, setVersions] = useState<ArticleVersion[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedVersion, setSelectedVersion] = useState<ArticleVersion | null>(null);
  const [expandedVersions, setExpandedVersions] = useState<Set<string>>(new Set());

  const loadVersions = useCallback(async () => {
    if (!articleId || !user?.id) return;

    setLoading(true);
    try {
      const data = await getArticleVersions(user.id, articleId);
      setVersions(data);
    } catch (error) {
      console.error("加载版本历史失败:", error);
      toast.error("加载版本历史失败");
    } finally {
      setLoading(false);
    }
  }, [articleId, user?.id]);

  useEffect(() => {
    if (open && articleId) {
      loadVersions();
    }
  }, [open, articleId, loadVersions]);

  const handleDelete = async (versionId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!user?.id) {
      toast.error("用户未登录");
      return;
    }
    if (!confirm("确定要删除这个版本吗？")) return;

    try {
      await deleteArticleVersion(user.id, versionId);
      await loadVersions();
      toast.success("版本已删除");
    } catch (error) {
      toast.error("删除失败");
    }
  };

  const handleRestore = (version: ArticleVersion) => {
    if (!confirm(`确定要恢复到版本 ${version.version_number} 吗？当前内容将被覆盖。`)) {
      return;
    }
    onRestore(version);
    onOpenChange(false);
    toast.success(`已恢复到版本 ${version.version_number}`);
  };

  const toggleExpand = (versionId: string) => {
    setExpandedVersions((prev) => {
      const next = new Set(prev);
      if (next.has(versionId)) {
        next.delete(versionId);
      } else {
        next.add(versionId);
      }
      return next;
    });
  };

  const getChangesDescription = (version: ArticleVersion, index: number) => {
    if (index === 0) {
      // 第一个版本，与当前内容比较
      const changes: string[] = [];
      if (version.title !== currentTitle) changes.push("标题");
      if (version.content !== currentContent) changes.push("内容");
      if (changes.length === 0) return "与当前一致";
      return `与当前不同: ${changes.join(", ")}`;
    }
    return `版本 ${version.version_number}`;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[80vh] flex flex-col">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            版本历史
          </DialogTitle>
        </DialogHeader>

        {loading ? (
          <div className="py-8 text-center text-muted-foreground">
            <div className="animate-spin h-6 w-6 border-2 border-primary border-t-transparent rounded-full mx-auto mb-2" />
            加载中...
          </div>
        ) : versions.length === 0 ? (
          <div className="py-8 text-center text-muted-foreground">
            <Clock className="h-12 w-12 mx-auto mb-3 opacity-30" />
            <p>暂无历史版本</p>
            <p className="text-sm mt-1">保存文章时会自动创建版本</p>
          </div>
        ) : (
          <>
            <div className="text-sm text-muted-foreground mb-2">
              共 {versions.length} 个历史版本（最多保留 50 个）
            </div>
            <ScrollArea className="flex-1 -mx-6 px-6">
              <div className="space-y-2">
                {versions.map((version, index) => {
                  const isExpanded = expandedVersions.has(version.id);
                  const isSelected = selectedVersion?.id === version.id;

                  return (
                    <div
                      key={version.id}
                      className={`border rounded-lg overflow-hidden transition-colors ${
                        isSelected
                          ? "border-primary bg-primary/5"
                          : "border-border hover:border-primary/50"
                      }`}
                    >
                      <button
                        onClick={() => toggleExpand(version.id)}
                        className="w-full flex items-center justify-between p-3 text-left"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-sm font-medium">
                            {version.version_number}
                          </div>
                          <div>
                            <div className="font-medium text-sm">
                              {format(new Date(version.created_at), "yyyy-MM-dd HH:mm", {
                                locale: zhCN,
                              })}
                            </div>
                            <div className="text-xs text-muted-foreground">
                              {getChangesDescription(version, index)}
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center gap-1">
                          {isExpanded ? (
                            <ChevronUp className="h-4 w-4 text-muted-foreground" />
                          ) : (
                            <ChevronDown className="h-4 w-4 text-muted-foreground" />
                          )}
                        </div>
                      </button>

                      {isExpanded && (
                        <div className="px-3 pb-3 border-t bg-muted/30">
                          <div className="pt-3 space-y-3">
                            <div className="space-y-2">
                              <div className="flex items-center gap-2 text-sm">
                                <FileText className="h-4 w-4 text-muted-foreground" />
                                <span className="font-medium">标题</span>
                              </div>
                              <p className="text-sm pl-6 text-muted-foreground">
                                {version.title}
                              </p>
                            </div>

                            {version.keywords && (
                              <div className="space-y-2">
                                <div className="flex items-center gap-2 text-sm">
                                  <span className="font-medium">关键词</span>
                                </div>
                                <p className="text-sm pl-6 text-muted-foreground">
                                  {version.keywords}
                                </p>
                              </div>
                            )}

                            {version.content && (
                              <div className="space-y-2">
                                <div className="flex items-center gap-2 text-sm">
                                  <span className="font-medium">内容预览</span>
                                </div>
                                <div className="text-sm pl-6 text-muted-foreground max-h-32 overflow-y-auto bg-muted/50 rounded p-2">
                                  {version.content.slice(0, 200)}
                                  {version.content.length > 200 && "..."}
                                </div>
                              </div>
                            )}

                            <div className="flex gap-2 pt-2">
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleRestore(version)}
                                className="flex-1"
                              >
                                <RotateCcw className="h-4 w-4 mr-1" />
                                恢复此版本
                              </Button>
                              <Button
                                size="sm"
                                variant="ghost"
                                onClick={(e) => handleDelete(version.id, e)}
                                className="text-destructive hover:text-destructive"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </ScrollArea>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
