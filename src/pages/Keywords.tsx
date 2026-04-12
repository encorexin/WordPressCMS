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
import { Checkbox } from "@/components/ui/checkbox";
import { toast } from "sonner";
import { logger } from "@/utils/logger";
import {
    Plus,
    Loader2,
    Tag,
    Trash2,
    FolderOpen,
    Search,
    Globe,
    Sparkles,
} from "lucide-react";
import {
    getKeywordsByGroup,
    createKeyword,
    createKeywordsBatch,
    deleteKeyword,
    deleteKeywordsByGroup,
    type Keyword,
} from "@/db/api";
import { fetchKeywordsFromAI, fetchKeywordsFromTrends } from "@/utils/keywordFetcher";

export default function Keywords() {
    const { user } = useAuth();
    const [keywordsByGroup, setKeywordsByGroup] = useState<Record<string, Keyword[]>>({});
    const [loading, setLoading] = useState(true);
    const [showDialog, setShowDialog] = useState(false);
    const [showFetchDialog, setShowFetchDialog] = useState(false);
    const [saving, setSaving] = useState(false);
    const [fetching, setFetching] = useState(false);
    const [searchQuery, setSearchQuery] = useState("");

    const [formData, setFormData] = useState({
        keywords: "",
        group_name: "",
    });

    const [fetchFormData, setFetchFormData] = useState({
        topic: "",
        source: "ai" as "ai" | "trends",
        count: 20,
        group_name: "",
    });

    const [fetchedKeywords, setFetchedKeywords] = useState<string[]>([]);
    const [selectedKeywords, setSelectedKeywords] = useState<Set<string>>(new Set());

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
            logger.error("加载关键词失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = () => {
        setFormData({ keywords: "", group_name: "" });
        setShowDialog(true);
    };

    const handleFetch = () => {
        setFetchFormData({
            topic: "",
            source: "ai",
            count: 20,
            group_name: "",
        });
        setFetchedKeywords([]);
        setSelectedKeywords(new Set());
        setShowFetchDialog(true);
    };

    const handleSave = async () => {
        if (!user?.id) return;

        if (!formData.keywords.trim()) {
            toast.error("请输入关键词");
            return;
        }

        try {
            setSaving(true);

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
        } catch (error: unknown) {
            toast.error(error instanceof Error ? error.message : "添加失败");
        } finally {
            setSaving(false);
        }
    };

    const handleFetchKeywords = async () => {
        if (!user?.id) return;

        if (!fetchFormData.topic.trim()) {
            toast.error("请输入主题");
            return;
        }

        try {
            setFetching(true);
            setFetchedKeywords([]);
            setSelectedKeywords(new Set());

            let result: Awaited<ReturnType<typeof fetchKeywordsFromAI>>;
            if (fetchFormData.source === "ai") {
                result = await fetchKeywordsFromAI(
                    user.id,
                    fetchFormData.topic,
                    fetchFormData.count
                );
            } else {
                result = await fetchKeywordsFromTrends(fetchFormData.topic);
            }

            if (result.success && result.keywords) {
                setFetchedKeywords(result.keywords);
                setSelectedKeywords(new Set(result.keywords));
                toast.success(`获取到 ${result.keywords.length} 个关键词`);
            } else {
                toast.error(result.error || "获取失败");
            }
        } catch (error) {
            toast.error("获取关键词失败");
        } finally {
            setFetching(false);
        }
    };

    const handleToggleKeyword = (keyword: string) => {
        const newSelected = new Set(selectedKeywords);
        if (newSelected.has(keyword)) {
            newSelected.delete(keyword);
        } else {
            newSelected.add(keyword);
        }
        setSelectedKeywords(newSelected);
    };

    const handleSelectAll = () => {
        if (selectedKeywords.size === fetchedKeywords.length) {
            setSelectedKeywords(new Set());
        } else {
            setSelectedKeywords(new Set(fetchedKeywords));
        }
    };

    const handleSaveFetched = async () => {
        if (!user?.id) return;

        if (selectedKeywords.size === 0) {
            toast.error("请选择要添加的关键词");
            return;
        }

        try {
            setSaving(true);
            const keywords = Array.from(selectedKeywords);
            const result = await createKeywordsBatch(
                user.id,
                keywords,
                fetchFormData.group_name || fetchFormData.topic || "未分组"
            );
            toast.success(`添加了 ${result.created} 个关键词，跳过 ${result.skipped} 个重复`);
            setShowFetchDialog(false);
            await loadKeywords();
        } catch (error) {
            toast.error("添加失败");
        } finally {
            setSaving(false);
        }
    };

    const handleDeleteKeyword = async (keyword: Keyword) => {
        if (!user?.id) return;
        try {
            await deleteKeyword(user.id, keyword.id);
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
                    <Button
                        variant="outline"
                        onClick={handleFetch}
                        className="border-cyan-500 text-cyan-600 hover:bg-cyan-50"
                    >
                        <Globe className="mr-2 h-4 w-4" />
                        网络获取
                    </Button>
                    <Button onClick={handleAdd} className="bg-gradient-to-r from-cyan-500 to-blue-500">
                        <Plus className="mr-2 h-4 w-4" />
                        添加
                    </Button>
                </div>
            </div>

            {loading ? (
                <div className="flex justify-center py-12">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </div>
            ) : Object.keys(filteredGroups).length === 0 ? (
                <Card className="border-0 shadow-lg">
                    <CardContent className="py-12 text-center">
                        <Tag className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                        <p className="text-muted-foreground mb-4">
                            {searchQuery ? "未找到匹配的关键词" : "暂无关键词，点击添加或从网络获取"}
                        </p>
                        <div className="flex justify-center gap-2">
                            <Button variant="outline" onClick={handleFetch}>
                                <Globe className="mr-2 h-4 w-4" />
                                网络获取
                            </Button>
                            <Button onClick={handleAdd}>
                                <Plus className="mr-2 h-4 w-4" />
                                手动添加
                            </Button>
                        </div>
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

            <Dialog open={showFetchDialog} onOpenChange={setShowFetchDialog}>
                <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle className="flex items-center gap-2">
                            <Globe className="h-5 w-5 text-cyan-500" />
                            从网络获取关键词
                        </DialogTitle>
                        <DialogDescription>
                            输入主题，AI 将为您生成相关关键词
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label>获取方式</Label>
                                <div className="flex gap-2">
                                    <Button
                                        variant={fetchFormData.source === "ai" ? "default" : "outline"}
                                        size="sm"
                                        onClick={() => setFetchFormData({ ...fetchFormData, source: "ai" })}
                                        className="flex-1"
                                    >
                                        <Sparkles className="mr-1 h-4 w-4" />
                                        AI 生成
                                    </Button>
                                    <Button
                                        variant={fetchFormData.source === "trends" ? "default" : "outline"}
                                        size="sm"
                                        onClick={() => setFetchFormData({ ...fetchFormData, source: "trends" })}
                                        className="flex-1"
                                    >
                                        <Globe className="mr-1 h-4 w-4" />
                                        搜索建议
                                    </Button>
                                </div>
                            </div>
                            <div className="space-y-2">
                                <Label>分组名称</Label>
                                <Input
                                    placeholder="默认使用主题名称"
                                    value={fetchFormData.group_name}
                                    onChange={(e) => setFetchFormData({ ...fetchFormData, group_name: e.target.value })}
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label>
                                {fetchFormData.source === "ai" ? "主题 / 种子关键词" : "搜索词"}
                            </Label>
                            <div className="flex gap-2">
                                <Input
                                    placeholder={fetchFormData.source === "ai" ? "例如：人工智能、健康饮食" : "输入搜索词"}
                                    value={fetchFormData.topic}
                                    onChange={(e) => setFetchFormData({ ...fetchFormData, topic: e.target.value })}
                                    onKeyDown={(e) => e.key === "Enter" && handleFetchKeywords()}
                                />
                                {fetchFormData.source === "ai" && (
                                    <Input
                                        type="number"
                                        placeholder="数量"
                                        value={fetchFormData.count}
                                        onChange={(e) => setFetchFormData({ ...fetchFormData, count: parseInt(e.target.value) || 20 })}
                                        className="w-20"
                                        min={5}
                                        max={50}
                                    />
                                )}
                            </div>
                            <p className="text-xs text-muted-foreground">
                                {fetchFormData.source === "ai"
                                    ? "AI 将根据主题生成相关关键词和长尾词"
                                    : "从搜索引擎获取相关搜索建议"}
                            </p>
                        </div>

                        <Button
                            onClick={handleFetchKeywords}
                            disabled={fetching || !fetchFormData.topic.trim()}
                            className="w-full bg-gradient-to-r from-cyan-500 to-blue-500"
                        >
                            {fetching ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    获取中...
                                </>
                            ) : (
                                <>
                                    <Globe className="mr-2 h-4 w-4" />
                                    获取关键词
                                </>
                            )}
                        </Button>

                        {fetchedKeywords.length > 0 && (
                            <div className="space-y-3">
                                <div className="flex items-center justify-between">
                                    <Label>
                                        获取结果 ({selectedKeywords.size}/{fetchedKeywords.length} 已选)
                                    </Label>
                                    <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={handleSelectAll}
                                    >
                                        {selectedKeywords.size === fetchedKeywords.length ? "取消全选" : "全选"}
                                    </Button>
                                </div>
                                <div className="flex flex-wrap gap-2 p-3 bg-muted/50 rounded-lg max-h-60 overflow-y-auto">
                                    {fetchedKeywords.map((keyword) => (
                                        <div
                                            key={keyword}
                                            className="flex items-center gap-1.5 px-2 py-1 bg-background rounded border cursor-pointer hover:bg-accent"
                                            onClick={() => handleToggleKeyword(keyword)}
                                        >
                                            <Checkbox
                                                checked={selectedKeywords.has(keyword)}
                                                onCheckedChange={() => handleToggleKeyword(keyword)}
                                                className="h-3 w-3"
                                            />
                                            <span className="text-sm">{keyword}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>

                    <DialogFooter>
                        <Button variant="outline" onClick={() => setShowFetchDialog(false)}>
                            取消
                        </Button>
                        <Button
                            onClick={handleSaveFetched}
                            disabled={saving || selectedKeywords.size === 0}
                            className="bg-gradient-to-r from-cyan-500 to-blue-500"
                        >
                            {saving ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    添加中...
                                </>
                            ) : (
                                `添加 ${selectedKeywords.size} 个关键词`
                            )}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
