import { getEffectiveAISettings } from "@/db/aiSettings";
import { aiLogger } from "@/utils/logger";

interface FetchKeywordsResult {
    success: boolean;
    keywords?: string[];
    error?: string;
}

export async function fetchKeywordsFromAI(
    userId: string,
    topic: string,
    count: number = 20
): Promise<FetchKeywordsResult> {
    try {
        const settings = await getEffectiveAISettings(userId);

        if (!settings.api_key || !settings.api_endpoint) {
            return {
                success: false,
                error: "请先在 AI 设置中配置 API",
            };
        }

        const prompt = `请为主题"${topic}"生成 ${count} 个相关的关键词或长尾关键词。

要求：
1. 关键词应该与主题高度相关
2. 包含一些热门搜索词
3. 包含一些长尾关键词
4. 适合用于文章创作和SEO优化

请直接输出关键词列表，每行一个，不要编号，不要其他解释。`;

        const response = await fetch(settings.api_endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${settings.api_key}`,
            },
            body: JSON.stringify({
                model: settings.model,
                messages: [
                    { role: "system", content: "你是一个SEO专家，擅长生成高质量的关键词。" },
                    { role: "user", content: prompt },
                ],
                temperature: 0.7,
                max_tokens: 1000,
            }),
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            return {
                success: false,
                error: errorData.error?.message || `请求失败: ${response.status}`,
            };
        }

        const data = await response.json();
        const content = data.choices?.[0]?.message?.content || "";

        const keywords = content
            .split("\n")
            .map((line: string) => line.trim())
            .filter((line: string) => line && !line.match(/^[\d\-\*\.]+\s*/))
            .map((line: string) => line.replace(/^[\d\-\*\.]+\s*/, "").trim())
            .filter((line: string) => line.length > 0 && line.length < 50);

        return {
            success: true,
            keywords: [...new Set(keywords)],
        };
    } catch (error) {
        aiLogger.error("获取关键词失败:", error);
        return {
            success: false,
            error: error instanceof Error ? error.message : "获取关键词失败",
        };
    }
}

export async function fetchKeywordsFromTrends(
    topic: string
): Promise<FetchKeywordsResult> {
    try {
        const response = await fetch(
            `https://api.allorigins.win/raw?url=${encodeURIComponent(
                `https://suggestqueries.google.com/complete/search?client=firefox&q=${encodeURIComponent(topic)}`
            )}`
        );

        if (!response.ok) {
            return {
                success: false,
                error: "网络请求失败",
            };
        }

        const data = await response.json();

        if (Array.isArray(data) && data.length > 1) {
            const suggestions = data[1] as string[];
            return {
                success: true,
                keywords: suggestions.slice(0, 10),
            };
        }

        return {
            success: false,
            error: "未获取到相关建议",
        };
    } catch (error) {
        aiLogger.error("获取搜索建议失败:", error);
        return {
            success: false,
            error: "获取搜索建议失败",
        };
    }
}
