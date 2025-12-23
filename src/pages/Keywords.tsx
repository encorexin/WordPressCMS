import { useState, useEffect } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
} from "@/components/ui/card";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import {
    Plus,
    Loader2,
    Tag,
    Trash2,
    FolderOpen,
    Search,
} from "lucide-react";
import {
    getKeywordsByGroup,
    createKeyword,
    createKeywordsBatch,
    deleteKeyword,
    deleteKeywordsByGroup,
    type Keyword,
} from "@/db/keywordService";

export default function Keywords() {
    const { user } = useAuth();
    const [keywordsByGroup, setKeywordsByGroup] = useState<Record<string, Keyword[]>>({});
    const [loading, setLoading] = useState(true);
    const [showDialog, setShowDialog] = useState(false);
    const [saving, setSaving] = useState(false);
    const [searchQuery, setSearchQuery] = useState("");

    const [formData, setFormData] = useState({
        keywords: "",
        group_name: "",
    });

    useEffect(() => {
        if (user?.id) {
            loadKeywords();
        }
    }, [user]);

    const loadKeywords = async () => {
        if (!user?.id) return;

        try {
            setLoading(true);
            const data = await getKeywordsByGroup(user.id);
            setKeywordsByGroup(data);
        } catch (error) {
            console.error("加载关键词失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = () => {
        setFormData({ keywords: "", group_name: "" });
        setShowDialog(true);
    };

    const handleSave = async () => {
        if (!user?.id) return;

        if (!formData.keywords.trim()) {
            toast.error("请输入关键词");
            return;
        }

        try {
            setSaving(true);

            // 支持批量添加（按逗号、换行分隔）
            const keywords = formData.keywords
                .split(/[,，\n]/)
                .map(k => k.trim())
                .filter(k => k);

            if (keywords.length === 1) {
                await createKeyword(user.id, {
                    keyword: keywords[0],
                    group_name: formData.group_name || "未分组",
                });
                toast.success("关键词已添加");
            } else {
                const result = await createKeywordsBatch(
                    user.id,
                    keywords,
                    formData.group_name || "未分组"
                );
                toast.success(`添加了 ${result.created} 个关键词，跳过 ${result.skipped} 个重复`);
            }

            setShowDialog(false);
            await loadKeywords();
        } catch (error: any) {
            toast.error(error.message || "添加失败");
        } finally {
            setSaving(false);
        }
    };

    const handleDeleteKeyword = async (keyword: Keyword) => {
        try {
            await deleteKeyword(keyword.id);
            toast.success("已删除");
            await loadKeywords();
        } catch (error) {
            toast.error("删除失败");
        }
    };

    const handleDeleteGroup = async (groupName: string) => {
        if (!user?.id) return;
        if (!confirm(`确定要删除分组 "${groupName}" 下的所有关键词吗？`)) return;

        try {
            const count = await deleteKeywordsByGroup(user.id, groupName);
            toast.success(`已删除 ${count} 个关键词`);
            await loadKeywords();
        } catch (error) {
            toast.error("删除失败");
        }
    };

    // 过滤关键词
    const filteredGroups = Object.entries(keywordsByGroup).reduce(
        (acc, [group, keywords]) => {
            if (!searchQuery) {
                acc[group] = keywords;
            } else {
                const filtered = keywords.filter(kw =>
                    kw.keyword.toLowerCase().includes(searchQuery.toLowerCase())
                );
                if (filtered.length > 0) {
                    acc[group] = filtered;
                }
            }
            return acc;
        },
        {} as Record<string, Keyword[]>
    );

    const totalKeywords = Object.values(keywordsByGroup).flat().length;

    return (
        <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-4xl">
            {/* 头部 */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
                <div className="flex items-center space-x-3">
                    <div className="p-2 bg-gradient-to-br from-cyan-500 to-blue-500 rounded-lg">
                        <Tag className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <h1 className="text-2xl font-bold">关键词库</h1>
                        <p className="text-sm text-muted-foreground">
                            共 {totalKeywords} 个关键词
                        </p>
                    </div>
                </div>
                <div className="flex gap-2">
                    <div className="relative flex-1 sm:w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="搜索关键词..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-10"
                        />
                    </div>
                    <Button onClick={handleAdd} className="bg-gradient-to-r from-cyan-500 to-blue-500">
                        <Plus className="mr-2 h-4 w-4" />
                        添加
                    </Button>
                </div>
            </div>

            {/* 关键词列表 */}
            {loading ? (
                <div className="flex justify-center py-12">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </div>
            ) : Object.keys(filteredGroups).length === 0 ? (
                <Card className="border-0 shadow-lg">
                    <CardContent className="py-12 text-center">
                        <Tag className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                        <p className="text-muted-foreground">
                            {searchQuery ? "未找到匹配的关键词" : "暂无关键词，点击添加按钮创建"}
                        </p>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-4">
                    {Object.entries(filteredGroups).map(([group, keywords]) => (
                        <Card key={group} className="border-0 shadow-lg">
                            <CardHeader className="pb-2">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center space-x-2">
                                        <FolderOpen className="h-4 w-4 text-muted-foreground" />
                                        <CardTitle className="text-base">{group}</CardTitle>
                                        <Badge variant="secondary">{keywords.length}</Badge>
                                    </div>
                                    <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={() => handleDeleteGroup(group)}
                                        className="text-red-500 hover:text-red-600"
                                    >
                                        <Trash2 className="h-4 w-4 mr-1" />
                                        删除分组
                                    </Button>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <div className="flex flex-wrap gap-2">
                                    {keywords.map((keyword) => (
                                        <Badge
                                            key={keyword.id}
                                            variant="outline"
                                            className="px-3 py-1.5 text-sm cursor-pointer hover:bg-red-50 hover:border-red-200 group"
                                            onClick={() => handleDeleteKeyword(keyword)}
                                        >
                                            {keyword.keyword}
                                            {keyword.use_count > 0 && (
                                                <span className="ml-1 text-xs text-muted-foreground">
                                                    ({keyword.use_count})
                                                </span>
                                            )}
                                            <Trash2 className="ml-1.5 h-3 w-3 opacity-0 group-hover:opacity-100 text-red-500" />
                                        </Badge>
                                    ))}
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* 添加对话框 */}
            <Dialog open={showDialog} onOpenChange={setShowDialog}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>添加关键词</DialogTitle>
                        <DialogDescription>
                            支持批量添加，用逗号或换行分隔多个关键词
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Label>关键词</Label>
                            <Input
                                placeholder="输入关键词，多个用逗号分隔"
                                value={formData.keywords}
                                onChange={(e) => setFormData({ ...formData, keywords: e.target.value })}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>分组（可选）</Label>
                            <Input
                                placeholder="默认：未分组"
                                value={formData.group_name}
                                onChange={(e) => setFormData({ ...formData, group_name: e.target.value })}
                            />
                        </div>
                    </div>

                    <DialogFooter>
                        <Button variant="outline" onClick={() => setShowDialog(false)}>
                            取消
                        </Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    添加中...
                                </>
                            ) : (
                                "添加"
                            )}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
