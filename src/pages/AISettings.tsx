import { useState, useEffect } from "react";
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
import { toast } from "sonner";
import { Loader2, Settings, Zap, Save, CheckCircle, RotateCcw, ImageIcon } from "lucide-react";
import { getAISettings, saveAISettings, testAIConnection, getDefaultSystemPrompt } from "@/db/aiSettings";
import type { AISettings } from "@/db/database";
import { IMAGE_PROVIDERS } from "@/utils/imageGeneration";
import { Switch } from "@/components/ui/switch";

const PRESET_MODELS = [
    // OpenAI
    { value: "gpt-4o", label: "GPT-4o" },
    { value: "gpt-4o-mini", label: "GPT-4o Mini" },
    { value: "gpt-4-turbo", label: "GPT-4 Turbo" },
    { value: "gpt-4", label: "GPT-4" },
    { value: "gpt-3.5-turbo", label: "GPT-3.5 Turbo" },
    { value: "o1-preview", label: "o1 Preview" },
    { value: "o1-mini", label: "o1 Mini" },
    // DeepSeek
    { value: "deepseek-chat", label: "DeepSeek Chat (V3)" },
    { value: "deepseek-reasoner", label: "DeepSeek Reasoner (R1)" },
    // Claude
    { value: "claude-3-5-sonnet-20241022", label: "Claude 3.5 Sonnet" },
    { value: "claude-3-5-haiku-20241022", label: "Claude 3.5 Haiku" },
    { value: "claude-3-opus-20240229", label: "Claude 3 Opus" },
    // Google
    { value: "gemini-2.0-flash-exp", label: "Gemini 2.0 Flash" },
    { value: "gemini-1.5-pro", label: "Gemini 1.5 Pro" },
    // 国内模型
    { value: "qwen-max", label: "通义千问 Max" },
    { value: "qwen-plus", label: "通义千问 Plus" },
    { value: "qwen-turbo", label: "通义千问 Turbo" },
    { value: "glm-4-plus", label: "智谱 GLM-4 Plus" },
    { value: "moonshot-v1-128k", label: "Moonshot (Kimi)" },
    { value: "yi-large", label: "零一万物 Yi-Large" },
    // 自定义
    { value: "custom", label: "自定义模型..." },
];

const PRESET_ENDPOINTS = [
    { value: "https://api.openai.com/v1/chat/completions", label: "OpenAI 官方" },
    { value: "https://api.anthropic.com/v1/messages", label: "Anthropic (Claude)" },
    { value: "https://api.deepseek.com/v1/chat/completions", label: "DeepSeek" },
    { value: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions", label: "阿里云百炼" },
    { value: "custom", label: "自定义端点..." },
];

export default function AISettingsPage() {
    const { user } = useAuth();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [testing, setTesting] = useState(false);

    const [apiEndpoint, setApiEndpoint] = useState("https://api.openai.com/v1/chat/completions");
    const [customEndpoint, setCustomEndpoint] = useState("");
    const [apiKey, setApiKey] = useState("");
    const [model, setModel] = useState("gpt-3.5-turbo");
    const [customModel, setCustomModel] = useState("");
    const [systemPrompt, setSystemPrompt] = useState(getDefaultSystemPrompt());
    const [useCustomEndpoint, setUseCustomEndpoint] = useState(false);
    const [useCustomModel, setUseCustomModel] = useState(false);

    // 图片生成设置
    const [imageEnabled, setImageEnabled] = useState(false);
    const [imageProvider, setImageProvider] = useState("siliconflow");
    const [imageApiKey, setImageApiKey] = useState("");
    const [imageEndpoint, setImageEndpoint] = useState("");
    const [imageModel, setImageModel] = useState("");

    // Slug 生成设置
    const [slugEnabled, setSlugEnabled] = useState(true);
    const [slugModel, setSlugModel] = useState("");

    useEffect(() => {
        loadSettings();
    }, [user]);

    const loadSettings = async () => {
        if (!user?.id) return;

        try {
            setLoading(true);
            const settings = await getAISettings(user.id);
            if (settings) {
                // 检查是否是预设端点
                const presetEndpoint = PRESET_ENDPOINTS.find(e => e.value === settings.api_endpoint);
                if (presetEndpoint) {
                    setApiEndpoint(settings.api_endpoint);
                    setUseCustomEndpoint(false);
                } else {
                    setApiEndpoint("custom");
                    setCustomEndpoint(settings.api_endpoint);
                    setUseCustomEndpoint(true);
                }

                // 检查是否是预设模型
                const presetModel = PRESET_MODELS.find(m => m.value === settings.model);
                if (presetModel) {
                    setModel(settings.model);
                    setUseCustomModel(false);
                } else {
                    setModel("custom");
                    setCustomModel(settings.model);
                    setUseCustomModel(true);
                }

                setApiKey(settings.api_key);
                setSystemPrompt(settings.system_prompt || getDefaultSystemPrompt());

                // 加载图片生成设置
                if (settings.image_enabled !== undefined) {
                    setImageEnabled(settings.image_enabled);
                }
                if (settings.image_provider) {
                    setImageProvider(settings.image_provider);
                }
                if (settings.image_api_key) {
                    setImageApiKey(settings.image_api_key);
                }
                if (settings.image_endpoint) {
                    setImageEndpoint(settings.image_endpoint);
                }
                if (settings.image_model) {
                    setImageModel(settings.image_model);
                }

                // 加载 Slug 生成设置
                if (settings.slug_enabled !== undefined) {
                    setSlugEnabled(settings.slug_enabled);
                }
                if (settings.slug_model) {
                    setSlugModel(settings.slug_model);
                }
            }
        } catch (error) {
            console.error("加载设置失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        if (!user?.id) return;

        const finalEndpoint = useCustomEndpoint ? customEndpoint : apiEndpoint;
        const finalModel = useCustomModel ? customModel : model;

        if (!finalEndpoint) {
            toast.error("请输入 API 端点");
            return;
        }
        if (!apiKey) {
            toast.error("请输入 API Key");
            return;
        }
        if (!finalModel) {
            toast.error("请选择或输入模型");
            return;
        }

        try {
            setSaving(true);
            await saveAISettings(user.id, {
                api_endpoint: finalEndpoint,
                api_key: apiKey,
                model: finalModel,
                system_prompt: systemPrompt,
                // 图片生成设置
                image_enabled: imageEnabled,
                image_provider: imageProvider as AISettings['image_provider'],
                image_api_key: imageApiKey,
                image_endpoint: imageEndpoint,
                image_model: imageModel,
                // Slug 生成设置
                slug_enabled: slugEnabled,
                slug_model: slugModel,
            });
            toast.success("设置保存成功");
        } catch (error) {
            toast.error("保存失败");
        } finally {
            setSaving(false);
        }
    };

    const handleTest = async () => {
        const finalEndpoint = useCustomEndpoint ? customEndpoint : apiEndpoint;
        const finalModel = useCustomModel ? customModel : model;

        if (!finalEndpoint || !apiKey || !finalModel) {
            toast.error("请先填写完整的 API 配置");
            return;
        }

        try {
            setTesting(true);
            const result = await testAIConnection({
                api_endpoint: finalEndpoint,
                api_key: apiKey,
                model: finalModel,
            });

            if (result.success) {
                toast.success(result.message);
            } else {
                toast.error(result.message);
            }
        } catch (error) {
            toast.error("测试失败");
        } finally {
            setTesting(false);
        }
    };

    const handleEndpointChange = (value: string) => {
        if (value === "custom") {
            setUseCustomEndpoint(true);
            setApiEndpoint("custom");
        } else {
            setUseCustomEndpoint(false);
            setApiEndpoint(value);
        }
    };

    const handleModelChange = (value: string) => {
        if (value === "custom") {
            setUseCustomModel(true);
            setModel("custom");
        } else {
            setUseCustomModel(false);
            setModel(value);
        }
    };

    const handleResetPrompt = () => {
        setSystemPrompt(getDefaultSystemPrompt());
        toast.success("已重置为默认提示词");
    };

    if (loading) {
        return (
            <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-2xl">
                <Card className="border-0 shadow-lg">
                    <CardContent className="p-8 flex justify-center">
                        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                    </CardContent>
                </Card>
            </div>
        );
    }

    return (
        <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-2xl space-y-6">
            {/* API 设置卡片 */}
            <Card className="border-0 shadow-lg">
                <CardHeader className="pb-4">
                    <div className="flex items-center space-x-3">
                        <div className="p-2 bg-gradient-to-br from-purple-500 to-pink-500 rounded-lg">
                            <Settings className="h-5 w-5 text-white" />
                        </div>
                        <div>
                            <CardTitle className="text-xl">API 设置</CardTitle>
                            <CardDescription>配置 AI 文章生成所使用的 API</CardDescription>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="space-y-6">
                    {/* API 端点 */}
                    <div className="space-y-2">
                        <Label htmlFor="endpoint">API 端点</Label>
                        <Select value={useCustomEndpoint ? "custom" : apiEndpoint} onValueChange={handleEndpointChange}>
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
                            <Input
                                placeholder="输入自定义 API 端点 URL"
                                value={customEndpoint}
                                onChange={(e) => setCustomEndpoint(e.target.value)}
                            />
                        )}
                    </div>

                    {/* API Key */}
                    <div className="space-y-2">
                        <Label htmlFor="apiKey">API Key</Label>
                        <Input
                            id="apiKey"
                            type="password"
                            placeholder="sk-..."
                            value={apiKey}
                            onChange={(e) => setApiKey(e.target.value)}
                        />
                        <p className="text-xs text-muted-foreground">
                            API Key 将安全存储在本地浏览器中
                        </p>
                    </div>

                    {/* 模型 */}
                    <div className="space-y-2">
                        <Label htmlFor="model">模型</Label>
                        <Select value={useCustomModel ? "custom" : model} onValueChange={handleModelChange}>
                            <SelectTrigger>
                                <SelectValue placeholder="选择模型" />
                            </SelectTrigger>
                            <SelectContent>
                                {PRESET_MODELS.map((m) => (
                                    <SelectItem key={m.value} value={m.value}>
                                        {m.label}
                                    </SelectItem>
                                ))}
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

                    {/* 测试按钮 */}
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
                </CardContent>
            </Card>

            {/* 提示词设置卡片 */}
            <Card className="border-0 shadow-lg">
                <CardHeader className="pb-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                            <div className="p-2 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-lg">
                                <Settings className="h-5 w-5 text-white" />
                            </div>
                            <div>
                                <CardTitle className="text-xl">系统提示词</CardTitle>
                                <CardDescription>自定义 AI 生成文章时使用的系统提示词</CardDescription>
                            </div>
                        </div>
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={handleResetPrompt}
                            className="text-muted-foreground hover:text-foreground"
                        >
                            <RotateCcw className="h-4 w-4 mr-1" />
                            重置
                        </Button>
                    </div>
                </CardHeader>
                <CardContent className="space-y-4">
                    <Textarea
                        placeholder="输入系统提示词..."
                        value={systemPrompt}
                        onChange={(e) => setSystemPrompt(e.target.value)}
                        className="min-h-[200px] font-mono text-sm"
                    />
                    <p className="text-xs text-muted-foreground">
                        系统提示词会作为 AI 的角色设定，影响生成内容的风格和格式。使用 {"{keywords}"} 和 {"{template}"} 作为占位符。
                    </p>
                </CardContent>
            </Card>

            {/* 图片生成设置 */}
            <Card className="border-0 shadow-lg bg-white/70 dark:bg-gray-900/70 backdrop-blur-sm">
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                            <div className="p-2 bg-gradient-to-br from-green-500 to-teal-600 rounded-lg">
                                <ImageIcon className="h-5 w-5 text-white" />
                            </div>
                            <div>
                                <CardTitle className="text-lg">图片生成设置</CardTitle>
                                <CardDescription>配置 AI 图片生成服务</CardDescription>
                            </div>
                        </div>
                        <div className="flex items-center space-x-2">
                            <Label htmlFor="image-enabled">启用</Label>
                            <Switch
                                id="image-enabled"
                                checked={imageEnabled}
                                onCheckedChange={setImageEnabled}
                            />
                        </div>
                    </div>
                </CardHeader>
                {imageEnabled && (
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label>图片生成服务</Label>
                            <Select value={imageProvider} onValueChange={setImageProvider}>
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
                            <p className="text-xs text-muted-foreground">
                                {IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.description}
                            </p>
                        </div>

                        <div className="space-y-2">
                            <Label>图片 API Key</Label>
                            <Input
                                type="password"
                                placeholder="输入图片生成服务的 API Key"
                                value={imageApiKey}
                                onChange={(e) => setImageApiKey(e.target.value)}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>API 端点 {imageProvider === 'custom' ? '(必填)' : '(可选)'}</Label>
                            <Input
                                placeholder={IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.endpoint || "输入自定义 API 端点"}
                                value={imageEndpoint}
                                onChange={(e) => setImageEndpoint(e.target.value)}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label>模型 (可选)</Label>
                            <Input
                                placeholder={IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.models?.[0] || "使用默认模型"}
                                value={imageModel}
                                onChange={(e) => setImageModel(e.target.value)}
                            />
                            {IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.models?.length ? (
                                <p className="text-xs text-muted-foreground">
                                    可用模型: {IMAGE_PROVIDERS.find(p => p.value === imageProvider)?.models?.join(', ')}
                                </p>
                            ) : null}
                        </div>
                    </CardContent>
                )}
            </Card>

            {/* 文章别名生成设置 */}
            <Card className="border-0 shadow-lg bg-white/70 dark:bg-gray-900/70 backdrop-blur-sm">
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                            <div className="p-2 bg-gradient-to-br from-orange-500 to-amber-600 rounded-lg">
                                <Zap className="h-5 w-5 text-white" />
                            </div>
                            <div>
                                <CardTitle className="text-lg">文章别名生成</CardTitle>
                                <CardDescription>使用 AI 生成 SEO 友好的 URL 别名</CardDescription>
                            </div>
                        </div>
                        <div className="flex items-center space-x-2">
                            <Label htmlFor="slug-enabled">启用</Label>
                            <Switch
                                id="slug-enabled"
                                checked={slugEnabled}
                                onCheckedChange={setSlugEnabled}
                            />
                        </div>
                    </div>
                </CardHeader>
                {slugEnabled && (
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label>使用模型</Label>
                            <Select value={slugModel || "default"} onValueChange={(v) => setSlugModel(v === "default" ? "" : v)}>
                                <SelectTrigger>
                                    <SelectValue placeholder="使用主 AI 模型" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="default">使用主 AI 模型</SelectItem>
                                    {PRESET_MODELS.filter(m => m.value !== "custom").map((m) => (
                                        <SelectItem key={m.value} value={m.value}>
                                            {m.label}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                            <p className="text-xs text-muted-foreground">
                                推荐使用快速模型如 deepseek-chat、gpt-3.5-turbo，不建议使用推理模型
                            </p>
                        </div>
                    </CardContent>
                )}
            </Card>

            {/* 保存按钮 */}
            <Button
                onClick={handleSave}
                className="w-full bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
                disabled={testing || saving}
                size="lg"
            >
                {saving ? (
                    <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        保存中...
                    </>
                ) : (
                    <>
                        <Save className="mr-2 h-4 w-4" />
                        保存所有设置
                    </>
                )}
            </Button>

            {/* 提示信息 */}
            <div className="bg-blue-50 dark:bg-blue-950/30 p-4 rounded-lg">
                <div className="flex items-start space-x-2">
                    <CheckCircle className="h-5 w-5 text-blue-500 mt-0.5 flex-shrink-0" />
                    <div className="text-sm text-blue-700 dark:text-blue-300">
                        <p className="font-medium mb-1">支持的 API 格式</p>
                        <p className="text-blue-600 dark:text-blue-400">
                            本系统支持 OpenAI 兼容格式的 API，包括 OpenAI、DeepSeek、阿里云百炼等服务。
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}
