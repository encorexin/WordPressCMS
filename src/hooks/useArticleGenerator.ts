import { useCallback, useRef, useState } from "react";
import { toast } from "sonner";
import { useAuth } from "@/context/LocalAuthProvider";
import { getAISettingsById, getEffectiveAISettings, markTopicAsUsed, type Topic } from "@/db/api";
import { sendChatStream } from "@/utils/aiChat";
import { aiLogger } from "@/utils/logger";
import { withRetry } from "@/utils/retry";

export interface UseArticleGeneratorOptions {
    onUpdate: (content: string) => void;
    onComplete?: () => void;
    onError?: (error: Error) => void;
    selectedTopic?: Topic | null;
    onTopicUsed?: () => void;
}

export function useArticleGenerator(options: UseArticleGeneratorOptions) {
    const { user } = useAuth();
    const [generating, setGenerating] = useState(false);
    const [progress, setProgress] = useState(0);
    const abortControllerRef = useRef<AbortController | null>(null);

    const generate = useCallback(
        async (keywords: string, template: string, systemPrompt?: string, aiSettingsId?: string) => {
            if (!keywords) {
                toast.error("请输入关键词");
                return;
            }

            if (!user?.id) {
                toast.error("用户未登录");
                return;
            }

            try {
                setGenerating(true);
                setProgress(0);

                const aiSettings = aiSettingsId
                    ? await getAISettingsById(aiSettingsId, user.id)
                    : await getEffectiveAISettings(user.id);

                if (!aiSettings) {
                    toast.error("请先在 AI 设置中创建配置");
                    setGenerating(false);
                    return;
                }

                if (!aiSettings.api_key) {
                    toast.error("请先在 AI 设置中配置 API Key");
                    setGenerating(false);
                    return;
                }

                const finalSystemPrompt = systemPrompt || aiSettings.system_prompt;
                const processedPrompt = finalSystemPrompt
                    .replace(/\{keywords\}/g, keywords)
                    .replace(/\{template\}/g, template || "默认模板");

                const userMessage = `关键词：${keywords}\n模板风格：${template || "默认模板"}\n\n请直接输出文章内容：`;

                abortControllerRef.current = new AbortController();

                const progressInterval = setInterval(() => {
                    setProgress((prev) => Math.min(prev + Math.random() * 15, 90));
                }, 1000);

                await withRetry(
                    async () => {
                        await sendChatStream({
                            endpoint: aiSettings.api_endpoint,
                            apiKey: aiSettings.api_key,
                            model: aiSettings.model,
                            messages: [
                                { role: "system", content: processedPrompt },
                                { role: "user", content: userMessage },
                            ],
                            signal: abortControllerRef.current!.signal,
                            onUpdate: (content) => {
                                options.onUpdate(content);
                            },
                            onComplete: async () => {
                                clearInterval(progressInterval);
                                setProgress(100);
                                toast.success("文章生成完成");
                                setGenerating(false);

                                if (options.selectedTopic) {
                                    await markTopicAsUsed(user.id, options.selectedTopic.id);
                                    options.onTopicUsed?.();
                                }

                                options.onComplete?.();
                            },
                            onError: (error) => {
                                clearInterval(progressInterval);
                                if (error.name === "AbortError") {
                                    toast.info("生成已取消");
                                } else {
                                    toast.error("生成失败: " + error.message);
                                    options.onError?.(error);
                                }
                                setGenerating(false);
                            },
                        });
                    },
                    "AI 文章生成",
                    { maxRetries: 2 }
                );
            } catch (error) {
                aiLogger.error("生成失败:", error);
                toast.error("生成失败");
                setGenerating(false);
            }
        },
        [user?.id, options]
    );

    const stop = useCallback(() => {
        if (abortControllerRef.current) {
            abortControllerRef.current.abort();
            abortControllerRef.current = null;
        }
    }, []);

    return {
        generating,
        progress,
        generate,
        stop,
    };
}
