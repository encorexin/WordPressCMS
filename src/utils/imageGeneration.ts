// AI 图片生成服务 - 支持多种 API

export interface ImageGenerationConfig {
    provider: 'openai' | 'aliyun' | 'baidu' | 'stability' | 'zhipu' | 'siliconflow' | 'replicate' | 'custom';
    apiKey: string;
    apiEndpoint?: string;
    model?: string;
}

export interface GeneratedImage {
    url: string;
    alt: string;
}

// OpenAI DALL-E 生成
async function generateWithOpenAI(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint || 'https://api.openai.com/v1/images/generations';
    const model = config.model || 'dall-e-3';

    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            model: model,
            prompt: prompt,
            n: 1,
            size: '1024x1024',
            response_format: 'url',
        }),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error?.message || '图片生成失败');
    }

    const data = await response.json();
    return {
        url: data.data[0].url,
        alt: prompt.slice(0, 100),
    };
}

// 阿里云通义万相生成
async function generateWithAliyun(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint || 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis';
    const model = config.model || 'wanx-v1';

    // 提交任务
    const submitResponse = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
            'X-DashScope-Async': 'enable',
        },
        body: JSON.stringify({
            model: model,
            input: {
                prompt: prompt,
            },
            parameters: {
                size: '1024*1024',
                n: 1,
            },
        }),
    });

    if (!submitResponse.ok) {
        const error = await submitResponse.json();
        throw new Error(error.message || '提交任务失败');
    }

    const submitData = await submitResponse.json();
    const taskId = submitData.output?.task_id;

    if (!taskId) {
        throw new Error('获取任务ID失败');
    }

    // 轮询获取结果
    const resultEndpoint = `https://dashscope.aliyuncs.com/api/v1/tasks/${taskId}`;
    let attempts = 0;
    const maxAttempts = 60;

    while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 2000));

        const resultResponse = await fetch(resultEndpoint, {
            headers: {
                'Authorization': `Bearer ${config.apiKey}`,
            },
        });

        const resultData = await resultResponse.json();
        const status = resultData.output?.task_status;

        if (status === 'SUCCEEDED') {
            const imageUrl = resultData.output?.results?.[0]?.url;
            if (imageUrl) {
                return {
                    url: imageUrl,
                    alt: prompt.slice(0, 100),
                };
            }
            throw new Error('获取图片URL失败');
        } else if (status === 'FAILED') {
            throw new Error(resultData.output?.message || '图片生成失败');
        }

        attempts++;
    }

    throw new Error('图片生成超时');
}

// 智谱 AI CogView 生成
async function generateWithZhipu(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint || 'https://open.bigmodel.cn/api/paas/v4/images/generations';
    const model = config.model || 'cogview-3-plus';

    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            model: model,
            prompt: prompt,
            size: '1024x1024',
        }),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error?.message || '图片生成失败');
    }

    const data = await response.json();
    return {
        url: data.data[0].url,
        alt: prompt.slice(0, 100),
    };
}

// Stability AI 生成
async function generateWithStability(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint || 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';

    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
            'Accept': 'application/json',
        },
        body: JSON.stringify({
            text_prompts: [{ text: prompt, weight: 1 }],
            cfg_scale: 7,
            height: 1024,
            width: 1024,
            samples: 1,
            steps: 30,
        }),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || '图片生成失败');
    }

    const data = await response.json();
    const base64Image = data.artifacts[0].base64;

    // 返回 base64 格式的图片
    return {
        url: `data:image/png;base64,${base64Image}`,
        alt: prompt.slice(0, 100),
    };
}

// 百度文心一格生成
async function generateWithBaidu(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    // 百度需要先获取 access_token（这里假设 apiKey 格式为 "api_key:secret_key"）
    const [apiKey, secretKey] = config.apiKey.split(':');

    if (!secretKey) {
        throw new Error('百度 API 需要格式: API_KEY:SECRET_KEY');
    }

    // 获取 access_token
    const tokenResponse = await fetch(
        `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${apiKey}&client_secret=${secretKey}`,
        { method: 'POST' }
    );

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;

    if (!accessToken) {
        throw new Error('获取百度 access_token 失败');
    }

    // 生成图片
    const endpoint = config.apiEndpoint || 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2';

    const response = await fetch(`${endpoint}?access_token=${accessToken}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            prompt: prompt,
            width: 1024,
            height: 1024,
            image_num: 1,
        }),
    });

    const data = await response.json();

    if (data.error_code) {
        throw new Error(data.error_msg || '图片生成失败');
    }

    // 百度也是异步的，需要轮询
    const taskId = data.data?.task_id;
    if (!taskId) {
        throw new Error('获取任务ID失败');
    }

    const queryEndpoint = 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/getImgv2';
    let attempts = 0;
    const maxAttempts = 60;

    while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 2000));

        const queryResponse = await fetch(`${queryEndpoint}?access_token=${accessToken}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ task_id: taskId }),
        });

        const queryData = await queryResponse.json();

        if (queryData.data?.task_status === 'SUCCESS') {
            const imageUrl = queryData.data?.sub_task_result_list?.[0]?.final_image_list?.[0]?.img_url;
            if (imageUrl) {
                return {
                    url: imageUrl,
                    alt: prompt.slice(0, 100),
                };
            }
            throw new Error('获取图片URL失败');
        } else if (queryData.data?.task_status === 'FAILED') {
            throw new Error('图片生成失败');
        }

        attempts++;
    }

    throw new Error('图片生成超时');
}

// SiliconFlow 生成 (OpenAI 兼容格式)
async function generateWithSiliconFlow(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint || 'https://api.siliconflow.cn/v1/images/generations';
    const model = config.model || 'black-forest-labs/FLUX.1-schnell';

    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            model: model,
            prompt: prompt,
            image_size: '1024x1024',
            batch_size: 1,
            num_inference_steps: 20,
        }),
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        const message = error.error?.message || error.message || error.detail || `请求失败: ${response.status}`;
        throw new Error(`SiliconFlow: ${message}`);
    }

    const data = await response.json();
    const imageUrl = data.images?.[0]?.url || data.data?.[0]?.url;

    if (!imageUrl) {
        throw new Error('SiliconFlow: 未能获取图片 URL');
    }

    return {
        url: imageUrl,
        alt: prompt.slice(0, 100),
    };
}

// Replicate 生成
async function generateWithReplicate(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint || 'https://api.replicate.com/v1/predictions';
    const model = config.model || 'stability-ai/stable-diffusion-3';

    // 创建预测
    const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            version: model,
            input: {
                prompt: prompt,
                width: 1024,
                height: 1024,
            },
        }),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || '图片生成失败');
    }

    const prediction = await response.json();

    // 轮询获取结果
    let attempts = 0;
    const maxAttempts = 60;

    while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 2000));

        const statusResponse = await fetch(prediction.urls.get, {
            headers: {
                'Authorization': `Bearer ${config.apiKey}`,
            },
        });

        const statusData = await statusResponse.json();

        if (statusData.status === 'succeeded') {
            const output = statusData.output;
            const imageUrl = Array.isArray(output) ? output[0] : output;
            return {
                url: imageUrl,
                alt: prompt.slice(0, 100),
            };
        } else if (statusData.status === 'failed') {
            throw new Error(statusData.error || '图片生成失败');
        }

        attempts++;
    }

    throw new Error('图片生成超时');
}

// 自定义端点生成 (OpenAI 兼容格式)
async function generateWithCustom(
    prompt: string,
    config: ImageGenerationConfig
): Promise<GeneratedImage> {
    if (!config.apiEndpoint) {
        throw new Error('自定义端点需要提供 API 端点');
    }

    const response = await fetch(config.apiEndpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${config.apiKey}`,
        },
        body: JSON.stringify({
            model: config.model || 'default',
            prompt: prompt,
            n: 1,
            size: '1024x1024',
        }),
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(error.error?.message || error.message || `请求失败: ${response.status}`);
    }

    const data = await response.json();

    // 尝试多种响应格式
    const imageUrl = data.data?.[0]?.url
        || data.images?.[0]?.url
        || data.output?.[0]
        || data.url
        || data.image_url;

    if (!imageUrl) {
        throw new Error('无法从响应中获取图片 URL');
    }

    return {
        url: imageUrl,
        alt: prompt.slice(0, 100),
    };
}

// 主生成函数
export async function generateImage(
    prompt: string,
    config: ImageGenerationConfig,
    onProgress?: (status: string) => void
): Promise<GeneratedImage> {
    onProgress?.('开始生成图片...');

    try {
        let result: GeneratedImage;

        switch (config.provider) {
            case 'openai':
                onProgress?.('使用 DALL-E 生成中...');
                result = await generateWithOpenAI(prompt, config);
                break;
            case 'aliyun':
                onProgress?.('使用通义万相生成中...');
                result = await generateWithAliyun(prompt, config);
                break;
            case 'zhipu':
                onProgress?.('使用智谱 CogView 生成中...');
                result = await generateWithZhipu(prompt, config);
                break;
            case 'stability':
                onProgress?.('使用 Stable Diffusion 生成中...');
                result = await generateWithStability(prompt, config);
                break;
            case 'baidu':
                onProgress?.('使用文心一格生成中...');
                result = await generateWithBaidu(prompt, config);
                break;
            case 'siliconflow':
                onProgress?.('使用 SiliconFlow 生成中...');
                result = await generateWithSiliconFlow(prompt, config);
                break;
            case 'replicate':
                onProgress?.('使用 Replicate 生成中...');
                result = await generateWithReplicate(prompt, config);
                break;
            case 'custom':
                onProgress?.('使用自定义端点生成中...');
                result = await generateWithCustom(prompt, config);
                break;
            default:
                throw new Error(`不支持的图片生成服务: ${config.provider}`);
        }

        onProgress?.('图片生成完成！');
        return result;
    } catch (error) {
        onProgress?.('图片生成失败');
        throw error;
    }
}

// 根据文章内容生成图片提示词
export function generateImagePrompt(keywords: string, title: string): string {
    return `A professional, high-quality illustration for an article about "${title}". Keywords: ${keywords}. Style: modern, clean, professional, suitable for blog post header image. No text or watermarks.`;
}

// 将图片插入到 Markdown 内容中
export function insertImageToContent(content: string, imageUrl: string, alt: string): string {
    // 在文章开头插入图片
    const imageMarkdown = `![${alt}](${imageUrl})\n\n`;
    return imageMarkdown + content;
}

// 支持的图片生成服务列表
export const IMAGE_PROVIDERS = [
    {
        value: 'openai',
        label: 'OpenAI DALL-E',
        description: '高质量 AI 生成图片',
        endpoint: 'https://api.openai.com/v1/images/generations',
        models: ['dall-e-3', 'dall-e-2'],
    },
    {
        value: 'aliyun',
        label: '阿里云通义万相',
        description: '阿里云 AI 图片生成',
        endpoint: 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis',
        models: ['wanx-v1', 'wanx-lite'],
    },
    {
        value: 'zhipu',
        label: '智谱 CogView',
        description: '智谱 AI 图片生成',
        endpoint: 'https://open.bigmodel.cn/api/paas/v4/images/generations',
        models: ['cogview-3-plus', 'cogview-3'],
    },
    {
        value: 'stability',
        label: 'Stability AI',
        description: 'Stable Diffusion 图片生成',
        endpoint: 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
        models: ['stable-diffusion-xl-1024-v1-0'],
    },
    {
        value: 'baidu',
        label: '百度文心一格',
        description: '百度 AI 图片生成 (需要 API_KEY:SECRET_KEY)',
        endpoint: 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2',
        models: ['v2'],
    },
    {
        value: 'siliconflow',
        label: 'SiliconFlow 硅基流动',
        description: '国内高性价比图片生成，FLUX.1-schnell 免费',
        endpoint: 'https://api.siliconflow.cn/v1/images/generations',
        models: ['black-forest-labs/FLUX.1-schnell', 'stabilityai/stable-diffusion-3-5-large', 'Kwai-Kolors/Kolors'],
    },
    {
        value: 'replicate',
        label: 'Replicate',
        description: '云端模型平台，支持多种开源模型',
        endpoint: 'https://api.replicate.com/v1/predictions',
        models: ['stability-ai/stable-diffusion-3', 'black-forest-labs/flux-schnell'],
    },
    {
        value: 'custom',
        label: '自定义端点',
        description: '使用自定义 API 端点 (OpenAI 兼容格式)',
        endpoint: '',
        models: [],
        requiresEndpoint: true,
    },
];

