import { useState, useEffect } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
    Card,
    CardContent,
    CardDescription,
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
import { toast } from "sonner";
import {
    Plus,
    Loader2,
    FileText,
    Trash2,
    Edit2,
    Sparkles,
} from "lucide-react";
import {
    getTemplates,
    createTemplate,
    updateTemplate,
    deleteTemplate,
    initDefaultTemplates,
    cleanDuplicateTemplates,
    type ArticleTemplate,
} from "@/db/templateService";

export default function Templates() {
    const { user } = useAuth();
    const [templates, setTemplates] = useState<ArticleTemplate[]>([]);
    const [loading, setLoading] = useState(true);
    const [showDialog, setShowDialog] = useState(false);
    const [editingTemplate, setEditingTemplate] = useState<ArticleTemplate | null>(null);
    const [saving, setSaving] = useState(false);

    const [formData, setFormData] = useState({
        name: "",
        description: "",
        system_prompt: "",
    });

    useEffect(() => {
        if (user?.id) {
            loadTemplates();
        }
    }, [user]);

    const loadTemplates = async () => {
        if (!user?.id) return;

        try {
            setLoading(true);
            // 清理重复模板
            await cleanDuplicateTemplates(user.id);
            // 初始化默认模板（首次使用）
            await initDefaultTemplates(user.id);
            const data = await getTemplates(user.id);
            setTemplates(data);
        } catch (error) {
            console.error("加载模板失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = () => {
        setEditingTemplate(null);
        setFormData({ name: "", description: "", system_prompt: "" });
        setShowDialog(true);
    };

    const handleEdit = (template: ArticleTemplate) => {
        setEditingTemplate(template);
        setFormData({
            name: template.name,
            description: template.description,
            system_prompt: template.system_prompt,
        });
        setShowDialog(true);
    };

    const handleDelete = async (template: ArticleTemplate) => {
        if (!confirm(`确定要删除模板 "${template.name}" 吗？`)) return;

        try {
            await deleteTemplate(template.id);
            toast.success("模板已删除");
            await loadTemplates();
        } catch (error) {
            toast.error("删除失败");
        }
    };

    const handleSave = async () => {
        if (!user?.id) return;

        if (!formData.name.trim()) {
            toast.error("请输入模板名称");
            return;
        }

        try {
            setSaving(true);

            if (editingTemplate) {
                await updateTemplate(editingTemplate.id, formData);
                toast.success("模板已更新");
            } else {
                await createTemplate(user.id, formData);
                toast.success("模板已创建");
            }

            setShowDialog(false);
            await loadTemplates();
        } catch (error) {
            toast.error("保存失败");
        } finally {
            setSaving(false);
        }
    };

    return (
        <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-4xl">
            {/* 头部 */}
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center space-x-3">
                    <div className="p-2 bg-gradient-to-br from-orange-500 to-red-500 rounded-lg">
                        <FileText className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <h1 className="text-2xl font-bold">模板库</h1>
                        <p className="text-sm text-muted-foreground">管理文章生成模板</p>
                    </div>
                </div>
                <Button onClick={handleAdd} className="bg-gradient-to-r from-orange-500 to-red-500">
                    <Plus className="mr-2 h-4 w-4" />
                    新建模板
                </Button>
            </div>

            {/* 模板列表 */}
            {loading ? (
                <div className="flex justify-center py-12">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </div>
            ) : templates.length === 0 ? (
                <Card className="border-0 shadow-lg">
                    <CardContent className="py-12 text-center">
                        <Sparkles className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                        <p className="text-muted-foreground">暂无模板，点击上方按钮创建</p>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-4 md:grid-cols-2">
                    {templates.map((template) => (
                        <Card key={template.id} className="border-0 shadow-lg hover:shadow-xl transition-shadow">
                            <CardHeader className="pb-2">
                                <div className="flex items-start justify-between">
                                    <div>
                                        <CardTitle className="text-lg">{template.name}</CardTitle>
                                        <CardDescription className="mt-1">
                                            {template.description || "无描述"}
                                        </CardDescription>
                                    </div>
                                    <div className="flex space-x-1">
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            onClick={() => handleEdit(template)}
                                        >
                                            <Edit2 className="h-4 w-4" />
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            onClick={() => handleDelete(template)}
                                            className="text-red-500 hover:text-red-600"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <div className="text-xs text-muted-foreground bg-gray-50 dark:bg-gray-800/50 p-3 rounded-lg max-h-24 overflow-hidden">
                                    <pre className="whitespace-pre-wrap font-mono">
                                        {template.system_prompt.slice(0, 200)}
                                        {template.system_prompt.length > 200 && "..."}
                                    </pre>
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* 编辑对话框 */}
            <Dialog open={showDialog} onOpenChange={setShowDialog}>
                <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle>
                            {editingTemplate ? "编辑模板" : "新建模板"}
                        </DialogTitle>
                        <DialogDescription>
                            创建自定义的文章生成模板
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Label>模板名称</Label>
                            <Input
                                placeholder="如：技术教程、产品评测"
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>描述（可选）</Label>
                            <Input
                                placeholder="简单描述这个模板的用途"
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>系统提示词</Label>
                            <Textarea
                                placeholder="定义 AI 的角色和生成要求..."
                                value={formData.system_prompt}
                                onChange={(e) => setFormData({ ...formData, system_prompt: e.target.value })}
                                className="min-h-[200px] font-mono text-sm"
                            />
                            <p className="text-xs text-muted-foreground">
                                提示：使用 {"{keywords}"} 和 {"{template}"} 作为占位符
                            </p>
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
                                    保存中...
                                </>
                            ) : (
                                "保存"
                            )}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
}
