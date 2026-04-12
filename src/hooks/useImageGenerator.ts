import { useCallback, useState } from "react";
import { toast } from "sonner";
import { useAuth } from "@/context/LocalAuthProvider";
import { getImageSettings } from "@/db/api";
import {
    generateImage,
    generateImagePrompt,
    insertImageToContent,
    type ImageGenerationConfig,
    IMAGE_PROVIDERS,
} from "@/utils/imageGeneration";
import { aiLogger } from "@/utils/logger";
import { handleApiError } from "@/utils/errorHandler";

export interface ImageSettings {
    provider: string;
    apiKey: string;
    endpoint: string;
    model: string;
    enabled: boolean;
}

export function useImageGenerator() {
    const { user } = useAuth();
    const [generating, setGenerating] = useState(false);
    const [status, setStatus] = useState("");
    const [showDialog, setShowDialog] = useState(false);
    const [prompt, setPrompt] = useState("");
    const [settings, setSettings] = useState<ImageSettings>({
        provider: "openai",
        apiKey: "",
        endpoint: "",
        model: "",
        enabled: false,
    });

    const loadSettings = useCallback(async () => {
        if (!user?.id) return;

        try {
            const imageSettings = await getImageSettings(user.id);
            if (imageSettings && imageSettings.enabled) {
                setSettings({
                    provider: imageSettings.provider,
                    apiKey: imageSettings.apiKey,
                    endpoint: imageSettings.endpoint,
                    model: imageSettings.model,
                    enabled: imageSettings.enabled,
                });
            }
        } catch (error) {
            aiLogger.error("加载图片设置失败:", error);
        }
    }, [user?.id]);

    const openDialog = useCallback((keywords: string, title: string) => {
        const generatedPrompt = generateImagePrompt(keywords, title);
        setPrompt(generatedPrompt);
        setShowDialog(true);
    }, []);

    const generate = useCallback(
        async (
            customPrompt?: string,
            customSettings?: Partial<ImageSettings>
        ): Promise<{ url: string; alt: string } | null> => {
            const finalSettings = customSettings ? { ...settings, ...customSettings } : settings;
            const finalPrompt = customPrompt || prompt;

            if (!finalSettings.apiKey) {
                toast.error("请输入图片生成 API Key");
                return null;
            }

            if (!finalPrompt) {
                toast.error("请输入图片描述");
                return null;
            }

            if (finalSettings.provider === "custom" && !finalSettings.endpoint) {
                toast.error("自定义端点需要提供 API 端点");
                return null;
            }

            setGenerating(true);
            setStatus("正在生成图片...");

            try {
                const config: ImageGenerationConfig = {
                    provider: finalSettings.provider as ImageGenerationConfig["provider"],
                    apiKey: finalSettings.apiKey,
                    apiEndpoint: finalSettings.endpoint || undefined,
                    model: finalSettings.model || undefined,
                };

                const result = await generateImage(finalPrompt, config, setStatus);

                toast.success("图片生成成功");
                setShowDialog(false);

                return { url: result.url, alt: result.alt };
            } catch (error) {
                const message = error instanceof Error ? error.message : "图片生成失败";
                toast.error(message);
                setStatus(`错误: ${message}`);
                return null;
            } finally {
                setGenerating(false);
            }
        },
        [settings, prompt]
    );

    const insertImage = useCallback(
        (currentContent: string, imageUrl: string, alt: string): string => {
            return insertImageToContent(currentContent, imageUrl, alt);
        },
        []
    );

    const updateSettings = useCallback((newSettings: Partial<ImageSettings>) => {
        setSettings((prev) => ({ ...prev, ...newSettings }));
    }, []);

    return {
        generating,
        status,
        showDialog,
        setShowDialog,
        prompt,
        setPrompt,
        settings,
        loadSettings,
        openDialog,
        generate,
        insertImage,
        updateSettings,
        providers: IMAGE_PROVIDERS,
    };
}
