import { db, generateId, getTimestamp, type AISettings } from './database';

// 默认提示词模板
const DEFAULT_SYSTEM_PROMPT = `你是一位专业的内容创作者，擅长撰写高质量的文章。
请根据用户提供的关键词和模板风格来生成文章。

要求：
1. 文章结构清晰，包含标题、引言、正文和结论
2. 内容专业、准确、有深度
3. 语言流畅，易于阅读
4. 字数在800-1500字之间
5. 使用Markdown格式输出`;

// 默认 AI 设置
const DEFAULT_AI_SETTINGS = {
    api_endpoint: 'https://api.openai.com/v1/chat/completions',
    api_key: '',
    model: 'gpt-3.5-turbo',
    system_prompt: DEFAULT_SYSTEM_PROMPT,
};

// 获取用户的 AI 设置
export async function getAISettings(userId: string): Promise<AISettings | null> {
    const settings = await db.ai_settings.where('user_id').equals(userId).first();
    return settings ?? null;
}

// 保存或更新 AI 设置
export async function saveAISettings(
    userId: string,
    settings: { api_endpoint: string; api_key: string; model: string; system_prompt: string }
): Promise<AISettings> {
    const existing = await db.ai_settings.where('user_id').equals(userId).first();

    if (existing) {
        await db.ai_settings.update(existing.id, {
            ...settings,
            updated_at: getTimestamp(),
        });
        return { ...existing, ...settings, updated_at: getTimestamp() };
    } else {
        const newSettings: AISettings = {
            id: generateId(),
            user_id: userId,
            ...settings,
            created_at: getTimestamp(),
            updated_at: getTimestamp(),
        };
        await db.ai_settings.add(newSettings);
        return newSettings;
    }
}

// 获取有效的 AI 设置（如果用户没有设置，返回默认值）
export async function getEffectiveAISettings(userId: string): Promise<{
    api_endpoint: string;
    api_key: string;
    model: string;
    system_prompt: string;
}> {
    const settings = await getAISettings(userId);
    if (settings && settings.api_key) {
        return {
            api_endpoint: settings.api_endpoint,
            api_key: settings.api_key,
            model: settings.model,
            system_prompt: settings.system_prompt || DEFAULT_SYSTEM_PROMPT,
        };
    }
    return DEFAULT_AI_SETTINGS;
}

// 测试 AI API 连接
export async function testAIConnection(settings: {
    api_endpoint: string;
    api_key: string;
    model: string;
}): Promise<{ success: boolean; message: string }> {
    try {
        const response = await fetch(settings.api_endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${settings.api_key}`,
            },
            body: JSON.stringify({
                model: settings.model,
                messages: [{ role: 'user', content: 'Hi' }],
                max_tokens: 5,
            }),
        });

        if (response.ok) {
            const data = await response.json();
            if (data.choices && data.choices.length > 0) {
                return { success: true, message: '连接成功！API 可用' };
            }
            return { success: true, message: '连接成功' };
        } else {
            const errorData = await response.json().catch(() => ({}));
            return {
                success: false,
                message: errorData.error?.message || `连接失败: ${response.status}`
            };
        }
    } catch (error) {
        return {
            success: false,
            message: error instanceof Error ? error.message : '连接失败'
        };
    }
}

// 获取默认提示词
export function getDefaultSystemPrompt(): string {
    return DEFAULT_SYSTEM_PROMPT;
}
