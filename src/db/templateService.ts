import { db, generateId, getTimestamp, type ArticleTemplate } from './database';
export type { ArticleTemplate };

// 获取用户的所有模板
export async function getTemplates(userId: string): Promise<ArticleTemplate[]> {
    return await db.article_templates
        .where('user_id')
        .equals(userId)
        .reverse()
        .sortBy('created_at');
}

// 获取单个模板
export async function getTemplate(templateId: string): Promise<ArticleTemplate | null> {
    const template = await db.article_templates.get(templateId);
    return template ?? null;
}

// 创建模板
export async function createTemplate(
    userId: string,
    data: { name: string; description: string; system_prompt: string }
): Promise<ArticleTemplate> {
    const template: ArticleTemplate = {
        id: generateId(),
        user_id: userId,
        name: data.name,
        description: data.description,
        system_prompt: data.system_prompt,
        created_at: getTimestamp(),
        updated_at: getTimestamp(),
    };

    await db.article_templates.add(template);
    return template;
}

// 更新模板
export async function updateTemplate(
    templateId: string,
    data: Partial<{ name: string; description: string; system_prompt: string }>
): Promise<ArticleTemplate | null> {
    await db.article_templates.update(templateId, {
        ...data,
        updated_at: getTimestamp(),
    });
    return await getTemplate(templateId);
}

// 删除模板
export async function deleteTemplate(templateId: string): Promise<void> {
    await db.article_templates.delete(templateId);
}

// 预置默认模板
export const DEFAULT_TEMPLATES = [
    {
        name: '技术教程',
        description: '适用于技术文章、编程教程等',
        system_prompt: `你是一位经验丰富的技术作者，擅长撰写清晰易懂的技术教程。

请根据用户提供的关键词创作一篇技术教程文章：

要求：
1. 使用通俗易懂的语言解释技术概念
2. 包含代码示例（如适用）
3. 分步骤讲解，循序渐进
4. 提供实践建议和注意事项
5. 使用 Markdown 格式，代码块需标注语言
6. 字数 1000-1500 字`,
    },
    {
        name: '产品评测',
        description: '适用于产品介绍、评测类文章',
        system_prompt: `你是一位专业的产品评测作者，擅长客观分析产品优缺点。

请根据用户提供的关键词创作一篇产品评测文章：

要求：
1. 客观公正地分析产品特点
2. 从多个维度评价（功能、性能、价格、用户体验等）
3. 列出产品优点和缺点
4. 与同类产品进行对比（如适用）
5. 给出购买建议
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
    },
    {
        name: 'SEO 文章',
        description: '适用于搜索引擎优化的内容',
        system_prompt: `你是一位 SEO 内容专家，擅长撰写对搜索引擎友好的文章。

请根据用户提供的关键词创作一篇 SEO 优化文章：

要求：
1. 关键词自然融入标题和正文
2. 使用清晰的标题层级（H1、H2、H3）
3. 开头段落包含核心关键词
4. 每个段落聚焦一个主题
5. 适当使用列表和表格
6. 结尾包含 CTA（行动号召）
7. 使用 Markdown 格式
8. 字数 1000-1500 字`,
    },
    {
        name: '新闻稿',
        description: '适用于新闻报道、公告类文章',
        system_prompt: `你是一位专业的新闻编辑，擅长撰写客观准确的新闻稿。

请根据用户提供的关键词创作一篇新闻稿：

要求：
1. 遵循新闻写作规范（倒金字塔结构）
2. 开头概括核心内容（5W1H）
3. 语言客观、准确、简洁
4. 引用相关数据和事实
5. 保持中立立场
6. 使用 Markdown 格式
7. 字数 500-800 字`,
    },
    {
        name: '博客文章',
        description: '适用于个人博客、生活分享',
        system_prompt: `你是一位有亲和力的博客作者，擅长用轻松的语气分享见解。

请根据用户提供的关键词创作一篇博客文章：

要求：
1. 语气亲切、自然，像与朋友对话
2. 融入个人观点和感受
3. 使用生动的比喻和例子
4. 段落简短，易于阅读
5. 可以适当使用表情符号
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
    },
    {
        name: '操作指南',
        description: '适用于步骤教程、使用说明',
        system_prompt: `你是一位技术文档专家，擅长撰写清晰的操作指南。

请根据用户提供的关键词创作一篇操作指南：

要求：
1. 使用编号列表，步骤清晰
2. 每个步骤独立、具体、可执行
3. 包含必要的前置条件和注意事项
4. 适当配合说明性文字
5. 使用 Markdown 格式
6. 字数 600-1000 字`,
    },
    {
        name: '清单文章',
        description: '适用于 Top 10、盘点类文章',
        system_prompt: `你是一位内容策划专家，擅长撰写引人入胜的清单类文章。

请根据用户提供的关键词创作一篇清单文章：

要求：
1. 标题吸引眼球（如"10个必知的..."）
2. 每个条目独立成段，有小标题
3. 内容多样，覆盖不同角度
4. 提供实用价值
5. 结尾有总结
6. 使用 Markdown 格式
7. 字数 1000-1500 字`,
    },
    {
        name: '品牌故事',
        description: '适用于企业介绍、品牌宣传',
        system_prompt: `你是一位品牌文案专家，擅长讲述动人的品牌故事。

请根据用户提供的关键词创作一篇品牌故事：

要求：
1. 突出品牌理念和价值观
2. 融入创始故事或发展历程
3. 情感共鸣，建立连接
4. 突出差异化优势
5. 结尾有行动号召
6. 使用 Markdown 格式
7. 字数 600-1000 字`,
    },
    {
        name: '知识科普',
        description: '适用于科普解读、知识分享',
        system_prompt: `你是一位知识传播专家，擅长将复杂概念用简单语言解释。

请根据用户提供的关键词创作一篇知识科普文章：

要求：
1. 从基础概念讲起
2. 使用通俗比喻帮助理解
3. 循序渐进，层层深入
4. 举例说明，贴近生活
5. 总结要点，加深记忆
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
    },
    {
        name: '社媒文案',
        description: '适用于微信公众号、社交媒体',
        system_prompt: `你是一位社交媒体运营专家，擅长撰写吸引眼球的社媒文案。

请根据用户提供的关键词创作一篇社媒文案：

要求：
1. 开头抓住注意力（钩子文案）
2. 语言简洁有力，金句频出
3. 段落短小，适合手机阅读
4. 善用分隔符和留白
5. 结尾引导互动或行动
6. 使用 Markdown 格式
7. 字数 500-800 字`,
    },
];

// 初始化默认模板（防止重复）
export async function initDefaultTemplates(userId: string): Promise<void> {
    const existingTemplates = await getTemplates(userId);
    const existingNames = new Set(existingTemplates.map(t => t.name));

    for (const template of DEFAULT_TEMPLATES) {
        // 只添加不存在的模板
        if (!existingNames.has(template.name)) {
            await createTemplate(userId, template);
        }
    }
}

// 清理重复模板（保留最新的）
export async function cleanDuplicateTemplates(userId: string): Promise<number> {
    const templates = await getTemplates(userId);
    const seen = new Map<string, string>(); // name -> id (保留最新的)
    const toDelete: string[] = [];

    for (const template of templates) {
        if (seen.has(template.name)) {
            toDelete.push(seen.get(template.name)!); // 删除旧的
        }
        seen.set(template.name, template.id);
    }

    for (const id of toDelete) {
        await deleteTemplate(id);
    }

    return toDelete.length;
}
