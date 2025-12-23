import { useState, useEffect } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
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
    Lightbulb,
    Trash2,
    Sparkles,
    Check,
    FolderOpen,
    Search,
} from "lucide-react";
import {
    getTopicsByCategory,
    createTopic,
    createTopicsBatch,
    deleteTopic,
    deleteUsedTopics,
    markTopicAsUsed,
    type Topic,
} from "@/db/topicService";
import { getEffectiveAISettings } from "@/db/aiSettings";
import { sendChatStream } from "@/utils/aiChat";

export default function Topics() {
    const { user } = useAuth();
    const [topicsByCategory, setTopicsByCategory] = useState<Record<string, Topic[]>>({});
    const [loading, setLoading] = useState(true);
    const [generating, setGenerating] = useState(false);
    const [showAddDialog, setShowAddDialog] = useState(false);
    const [showGenerateDialog, setShowGenerateDialog] = useState(false);
    const [saving, setSaving] = useState(false);
    const [searchQuery, setSearchQuery] = useState("");

    const [formData, setFormData] = useState({
        title: "",
        description: "",
        keywords: "",
        category: "",
    });

    const [generateData, setGenerateData] = useState({
        topic: "",
        count: 10,
        category: "",
    });

    const [generatedTopics, setGeneratedTopics] = useState<string>("");

    useEffect(() => {
        if (user?.id) {
            loadTopics();
        }
    }, [user]);

    const loadTopics = async () => {
        if (!user?.id) return;

        try {
            setLoading(true);
            const data = await getTopicsByCategory(user.id);
            setTopicsByCategory(data);
        } catch (error) {
            console.error("加载主题失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = () => {
        setFormData({ title: "", description: "", keywords: "", category: "" });
        setShowAddDialog(true);
    };

    const handleSave = async () => {
        if (!user?.id) return;

        if (!formData.title.trim()) {
            toast.error("请输入主题标题");
            return;
        }

        try {
            setSaving(true);
            await createTopic(user.id, formData);
            toast.success("主题已添加");
            setShowAddDialog(false);
            await loadTopics();
        } catch (error) {
            toast.error("添加失败");
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async (topic: Topic) => {
        try {
            await deleteTopic(topic.id);
            toast.success("已删除");
            await loadTopics();
        } catch (error) {
            toast.error("删除失败");
        }
    };

    const handleMarkUsed = async (topic: Topic) => {
        try {
            await markTopicAsUsed(topic.id);
            toast.success("已标记为已使用");
            await loadTopics();
        } catch (error) {
            toast.error("操作失败");
        }
    };

    const handleClearUsed = async () => {
        if (!user?.id) return;
        if (!confirm("确定要清除所有已使用的主题吗？")) return;

        try {
            const count = await deleteUsedTopics(user.id);
            toast.success(`已清除 ${count} 个主题`);
            await loadTopics();
        } catch (error) {
            toast.error("清除失败");
        }
    };

    const handleGenerate = async () => {
        if (!user?.id) return;

        if (!generateData.topic.trim()) {
            toast.error("请输入主题方向");
            return;
        }

        try {
            setGenerating(true);
            setGeneratedTopics("");

            const aiSettings = await getEffectiveAISettings(user.id);

            if (!aiSettings.api_key) {
                toast.error("请先在 AI 设置中配置 API Key");
                setGenerating(false);
                return;
            }

            const prompt = `请为我生成 ${generateData.count} 个关于"${generateData.topic}"的文章主题创意。

对于每个主题，请按以下格式输出：
---
标题: [文章标题]
描述: [2-3句话的大纲描述，说明文章将包含什么内容]
关键词: [3-5个相关关键词，用逗号分隔]
---

要求：
1. 主题要具有实用价值和吸引力
2. 标题要吸引眼球，适合 SEO
3. 每个主题要有独特的角度
4. 描述要清晰说明文章内容方向

请直接输出，不要添加其他说明。`;

            await sendChatStream({
                endpoint: aiSettings.api_endpoint,
                apiKey: aiSettings.api_key,
                model: aiSettings.model,
                messages: [
                    { role: "user", content: prompt }
                ],
                onUpdate: (content: string) => {
                    setGeneratedTopics(content);
                },
                onComplete: () => {
                    toast.success("主题生成完成");
                    setGenerating(false);
                },
                onError: (error: Error) => {
                    toast.error("生成失败: " + error.message);
                    setGenerating(false);
                },
            });
        } catch (error) {
            toast.error("生成失败");
            setGenerating(false);
        }
    };

    const handleSaveGenerated = async () => {
        if (!user?.id || !generatedTopics) return;

        try {
            setSaving(true);

            // 解析生成的主题
            const topicBlocks = generatedTopics.split('---').filter(block => block.trim());
            const topics: { title: string; description: string; keywords: string; category: string }[] = [];

            for (const block of topicBlocks) {
                const titleMatch = block.match(/标题[:：]\s*(.+)/);
                const descMatch = block.match(/描述[:：]\s*(.+)/);
                const keywordsMatch = block.match(/关键词[:：]\s*(.+)/);

                if (titleMatch) {
                    topics.push({
                        title: titleMatch[1].trim(),
                        description: descMatch ? descMatch[1].trim() : "",
                        keywords: keywordsMatch ? keywordsMatch[1].trim() : "",
                        category: generateData.category || "AI 生成",
                    });
                }
            }

            if (topics.length === 0) {
                toast.error("未能解析出有效主题");
                return;
            }

            const count = await createTopicsBatch(user.id, topics);
            toast.success(`已保存 ${count} 个主题`);
            setShowGenerateDialog(false);
            setGeneratedTopics("");
            await loadTopics();
        } catch (error) {
            toast.error("保存失败");
        } finally {
            setSaving(false);
        }
    };

    // 过滤主题
    const filteredGroups = Object.entries(topicsByCategory).reduce(
        (acc, [category, topics]) => {
            if (!searchQuery) {
                acc[category] = topics;
            } else {
                const filtered = topics.filter(topic =>
                    topic.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                    topic.description.toLowerCase().includes(searchQuery.toLowerCase())
                );
                if (filtered.length > 0) {
                    acc[category] = filtered;
                }
            }
            return acc;
        },
        {} as Record<string, Topic[]>
    );

    const totalTopics = Object.values(topicsByCategory).flat().length;
    const unusedTopics = Object.values(topicsByCategory).flat().filter(t => !t.used).length;

    return (
        <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-5xl">
            {/* 头部 */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
                <div className="flex items-center space-x-3">
                    <div className="p-2 bg-gradient-to-br from-amber-500 to-orange-500 rounded-lg">
                        <Lightbulb className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <h1 className="text-2xl font-bold">主题库</h1>
                        <p className="text-sm text-muted-foreground">
                            {unusedTopics} 个待使用 / 共 {totalTopics} 个主题
                        </p>
                    </div>
                </div>
                <div className="flex gap-2 flex-wrap">
                    <div className="relative flex-1 sm:w-48">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="搜索主题..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-10"
                        />
                    </div>
                    <Button variant="outline" onClick={handleClearUsed}>
                        <Trash2 className="mr-2 h-4 w-4" />
                        清除已用
                    </Button>
                    <Button variant="outline" onClick={handleAdd}>
                        <Plus className="mr-2 h-4 w-4" />
                        手动添加
                    </Button>
                    <Button
                        onClick={() => setShowGenerateDialog(true)}
                        className="bg-gradient-to-r from-amber-500 to-orange-500"
                    >
                        <Sparkles className="mr-2 h-4 w-4" />
                        AI 生成
                    </Button>
                </div>
            </div>

            {/* 主题列表 */}
            {loading ? (
                <div className="flex justify-center py-12">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </div>
            ) : Object.keys(filteredGroups).length === 0 ? (
                <Card className="border-0 shadow-lg">
                    <CardContent className="py-12 text-center">
                        <Lightbulb className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                        <p className="text-muted-foreground">
                            {searchQuery ? "未找到匹配的主题" : "暂无主题，点击 AI 生成创建"}
                        </p>
                    </CardContent>
                </Card>
            ) : (
                <div className="space-y-6">
                    {Object.entries(filteredGroups).map(([category, topics]) => (
                        <Card key={category} className="border-0 shadow-lg">
                            <CardHeader className="pb-3">
                                <div className="flex items-center space-x-2">
                                    <FolderOpen className="h-4 w-4 text-muted-foreground" />
                                    <CardTitle className="text-base">{category}</CardTitle>
                                    <Badge variant="secondary">{topics.length}</Badge>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-3">
                                    {topics.map((topic) => (
                                        <div
                                            key={topic.id}
                                            className={`p-4 rounded-lg border transition-colors ${topic.used
                                                ? "bg-gray-50 dark:bg-gray-800/50 opacity-60"
                                                : "bg-white dark:bg-gray-900 hover:border-amber-200"
                                                }`}
                                        >
                                            <div className="flex items-start justify-between gap-4">
                                                <div className="flex-1 min-w-0">
                                                    <div className="flex items-center gap-2">
                                                        <h3 className="font-medium truncate">{topic.title}</h3>
                                                        {topic.used && (
                                                            <Badge variant="outline" className="text-xs">已使用</Badge>
                                                        )}
                                                    </div>
                                                    {topic.description && (
                                                        <p className="text-sm text-muted-foreground mt-1 line-clamp-2">
                                                            {topic.description}
                                                        </p>
                                                    )}
                                                    {topic.keywords && (
                                                        <div className="flex flex-wrap gap-1 mt-2">
                                                            {topic.keywords.split(/[,，]/).map((kw, i) => (
                                                                <Badge key={i} variant="secondary" className="text-xs">
                                                                    {kw.trim()}
                                                                </Badge>
                                                            ))}
                                                        </div>
                                                    )}
                                                </div>
                                                <div className="flex items-center gap-1 shrink-0">
                                                    {!topic.used && (
                                                        <Button
                                                            variant="ghost"
                                                            size="icon"
                                                            onClick={() => handleMarkUsed(topic)}
                                                            title="标记为已使用"
                                                        >
                                                            <Check className="h-4 w-4" />
                                                        </Button>
                                                    )}
                                                    <Button
                                                        variant="ghost"
                                                        size="icon"
                                                        onClick={() => handleDelete(topic)}
                                                        className="text-red-500 hover:text-red-600"
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* 手动添加对话框 */}
            <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>添加主题</DialogTitle>
                        <DialogDescription>手动添加一个文章主题创意</DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Label>主题标题 *</Label>
                            <Input
                                placeholder="如：2024 年最值得学习的编程语言"
                                value={formData.title}
                                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>描述/大纲</Label>
                            <Textarea
                                placeholder="简要描述文章内容方向..."
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>关键词</Label>
                            <Input
                                placeholder="用逗号分隔多个关键词"
                                value={formData.keywords}
                                onChange={(e) => setFormData({ ...formData, keywords: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>分类</Label>
                            <Input
                                placeholder="如：技术、生活、产品等"
                                value={formData.category}
                                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                            />
                        </div>
                    </div>

                    <DialogFooter>
                        <Button variant="outline" onClick={() => setShowAddDialog(false)}>
                            取消
                        </Button>
                        <Button onClick={handleSave} disabled={saving}>
                            {saving ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    保存中...
                                </>
                            ) : (
                                "保存"
                            )}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* AI 生成对话框 */}
            <Dialog open={showGenerateDialog} onOpenChange={setShowGenerateDialog}>
                <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle>AI 生成主题</DialogTitle>
                        <DialogDescription>
                            输入主题方向，AI 将批量生成文章主题创意
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label>主题方向 *</Label>
                                <Input
                                    placeholder="如：Python 编程、健康养生"
                                    value={generateData.topic}
                                    onChange={(e) => setGenerateData({ ...generateData, topic: e.target.value })}
                                />
                            </div>
                            <div className="space-y-2">
                                <Label>生成数量</Label>
                                <Input
                                    type="number"
                                    min={1}
                                    max={20}
                                    value={generateData.count}
                                    onChange={(e) => setGenerateData({ ...generateData, count: parseInt(e.target.value) || 10 })}
                                />
                            </div>
                        </div>
                        <div className="space-y-2">
                            <Label>保存到分类</Label>
                            <Input
                                placeholder="默认：AI 生成"
                                value={generateData.category}
                                onChange={(e) => setGenerateData({ ...generateData, category: e.target.value })}
                            />
                        </div>

                        <Button
                            onClick={handleGenerate}
                            disabled={generating}
                            className="w-full bg-gradient-to-r from-amber-500 to-orange-500"
                        >
                            {generating ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    生成中...
                                </>
                            ) : (
                                <>
                                    <Sparkles className="mr-2 h-4 w-4" />
                                    开始生成
                                </>
                            )}
                        </Button>

                        {generatedTopics && (
                            <div className="space-y-2">
                                <Label>生成结果</Label>
                                <div className="bg-gray-50 dark:bg-gray-800 p-4 rounded-lg max-h-64 overflow-y-auto">
                                    <pre className="text-sm whitespace-pre-wrap font-mono">
                                        {generatedTopics}
                                    </pre>
                                </div>
                            </div>
                        )}
                    </div>

                    <DialogFooter>
                        <Button variant="outline" onClick={() => setShowGenerateDialog(false)}>
                            关闭
                        </Button>
                        {generatedTopics && !generating && (
                            <Button onClick={handleSaveGenerated} disabled={saving}>
                                {saving ? (
                                    <>
                                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                        保存中...
                                    </>
                                ) : (
                                    "保存到主题库"
                                )}
                            </Button>
                        )}
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
