import { db, generateId, getTimestamp, type AISettings } from "./database";

const DEFAULT_SYSTEM_PROMPT = `你是一位专业的内容创作者，擅长撰写高质量的文章。
请根据用户提供的关键词和模板风格来生成文章。

要求：
1. 文章结构清晰，包含标题、引言、正文和结论
2. 内容专业、准确、有深度
3. 语言流畅，易于阅读
4. 字数在800-1500字之间
5. 使用Markdown格式输出`;

const DEFAULT_AI_SETTINGS = {
  api_endpoint: "https://api.openai.com/v1/chat/completions",
  api_key: "",
  model: "gpt-5.4",
  system_prompt: DEFAULT_SYSTEM_PROMPT,
};

// 获取用户的所有 AI 配置
export async function getAllAISettings(userId: string): Promise<AISettings[]> {
  const settings = await db.ai_settings.where("user_id").equals(userId).toArray();
  return settings.sort((a, b) => {
    if (a.is_default && !b.is_default) return -1;
    if (!a.is_default && b.is_default) return 1;
    return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime();
  });
}

// 获取用户的默认 AI 配置
export async function getDefaultAISettings(userId: string): Promise<AISettings | null> {
  const settings = await db.ai_settings
    .where("user_id")
    .equals(userId)
    .and((s) => s.is_default)
    .first();

  if (settings) return settings;

  const allSettings = await getAllAISettings(userId);
  return allSettings[0] ?? null;
}

// 获取单个 AI 配置
export async function getAISettingsById(
  settingsId: string,
  userId?: string
): Promise<AISettings | null> {
  const settings = await db.ai_settings.get(settingsId);
  if (!settings) return null;
  if (userId && settings.user_id !== userId) return null;
  return settings;
}

// 兼容旧接口：获取用户的 AI 设置（返回默认配置）
export async function getAISettings(userId: string): Promise<AISettings | null> {
  return getDefaultAISettings(userId);
}

// 创建新的 AI 配置
export async function createAISettings(
  userId: string,
  settings: {
    name: string;
    api_endpoint: string;
    api_key: string;
    model: string;
    system_prompt: string;
    is_default?: boolean;
    image_provider?: AISettings["image_provider"];
    image_api_key?: string;
    image_endpoint?: string;
    image_model?: string;
    image_enabled?: boolean;
    slug_model?: string;
    slug_enabled?: boolean;
  }
): Promise<AISettings> {
  if (settings.is_default) {
    await db.ai_settings.where("user_id").equals(userId).modify({ is_default: false });
  }

  const existingSettings = await getAllAISettings(userId);
  const shouldBeDefault = settings.is_default ?? existingSettings.length === 0;

  const newSettings: AISettings = {
    id: generateId(),
    user_id: userId,
    name: settings.name,
    is_default: shouldBeDefault,
    api_endpoint: settings.api_endpoint,
    api_key: settings.api_key,
    model: settings.model,
    system_prompt: settings.system_prompt,
    image_provider: settings.image_provider,
    image_api_key: settings.image_api_key,
    image_endpoint: settings.image_endpoint,
    image_model: settings.image_model,
    image_enabled: settings.image_enabled,
    slug_model: settings.slug_model,
    slug_enabled: settings.slug_enabled,
    created_at: getTimestamp(),
    updated_at: getTimestamp(),
  };

  await db.ai_settings.add(newSettings);
  return newSettings;
}

// 更新 AI 配置
export async function updateAISettings(
  settingsId: string,
  userId: string,
  settings: Partial<Omit<AISettings, "id" | "user_id" | "created_at">>
): Promise<AISettings | null> {
  const existing = await db.ai_settings.get(settingsId);
  if (!existing || existing.user_id !== userId) {
    return null;
  }

  if (settings.is_default) {
    await db.ai_settings.where("user_id").equals(userId).modify({ is_default: false });
  }

  const updatedSettings = {
    ...settings,
    updated_at: getTimestamp(),
  };

  await db.ai_settings.update(settingsId, updatedSettings);
  return { ...existing, ...updatedSettings } as AISettings;
}

// 保存或更新 AI 设置（兼容旧接口）
export async function saveAISettings(
  userId: string,
  settings: {
    api_endpoint: string;
    api_key: string;
    model: string;
    system_prompt: string;
    image_provider?: AISettings["image_provider"];
    image_api_key?: string;
    image_endpoint?: string;
    image_model?: string;
    image_enabled?: boolean;
    slug_model?: string;
    slug_enabled?: boolean;
  }
): Promise<AISettings> {
  const existing = await getDefaultAISettings(userId);

  if (existing) {
    return (await updateAISettings(existing.id, userId, settings)) as AISettings;
  } else {
    return createAISettings(userId, {
      name: "默认配置",
      ...settings,
    });
  }
}

// 删除 AI 配置
export async function deleteAISettings(settingsId: string, userId: string): Promise<boolean> {
  const existing = await db.ai_settings.get(settingsId);
  if (!existing || existing.user_id !== userId) {
    return false;
  }

  await db.ai_settings.delete(settingsId);

  if (existing.is_default) {
    const remaining = await getAllAISettings(userId);
    if (remaining.length > 0) {
      await db.ai_settings.update(remaining[0].id, { is_default: true });
    }
  }

  return true;
}

// 设置默认配置
export async function setDefaultAISettings(settingsId: string, userId: string): Promise<boolean> {
  const existing = await db.ai_settings.get(settingsId);
  if (!existing || existing.user_id !== userId) {
    return false;
  }

  await db.ai_settings.where("user_id").equals(userId).modify({ is_default: false });

  await db.ai_settings.update(settingsId, { is_default: true, updated_at: getTimestamp() });
  return true;
}

// 获取有效的 AI 设置
export async function getEffectiveAISettings(
  userId: string,
  settingsId?: string
): Promise<{
  id: string;
  api_endpoint: string;
  api_key: string;
  model: string;
  system_prompt: string;
}> {
  let settings: AISettings | null = null;

  if (settingsId) {
    settings = await getAISettingsById(settingsId);
  }

  if (!settings) {
    settings = await getDefaultAISettings(userId);
  }

  if (settings && settings.api_key) {
    return {
      id: settings.id,
      api_endpoint: settings.api_endpoint,
      api_key: settings.api_key,
      model: settings.model,
      system_prompt: settings.system_prompt || DEFAULT_SYSTEM_PROMPT,
    };
  }
  return { id: "", ...DEFAULT_AI_SETTINGS };
}

// 获取图片生成设置
export async function getImageSettings(
  userId: string,
  settingsId?: string
): Promise<{
  enabled: boolean;
  provider: string;
  apiKey: string;
  endpoint: string;
  model: string;
} | null> {
  let settings: AISettings | null = null;

  if (settingsId) {
    settings = await getAISettingsById(settingsId);
  } else {
    settings = await getDefaultAISettings(userId);
  }

  if (settings && settings.image_enabled && settings.image_api_key) {
    return {
      enabled: true,
      provider: settings.image_provider || "openai",
      apiKey: settings.image_api_key,
      endpoint: settings.image_endpoint || "",
      model: settings.image_model || "",
    };
  }
  return null;
}

// 获取 Slug 生成设置
export async function getSlugSettings(
  userId: string,
  settingsId?: string
): Promise<{
  enabled: boolean;
  model: string;
} | null> {
  let settings: AISettings | null = null;

  if (settingsId) {
    settings = await getAISettingsById(settingsId);
  } else {
    settings = await getDefaultAISettings(userId);
  }

  if (settings) {
    return {
      enabled: settings.slug_enabled ?? true,
      model: settings.slug_model || settings.model || "",
    };
  }
  return null;
}

// 测试 AI API 连接
export async function testAIConnection(settings: {
  api_endpoint: string;
  api_key: string;
  model: string;
}): Promise<{ success: boolean; message: string }> {
  try {
    const response = await fetch(settings.api_endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${settings.api_key}`,
      },
      body: JSON.stringify({
        model: settings.model,
        messages: [{ role: "user", content: "Hi" }],
        max_tokens: 5,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      if (data.choices && data.choices.length > 0) {
        return { success: true, message: "连接成功！API 可用" };
      }
      return { success: true, message: "连接成功" };
    } else {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        message: errorData.error?.message || `连接失败: ${response.status}`,
      };
    }
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : "连接失败",
    };
  }
}

// 获取默认提示词
export function getDefaultSystemPrompt(): string {
  return DEFAULT_SYSTEM_PROMPT;
}
