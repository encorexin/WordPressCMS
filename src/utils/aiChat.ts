import ky, {
  type KyResponse,
  type AfterResponseHook,
  type NormalizedOptions,
} from "ky";
import {
  createParser,
  type EventSourceParser,
} from "eventsource-parser";

export interface SSEOptions {
  onData: (data: string) => void;
  onEvent?: (event: any) => void;
  onCompleted?: (error?: Error) => void;
  onAborted?: () => void;
  onReconnectInterval?: (interval: number) => void;
}

export const createSSEHook = (options: SSEOptions): AfterResponseHook => {
  const hook: AfterResponseHook = async (
    request: Request,
    _options: NormalizedOptions,
    response: KyResponse
  ) => {
    if (!response.ok || !response.body) {
      return;
    }

    let completed: boolean = false;
    const innerOnCompleted = (error?: Error): void => {
      if (completed) {
        return;
      }

      completed = true;
      options.onCompleted?.(error);
    };

    const isAborted: boolean = false;

    const reader: ReadableStreamDefaultReader<Uint8Array> =
      response.body.getReader();

    const decoder: TextDecoder = new TextDecoder("utf8");

    const parser: EventSourceParser = createParser({
      onEvent: (event) => {
        if (event.data) {
          options.onEvent?.(event);
          // 处理单 message 多 data字段的场景
          const dataArray: string[] = event.data.split("\\ ");
          for (const data of dataArray) {
            options.onData(data);
          }
        }
      },
    });

    const read = (): void => {
      if (isAborted) {
        return;
      }

      reader
        .read()
        .then((result: ReadableStreamReadResult<Uint8Array>) => {
          if (result.done) {
            innerOnCompleted();
            return;
          }

          parser.feed(decoder.decode(result.value, { stream: true }));

          read();
        })
        .catch((error) => {
          /**
           * 判断是否是手动调用 abortController.abort() 而停止的请求
           */
          if (request.signal.aborted) {
            options.onAborted?.();
            return;
          }

          innerOnCompleted(error as Error);
        });
    };

    read();

    return response;
  };

  return hook;
};

export interface ChatMessage {
  role: "user" | "assistant" | "system";
  content: string;
  id?: string;
}

export interface ChatStreamOptions {
  /** 模型调用接口地址 */
  endpoint: string;
  /** 消息列表 */
  messages: ChatMessage[];
  /** 应用id (可选，用于兼容旧版) */
  apiId?: string;
  /** API Key (新版使用) */
  apiKey?: string;
  /** 模型名称 (新版使用) */
  model?: string;
  /** 流式返回更新回调 */
  onUpdate: (content: string) => void;
  /** 模型调用完成回调 */
  onComplete: () => void;
  /** 模型调用完成回调 */
  onError: (error: Error) => void;
  /** 中断控制 */
  signal?: AbortSignal;
}

export const sendChatStream = async (
  options: ChatStreamOptions
): Promise<void> => {
  const { messages, onUpdate, onComplete, onError, signal } = options;

  let currentContent = "";

  const sseHook = createSSEHook({
    onData: (data: string) => {
      try {
        // 处理 [DONE] 标记
        if (data === "[DONE]") {
          return;
        }
        const parsed = JSON.parse(data);
        if (parsed.choices?.[0]?.delta?.content) {
          currentContent += parsed.choices[0].delta.content;
          onUpdate(currentContent);
        }
      } catch {
        console.warn("Failed to parse SSE data:", data);
      }
    },
    onCompleted: (error?: Error) => {
      if (error) {
        onError(error);
      } else {
        onComplete();
      }
    },
    onAborted: () => {
      console.log("Stream aborted");
    },
  });

  // 构建请求头
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  // 优先使用 API Key，否则使用旧版 X-App-Id
  if (options.apiKey) {
    headers["Authorization"] = `Bearer ${options.apiKey}`;
  } else if (options.apiId) {
    headers["X-App-Id"] = options.apiId;
  }

  // 构建请求体
  const body: Record<string, unknown> = {
    messages: messages.map((msg) => ({
      role: msg.role,
      content: msg.content,
    })),
    stream: true,
  };

  // 如果指定了模型，添加到请求体
  if (options.model) {
    body.model = options.model;
  }

  try {
    await ky.post(options.endpoint, {
      json: body,
      headers,
      signal,
      timeout: 60000,
      hooks: {
        afterResponse: [sseHook],
      },
    });
  } catch (error) {
    if (!signal?.aborted) {
      onError(error as Error);
    }
  }
};

// 生成 SEO 友好的文章别名
export async function generateSEOSlug(
  title: string,
  options: {
    endpoint: string;
    apiKey?: string;
    model?: string;
  }
): Promise<string> {
  const prompt = `请将以下中文标题转换为SEO友好的英文URL别名(slug)。

要求：
1. 全部小写
2. 单词之间用短横线(-)连接
3. 只包含英文字母、数字和短横线
4. 简洁明了，长度控制在3-8个单词
5. 移除无意义的词（如 the, a, an 等）
6. 直接输出slug结果，不要任何解释或其他文字

标题：${title}`;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (options.apiKey) {
    headers["Authorization"] = `Bearer ${options.apiKey}`;
  }

  // 确保端点格式正确
  let endpoint = options.endpoint;
  if (!endpoint.includes('/chat/completions') && !endpoint.includes('/v1/')) {
    endpoint = endpoint.replace(/\/$/, '') + '/chat/completions';
  }

  // 检查是否是推理模型（如 deepseek-reasoner）
  const isReasonerModel = options.model?.includes('reasoner') || options.model?.includes('r1');

  const body: Record<string, unknown> = {
    messages: [{ role: "user", content: prompt }],
    model: options.model || "gpt-3.5-turbo",
    max_tokens: isReasonerModel ? 1000 : 100, // 推理模型需要更多 tokens
    temperature: 0.3,
    stream: false,
  };

  try {
    console.log("SEO Slug API 请求:", { endpoint, body });

    const response = await fetch(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("AI Slug 生成失败:", response.status, errorText);
      throw new Error(`API 请求失败: ${response.status}`);
    }

    const data = await response.json();
    console.log("API 原始响应:", JSON.stringify(data, null, 2));

    // 尝试多种方式提取内容
    let slug = "";

    // OpenAI 格式
    if (data.choices?.[0]?.message?.content) {
      slug = data.choices[0].message.content.trim();
    }
    // DeepSeek Reasoner 格式 - 内容可能在 reasoning_content 中，或者需要从中提取
    else if (data.choices?.[0]?.message?.reasoning_content) {
      // 从推理内容中尝试提取 slug（通常在最后）
      const reasoning = data.choices[0].message.reasoning_content;
      // 尝试找到最后生成的 slug 格式内容
      const slugMatch = reasoning.match(/[a-z][a-z0-9-]*[a-z0-9]/gi);
      if (slugMatch && slugMatch.length > 0) {
        // 取最后一个匹配的、看起来像 slug 的内容
        slug = slugMatch[slugMatch.length - 1];
      }
    }
    // 其他可能的格式
    else if (data.choices?.[0]?.text) {
      slug = data.choices[0].text.trim();
    }
    else if (data.result) {
      slug = data.result.trim();
    }
    else if (data.response) {
      slug = data.response.trim();
    }
    else if (data.output) {
      slug = data.output.trim();
    }
    else if (typeof data === 'string') {
      slug = data.trim();
    }

    console.log("提取的原始内容:", slug);

    // 如果仍然为空，尝试基于标题自动生成一个简单的 slug
    if (!slug) {
      console.log("API 未返回有效内容，使用本地生成");
      // 使用 pinyin 或简单的中文到英文映射是理想的，这里先用简单处理
      slug = "article-" + Date.now().toString(36);
    }

    // 移除可能的引号和多余字符
    slug = slug.replace(/^["'`]|["'`]$/g, '');
    slug = slug.replace(/^slug[：:]\s*/i, '');
    slug = slug.replace(/\n.*/g, ''); // 只取第一行

    // 清理结果
    slug = slug
      .toLowerCase()
      .replace(/[^a-z0-9-\s]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "")
      .substring(0, 60); // 限制长度

    console.log("最终处理后:", slug);

    return slug;
  } catch (error) {
    console.error("生成 SEO Slug 失败:", error);
    throw error;
  }
}

