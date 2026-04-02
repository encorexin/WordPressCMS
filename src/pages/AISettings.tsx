import React, { useState, useEffect } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/ui/card";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { toast } from "sonner";
import { Loader2, Settings, Zap, Save, CheckCircle, RotateCcw, ImageIcon, Plus, Pencil, Trash2, Star, CheckCircle2 } from "lucide-react";
import {
    getAllAISettings,
    createAISettings,
    updateAISettings,
    deleteAISettings,
    setDefaultAISettings,
    testAIConnection,
    getDefaultSystemPrompt
} from "@/db/aiSettings";
import type { AISettings } from "@/db/database";
import { IMAGE_PROVIDERS } from "@/utils/imageGeneration";
import { Switch } from "@/components/ui/switch";
import { aiLogger } from "@/utils/logger";

const ENDPOINT_MODELS = {
    openai: {
        label: "OpenAI",
        endpoint: "https://api.openai.com/v1/chat/completions",
        models: [
            { value: "gpt-5", label: "GPT-5 (旗舰)" },
            { value: "gpt-5-mini", label: "GPT-5 Mini" },
            { value: "gpt-5-nano", label: "GPT-5 Nano" },
            { value: "gpt-4.1", label: "GPT-4.1" },
            { value: "gpt-4.1-mini", label: "GPT-4.1 Mini" },
            { value: "gpt-4.1-nano", label: "GPT-4.1 Nano" },
            { value: "gpt-4o", label: "GPT-4o" },
            { value: "gpt-4o-mini", label: "GPT-4o Mini" },
            { value: "o3", label: "o3 (推理)" },
            { value: "o4-mini", label: "o4 Mini (推理)" },
        ],
    },
    anthropic: {
        label: "Anthropic (Claude)",
        endpoint: "https://api.anthropic.com/v1/messages",
        models: [
            { value: "claude-4-opus", label: "Claude 4 Opus (最强)" },
            { value: "claude-4-sonnet", label: "Claude 4 Sonnet" },
            { value: "claude-3-7-sonnet-20250219", label: "Claude 3.7 Sonnet" },
            { value: "claude-3-5-sonnet-20241022", label: "Claude 3.5 Sonnet" },
            { value: "claude-3-5-haiku-20241022", label: "Claude 3.5 Haiku" },
        ],
    },
    deepseek: {
        label: "DeepSeek",
        endpoint: "https://api.deepseek.com/v1/chat/completions",
        models: [
            { value: "deepseek-chat", label: "DeepSeek V3.2" },
            { value: "deepseek-reasoner", label: "DeepSeek R1 (推理)" },
        ],
    },
    google: {
        label: "Google (Gemini)",
        endpoint: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
        models: [
            { value: "gemini-2.5-pro", label: "Gemini 2.5 Pro" },
            { value: "gemini-2.5-flash", label: "Gemini 2.5 Flash" },
            { value: "gemini-2.5-flash-lite", label: "Gemini 2.5 Flash Lite" },
            { value: "gemini-2.0-flash", label: "Gemini 2.0 Flash" },
        ],
    },
    aliyun: {
        label: "阿里云百炼",
        endpoint: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        models: [
            { value: "qwen3-max", label: "Qwen3 Max (旗舰)" },
            { value: "qwen3-32b", label: "Qwen3 32B (开源)" },
            { value: "qwen3.5-omni-plus", label: "Qwen3.5 Omni Plus" },
            { value: "qwen3.5-omni-flash", label: "Qwen3.5 Omni Flash" },
            { value: "qwen-max", label: "Qwen Max" },
            { value: "qwen-plus", label: "Qwen Plus" },
            { value: "qwen-turbo", label: "Qwen Turbo" },
            { value: "qwen-coder-plus", label: "Qwen Coder Plus" },
        ],
    },
    zhipu: {
        label: "智谱 AI",
        endpoint: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        models: [
            { value: "glm-5", label: "GLM-5 (旗舰)" },
            { value: "glm-5-turbo", label: "GLM-5 Turbo" },
            { value: "glm-5.1", label: "GLM-5.1" },
            { value: "glm-4.6v", label: "GLM-4.6V (视觉)" },
            { value: "glm-4-flash", label: "GLM-4 Flash" },
        ],
    },
    moonshot: {
        label: "Moonshot (Kimi)",
        endpoint: "https://api.moonshot.cn/v1/chat/completions",
        models: [
            { value: "kimi-k2-5", label: "Kimi K2.5 (最新)" },
            { value: "kimi-k2", label: "Kimi K2 (开源万亿)" },
            { value: "kimi-latest", label: "Kimi Latest" },
            { value: "moonshot-v1-128k", label: "Kimi K1 (128K)" },
        ],
    },
    siliconflow: {
        label: "SiliconFlow",
        endpoint: "https://api.siliconflow.cn/v1/chat/completions",
        models: [
            { value: "deepseek-ai/DeepSeek-V3", label: "DeepSeek V3" },
            { value: "deepseek-ai/DeepSeek-R1", label: "DeepSeek R1" },
            { value: "Qwen/Qwen3-32B", label: "Qwen3 32B" },
            { value: "meta-llama/Llama-3.3-70B-Instruct", label: "Llama 3.3 70B" },
            { value: "THUDM/glm-4-9b-chat", label: "GLM-4 9B" },
        ],
    },
    groq: {
        label: "Groq",
        endpoint: "https://api.groq.com/openai/v1/chat/completions",
        models: [
            { value: "llama-3.3-70b-versatile", label: "Llama 3.3 70B" },
            { value: "llama-3.1-8b-instant", label: "Llama 3.1 8B" },
            { value: "deepseek-r1-distill-llama-70b", label: "DeepSeek R1 70B" },
            { value: "mixtral-8x7b-32768", label: "Mixtral 8x7B" },
        ],
    },
    together: {
        label: "Together AI",
        endpoint: "https://api.together.xyz/v1/chat/completions",
        models: [
            { value: "meta-llama/Llama-3.3-70B-Instruct-Turbo", label: "Llama 3.3 70B" },
            { value: "Qwen/Qwen3-32B-Instruct", label: "Qwen3 32B" },
            { value: "deepseek-ai/DeepSeek-V3", label: "DeepSeek V3" },
            { value: "deepseek-ai/DeepSeek-R1", label: "DeepSeek R1" },
        ],
    },
    openrouter: {
        label: "OpenRouter",
        endpoint: "https://openrouter.ai/api/v1/chat/completions",
        models: [
            { value: "openai/gpt-5", label: "GPT-5" },
            { value: "anthropic/claude-4-opus", label: "Claude 4 Opus" },
            { value: "anthropic/claude-4-sonnet", label: "Claude 4 Sonnet" },
            { value: "google/gemini-2.5-pro", label: "Gemini 2.5 Pro" },
            { value: "deepseek/deepseek-chat", label: "DeepSeek V3" },
            { value: "qwen/qwen-3-32b", label: "Qwen3 32B" },
        ],
    },
} as const;

const PRESET_ENDPOINTS = [
    ...Object.entries(ENDPOINT_MODELS).map(([key, config]) => ({
        value: config.endpoint,
        label: config.label,
        key,
    })),
    { value: "custom", label: "自定义端点...", key: "custom" },
];

const ALL_MODELS = Object.values(ENDPOINT_MODELS).flatMap(config => config.models);
const CUSTOM_MODEL_OPTION = { value: "custom", label: "自定义模型..." };

const EMPTY_FORM = {
    name: "",
    api_endpoint: "https://api.openai.com/v1/chat/completions",
    api_key: "",
    model: "gpt-4o",
    system_prompt: getDefaultSystemPrompt(),
    image_enabled: false,
    image_provider: "siliconflow" as AISettings['image_provider'],
    image_api_key: "",
    image_endpoint: "",
    image_model: "",
    slug_enabled: true,
    slug_model: "",
};

export default function AISettingsPage() {
    const { user } = useAuth();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [testing, setTesting] = useState(false);
    const [settingsList, setSettingsList] = useState<AISettings[]>([]);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [dialogOpen, setDialogOpen] = useState(false);
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
    const [deletingId, setDeletingId] = useState<string | null>(null);

    const [formData, setFormData] = useState(EMPTY_FORM);
    const [useCustomEndpoint, setUseCustomEndpoint] = useState(false);
    const [customEndpoint, setCustomEndpoint] = useState("");
    const [useCustomModel, setUseCustomModel] = useState(false);
    const [customModel, setCustomModel] = useState("");

    useEffect(() => {
        loadSettings();
    }, [user]);

    const loadSettings = async () => {
        if (!user?.id) return;
        try {
            setLoading(true);
            const settings = await getAllAISettings(user.id);
            setSettingsList(settings);
        } catch (error) {
            aiLogger.error("加载设置失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const openCreateDialog = () => {
        setEditingId(null);
        setFormData({ ...EMPTY_FORM, name: `配置 ${settingsList.length + 1}` });
        setUseCustomEndpoint(false);
        setCustomEndpoint("");
        setUseCustomModel(false);
        setCustomModel("");
        setDialogOpen(true);
    };

    const openEditDialog = (settings: AISettings) => {
        setEditingId(settings.id);
        setFormData({
            name: settings.name,
            api_endpoint: settings.api_endpoint,
            api_key: settings.api_key,
            model: settings.model,
            system_prompt: settings.system_prompt || getDefaultSystemPrompt(),
            image_enabled: settings.image_enabled ?? false,
            image_provider: settings.image_provider || "siliconflow",
            image_api_key: settings.image_api_key || "",
            image_endpoint: settings.image_endpoint || "",
            image_model: settings.image_model || "",
            slug_enabled: settings.slug_enabled ?? true,
            slug_model: settings.slug_model || "",
        });

        const presetEndpoint = PRESET_ENDPOINTS.find(e => e.value === settings.api_endpoint);
        if (presetEndpoint && presetEndpoint.key !== "custom") {
            setUseCustomEndpoint(false);
        } else {
            setUseCustomEndpoint(true);
            setCustomEndpoint(settings.api_endpoint);
        }

        const availableModels = useCustomEndpoint
            ? ALL_MODELS
            : (presetEndpoint && presetEndpoint.key !== "custom"
                ? ENDPOINT_MODELS[presetEndpoint.key as keyof typeof ENDPOINT_MODELS].models
                : ALL_MODELS);
        const presetModel = availableModels.find(m => m.value === settings.model);
        if (presetModel) {
            setUseCustomModel(false);
        } else {
            setUseCustomModel(true);
            setCustomModel(settings.model);
        }

        setDialogOpen(true);
    };

    const handleSave = async () => {
        if (!user?.id) return;

        const finalEndpoint = useCustomEndpoint ? customEndpoint : formData.api_endpoint;
        const finalModel = useCustomModel ? customModel : formData.model;

        if (!formData.name.trim()) {
            toast.error("请输入配置名称");
            return;
        }
        if (!finalEndpoint) {
            toast.error("请输入 API 端点");
            return;
        }
        if (!formData.api_key) {
            toast.error("请输入 API Key");
            return;
        }
        if (!finalModel) {
            toast.error("请选择或输入模型");
            return;
        }

        try {
            setSaving(true);
            const settingsData = {
                name: formData.name.trim(),
                api_endpoint: finalEndpoint,
                api_key: formData.api_key,
                model: finalModel,
                system_prompt: formData.system_prompt,
                image_enabled: formData.image_enabled,
                image_provider: formData.image_provider,
                image_api_key: formData.image_api_key,
                image_endpoint: formData.image_endpoint,
                image_model: formData.image_model,
                slug_enabled: formData.slug_enabled,
                slug_model: formData.slug_model,
            };

            if (editingId) {
                await updateAISettings(editingId, user.id, settingsData);
                toast.success("配置更新成功");
            } else {
                await createAISettings(user.id, settingsData);
                toast.success("配置创建成功");
            }

            setDialogOpen(false);
            loadSettings();
        } catch (error) {
            toast.error(editingId ? "更新失败" : "创建失败");
        } finally {
            setSaving(false);
        }
    };

    const handleTest = async () => {
        const finalEndpoint = useCustomEndpoint ? customEndpoint : formData.api_endpoint;
        const finalModel = useCustomModel ? customModel : formData.model;

        if (!finalEndpoint || !formData.api_key || !finalModel) {
            toast.error("请先填写完整的 API 配置");
            return;
        }

        try {
            setTesting(true);
            const result = await testAIConnection({
                api_endpoint: finalEndpoint,
                api_key: formData.api_key,
                model: finalModel,
            });

            if (result.success) {
                toast.success(result.message);
            } else {
                toast.error(result.message);
            }
        } catch {
            toast.error("测试失败");
        } finally {
            setTesting(false);
        }
    };

    const handleDelete = async () => {
        if (!user?.id || !deletingId) return;

        try {
            await deleteAISettings(deletingId, user.id);
            toast.success("配置已删除");
            setDeleteDialogOpen(false);
            setDeletingId(null);
            loadSettings();
        } catch {
            toast.error("删除失败");
        }
    };

    const handleSetDefault = async (settingsId: string) => {
        if (!user?.id) return;

        try {
            await setDefaultAISettings(settingsId, user.id);
            toast.success("已设为默认配置");
            loadSettings();
        } catch {
            toast.error("设置失败");
        }
    };

    const handleEndpointChange = (value: string) => {
        if (value === "custom") {
            setUseCustomEndpoint(true);
            setFormData(prev => ({ ...prev, api_endpoint: "custom" }));
        } else {
            setUseCustomEndpoint(false);
            setFormData(prev => ({ ...prev, api_endpoint: value }));
            const provider = Object.entries(ENDPOINT_MODELS).find(
                ([, config]) => config.endpoint === value
            );
            if (provider) {
                setFormData(prev => ({ ...prev, model: provider[1].models[0].value }));
                setUseCustomModel(false);
            }
        }
    };

    const handleModelChange = (value: string) => {
        if (value === "custom") {
            setUseCustomModel(true);
            setFormData(prev => ({ ...prev, model: "custom" }));
        } else {
            setUseCustomModel(false);
            setFormData(prev => ({ ...prev, model: value }));
        }
    };

    const getAvailableModels = () => {
        if (useCustomEndpoint) {
            return [...ALL_MODELS, CUSTOM_MODEL_OPTION];
        }
        const provider = Object.entries(ENDPOINT_MODELS).find(
            ([, config]) => config.endpoint === formData.api_endpoint
        );
        if (provider) {
            return [...provider[1].models, CUSTOM_MODEL_OPTION];
        }
        return [...ALL_MODELS, CUSTOM_MODEL_OPTION];
    };

    if (loading) {
        return (
            <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-4xl">
                <Card className="border-0 shadow-lg">
                    <CardContent className="p-8 flex justify-center">
                        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                    </CardContent>
                </Card>
            </div>
        );
    }

    return (
        <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-4xl space-y-6">
            <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                    <div className="p-2 bg-gradient-to-br from-purple-500 to-pink-500 rounded-lg">
                        <Settings className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <h1 className="text-2xl font-bold">AI 配置管理</h1>
                        <p className="text-sm text-muted-foreground">管理多个 AI API 配置，文章生成时可选择使用</p>
                    </div>
                </div>
                <Button onClick={openCreateDialog} className="bg-gradient-to-r from-blue-500 to-purple-600">
                    <Plus className="mr-2 h-4 w-4" />
                    新建配置
                </Button>
            </div>

            {settingsList.length === 0 ? (
                <Card className="border-0 shadow-lg">
                    <CardContent className="p-8 text-center">
                        <Settings className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                        <h3 className="text-lg font-medium mb-2">暂无 AI 配置</h3>
                        <p className="text-muted-foreground mb-4">创建您的第一个 AI 配置以开始生成文章</p>
                        <Button onClick={openCreateDialog} className="bg-gradient-to-r from-blue-500 to-purple-600">
                            <Plus className="mr-2 h-4 w-4" />
                            创建配置
                        </Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-4">
                    {settingsList.map((settings) => (
                        <Card key={settings.id} className={`border-0 shadow-lg ${settings.is_default ? 'ring-2 ring-blue-500' : ''}`}>
                            <CardHeader className="pb-3">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center space-x-3">
                                        <div className={`p-2 rounded-lg ${settings.is_default ? 'bg-gradient-to-br from-blue-500 to-purple-600' : 'bg-muted'}`}>
                                            <Settings className="h-4 w-4 text-white" />
                                        </div>
                                        <div>
                                            <CardTitle className="text-lg flex items-center gap-2">
                                                {settings.name}
                                                {settings.is_default && (
                                                    <span className="text-xs bg-blue-500 text-white px-2 py-0.5 rounded-full">
                                                        默认
                                                    </span>
                                                )}
                                            </CardTitle>
                                            <CardDescription className="text-xs mt-1">
                                                {settings.model} · {PRESET_ENDPOINTS.find(e => e.value === settings.api_endpoint)?.label || '自定义端点'}
                                            </CardDescription>
                                        </div>
                                    </div>
                                    <div className="flex items-center space-x-2">
                                        {!settings.is_default && (
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                onClick={() => handleSetDefault(settings.id)}
                                                title="设为默认"
                                            >
                                                <Star className="h-4 w-4" />
                                            </Button>
                                        )}
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => openEditDialog(settings)}
                                        >
                                            <Pencil className="h-4 w-4" />
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => {
                                                setDeletingId(settings.id);
                                                setDeleteDialogOpen(true);
                                            }}
                                            className="text-destructive hover:text-destructive"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            </CardHeader>
                            <CardContent className="pt-0">
                                <div className="flex flex-wrap gap-2 text-xs text-muted-foreground">
                                    {settings.image_enabled && (
                                        <span className="bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 px-2 py-1 rounded">
                                            图片生成
                                        </span>
                                    )}
                                    {settings.slug_enabled && (
                                        <span className="bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300 px-2 py-1 rounded">
                                            别名生成
                                        </span>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
                <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle>{editingId ? '编辑配置' : '新建配置'}</DialogTitle>
                        <DialogDescription>
                            配置 AI API 信息，用于文章生成
                        </DialogDescription>
                    </DialogHeader>

                    <div className="space-y-6 py-4">
                        <div className="space-y-2">
                            <Label>配置名称</Label>
                            <Input
                                placeholder="例如：GPT-5 生产环境"
                                value={formData.name}
                                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>API 端点</Label>
                            <Select
                                value={useCustomEndpoint ? "custom" : formData.api_endpoint}
                                onValueChange={handleEndpointChange}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="选择 API 端点" />
                                </SelectTrigger>
                                <SelectContent>
                                    {PRESET_ENDPOINTS.map((endpoint) => (
                                        <SelectItem key={endpoint.value} value={endpoint.value}>
                                            {endpoint.label}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                            {useCustomEndpoint && (
                                <>
                                    <Input
                                        placeholder="输入自定义 API 端点 URL"
                                        value={customEndpoint}
                                        onChange={(e) => setCustomEndpoint(e.target.value)}
                                    />
                                    <p className="text-xs text-muted-foreground">
                                        支持的端点格式：OpenAI 兼容格式 <code className="bg-muted px-1 rounded">/v1/chat/completions</code> 或 Anthropic 格式 <code className="bg-muted px-1 rounded">/v1/messages</code>
                                    </p>
                                </>
                            )}
                        </div>

                        <div className="space-y-2">
                            <Label>API Key</Label>
                            <Input
                                type="password"
                                placeholder="sk-..."
                                value={formData.api_key}
                                onChange={(e) => setFormData(prev => ({ ...prev, api_key: e.target.value }))}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>模型</Label>
                            <Select
                                value={useCustomModel ? "custom" : formData.model}
                                onValueChange={handleModelChange}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="选择模型" />
                                </SelectTrigger>
                                <SelectContent>
                                    {useCustomEndpoint ? (
                                        Object.entries(ENDPOINT_MODELS).map(([key, config]) => (
                                            <React.Fragment key={key}>
                                                <div className="px-2 py-1.5 text-xs font-semibold text-muted-foreground">
                                                    {config.label}
                                                </div>
                                                {config.models.map((m) => (
                                                    <SelectItem key={m.value} value={m.value} className="pl-6">
                                                        {m.label}
                                                    </SelectItem>
                                                ))}
                                            </React.Fragment>
                                        ))
                                    ) : (
                                        getAvailableModels()
                                            .filter(m => m.value !== "custom")
                                            .map((m) => (
                                                <SelectItem key={m.value} value={m.value}>
                                                    {m.label}
                                                </SelectItem>
                                            ))
                                    )}
                                    <SelectItem value="custom" className="border-t mt-1 pt-1">
                                        自定义模型...
                                    </SelectItem>
                                </SelectContent>
                            </Select>
                            {useCustomModel && (
                                <Input
                                    placeholder="输入自定义模型名称"
                                    value={customModel}
                                    onChange={(e) => setCustomModel(e.target.value)}
                                />
                            )}
                        </div>

                        <Button
                            onClick={handleTest}
                            variant="outline"
                            className="w-full"
                            disabled={testing || saving}
                        >
                            {testing ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    测试中...
                                </>
                            ) : (
                                <>
                                    <Zap className="mr-2 h-4 w-4" />
                                    测试连接
                                </>
                            )}
                        </Button>

                        <div className="space-y-2">
                            <div className="flex items-center justify-between">
                                <Label>系统提示词</Label>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => setFormData(prev => ({ ...prev, system_prompt: getDefaultSystemPrompt() }))}
                                >
                                    <RotateCcw className="h-4 w-4 mr-1" />
                                    重置
                                </Button>
                            </div>
                            <Textarea
                                placeholder="输入系统提示词..."
                                value={formData.system_prompt}
                                onChange={(e) => setFormData(prev => ({ ...prev, system_prompt: e.target.value }))}
                                className="min-h-[150px] font-mono text-sm"
                            />
                        </div>

                        <Card className="border-0 shadow-lg bg-muted/50">
                            <CardHeader className="pb-3">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center space-x-3">
                                        <div className="p-2 bg-gradient-to-br from-green-500 to-teal-600 rounded-lg">
                                            <ImageIcon className="h-4 w-4 text-white" />
                                        </div>
                                        <div>
                                            <CardTitle className="text-base">图片生成设置</CardTitle>
                                        </div>
                                    </div>
                                    <Switch
                                        checked={formData.image_enabled}
                                        onCheckedChange={(checked) => setFormData(prev => ({ ...prev, image_enabled: checked }))}
                                    />
                                </div>
                            </CardHeader>
                            {formData.image_enabled && (
                                <CardContent className="space-y-4">
                                    <div className="space-y-2">
                                        <Label>图片生成服务</Label>
                                        <Select
                                            value={formData.image_provider}
                                            onValueChange={(v) => setFormData(prev => ({ ...prev, image_provider: v as AISettings['image_provider'] }))}
                                        >
                                            <SelectTrigger>
                                                <SelectValue />
                                            </SelectTrigger>
                                            <SelectContent>
                                                {IMAGE_PROVIDERS.map((provider) => (
                                                    <SelectItem key={provider.value} value={provider.value}>
                                                        {provider.label}
                                                    </SelectItem>
                                                ))}
                                            </SelectContent>
                                        </Select>
                                    </div>
                                    <div className="space-y-2">
                                        <Label>图片 API Key</Label>
                                        <Input
                                            type="password"
                                            placeholder="输入图片生成服务的 API Key"
                                            value={formData.image_api_key}
                                            onChange={(e) => setFormData(prev => ({ ...prev, image_api_key: e.target.value }))}
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label>API 端点 (可选)</Label>
                                        <Input
                                            placeholder="使用默认端点"
                                            value={formData.image_endpoint}
                                            onChange={(e) => setFormData(prev => ({ ...prev, image_endpoint: e.target.value }))}
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label>模型 (可选)</Label>
                                        <Input
                                            placeholder="使用默认模型"
                                            value={formData.image_model}
                                            onChange={(e) => setFormData(prev => ({ ...prev, image_model: e.target.value }))}
                                        />
                                    </div>
                                </CardContent>
                            )}
                        </Card>

                        <Card className="border-0 shadow-lg bg-muted/50">
                            <CardHeader className="pb-3">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center space-x-3">
                                        <div className="p-2 bg-gradient-to-br from-orange-500 to-amber-600 rounded-lg">
                                            <Zap className="h-4 w-4 text-white" />
                                        </div>
                                        <div>
                                            <CardTitle className="text-base">文章别名生成</CardTitle>
                                        </div>
                                    </div>
                                    <Switch
                                        checked={formData.slug_enabled}
                                        onCheckedChange={(checked) => setFormData(prev => ({ ...prev, slug_enabled: checked }))}
                                    />
                                </div>
                            </CardHeader>
                            {formData.slug_enabled && (
                                <CardContent>
                                    <div className="space-y-2">
                                        <Label>使用模型</Label>
                                        <Select
                                            value={formData.slug_model || "default"}
                                            onValueChange={(v) => setFormData(prev => ({ ...prev, slug_model: v === "default" ? "" : v }))}
                                        >
                                            <SelectTrigger>
                                                <SelectValue placeholder="使用主 AI 模型" />
                                            </SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="default">使用主 AI 模型</SelectItem>
                                                {Object.entries(ENDPOINT_MODELS).map(([key, config]) => (
                                                    <React.Fragment key={key}>
                                                        <div className="px-2 py-1.5 text-xs font-semibold text-muted-foreground">
                                                            {config.label}
                                                        </div>
                                                        {config.models.map((m) => (
                                                            <SelectItem key={m.value} value={m.value} className="pl-6">
                                                                {m.label}
                                                            </SelectItem>
                                                        ))}
                                                    </React.Fragment>
                                                ))}
                                            </SelectContent>
                                        </Select>
                                        <p className="text-xs text-muted-foreground">
                                            推荐使用快速模型，不建议使用推理模型
                                        </p>
                                    </div>
                                </CardContent>
                            )}
                        </Card>
                    </div>

                    <DialogFooter>
                        <Button variant="outline" onClick={() => setDialogOpen(false)}>
                            取消
                        </Button>
                        <Button
                            onClick={handleSave}
                            className="bg-gradient-to-r from-blue-500 to-purple-600"
                            disabled={testing || saving}
                        >
                            {saving ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    保存中...
                                </>
                            ) : (
                                <>
                                    <Save className="mr-2 h-4 w-4" />
                                    保存配置
                                </>
                            )}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>确认删除</AlertDialogTitle>
                        <AlertDialogDescription>
                            确定要删除此配置吗？此操作无法撤销。
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>取消</AlertDialogCancel>
                        <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground">
                            删除
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>

            <div className="bg-blue-50 dark:bg-blue-950/30 p-4 rounded-lg">
                <div className="flex items-start space-x-2">
                    <CheckCircle className="h-5 w-5 text-blue-500 mt-0.5 flex-shrink-0" />
                    <div className="text-sm text-blue-700 dark:text-blue-300">
                        <p className="font-medium mb-1">多配置说明</p>
                        <p className="text-blue-600 dark:text-blue-400">
                            您可以创建多个 AI 配置，在文章生成时选择使用不同的配置。默认配置会在文章编辑器中自动选中。
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}
