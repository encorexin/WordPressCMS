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

  const body = {
    messages: [{ role: "user", content: prompt }],
    model: options.model || "gpt-3.5-turbo",
    max_tokens: 50,
    temperature: 0.3,
    stream: false,
  };

  try {
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
    let slug = data.choices?.[0]?.message?.content?.trim() || "";

    // 移除可能的引号和多余字符
    slug = slug.replace(/^["'`]|["'`]$/g, '');
    slug = slug.replace(/^slug[：:]\s*/i, '');

    // 清理结果
    slug = slug
      .toLowerCase()
      .replace(/[^a-z0-9-\s]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "")
      .substring(0, 60); // 限制长度

    return slug;
  } catch (error) {
    console.error("生成 SEO Slug 失败:", error);
    throw error;
  }
}

