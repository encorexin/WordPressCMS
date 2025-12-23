import { db } from './database';

// 导出数据结构
export interface ExportData {
    version: string;
    exportedAt: string;
    data: {
        users: any[];
        wordpress_sites: any[];
        articles: any[];
        ai_settings: any[];
        article_templates: any[];
        keywords: any[];
        topics: any[];
    };
}

// 单独导出结构
export interface SingleExportData {
    type: string;
    exportedAt: string;
    count: number;
    data: any[];
}

// 导出所有数据
export async function exportAllData(): Promise<ExportData> {
    const [users, wordpress_sites, articles, ai_settings, article_templates, keywords, topics] = await Promise.all([
        db.users.toArray(),
        db.wordpress_sites.toArray(),
        db.articles.toArray(),
        db.ai_settings.toArray(),
        db.article_templates.toArray(),
        db.keywords.toArray(),
        db.topics.toArray(),
    ]);

    return {
        version: '2.0.0',
        exportedAt: new Date().toISOString(),
        data: {
            users,
            wordpress_sites,
            articles,
            ai_settings,
            article_templates,
            keywords,
            topics,
        },
    };
}

// 导出单个表数据
export async function exportTableData(tableName: string): Promise<SingleExportData> {
    let data: any[] = [];

    switch (tableName) {
        case 'articles':
            data = await db.articles.toArray();
            break;
        case 'wordpress_sites':
            data = await db.wordpress_sites.toArray();
            break;
        case 'article_templates':
            data = await db.article_templates.toArray();
            break;
        case 'keywords':
            data = await db.keywords.toArray();
            break;
        case 'topics':
            data = await db.topics.toArray();
            break;
        case 'ai_settings':
            data = await db.ai_settings.toArray();
            break;
        default:
            throw new Error(`不支持的表: ${tableName}`);
    }

    return {
        type: tableName,
        exportedAt: new Date().toISOString(),
        count: data.length,
        data,
    };
}

// 下载 JSON 导出文件
export function downloadExportFile(data: ExportData | SingleExportData, filename?: string): void {
    const json = JSON.stringify(data, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const defaultFilename = 'type' in data
        ? `${data.type}-${new Date().toISOString().split('T')[0]}.json`
        : `wordpress-cms-backup-${new Date().toISOString().split('T')[0]}.json`;

    const a = document.createElement('a');
    a.href = url;
    a.download = filename || defaultFilename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 导出为 CSV 格式
export function exportToCSV(data: any[], filename: string): void {
    if (data.length === 0) {
        throw new Error('没有数据可导出');
    }

    // 获取所有列名
    const headers = Object.keys(data[0]);

    // 构建 CSV 内容
    const csvContent = [
        headers.join(','),
        ...data.map(row =>
            headers.map(header => {
                const value = row[header];
                // 处理特殊字符
                if (value === null || value === undefined) return '';
                const str = String(value);
                // 如果包含逗号、引号或换行，用引号包裹
                if (str.includes(',') || str.includes('"') || str.includes('\n')) {
                    return `"${str.replace(/"/g, '""')}"`;
                }
                return str;
            }).join(',')
        )
    ].join('\n');

    const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `${filename}-${new Date().toISOString().split('T')[0]}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 导出文章为 Markdown 格式
export function exportArticlesToMarkdown(articles: any[]): void {
    if (articles.length === 0) {
        throw new Error('没有文章可导出');
    }

    const markdown = articles.map(article => {
        return `# ${article.title || '无标题'}

**关键词:** ${article.keywords || '无'}
**模板:** ${article.template || '默认'}
**状态:** ${article.status || '未知'}
**创建时间:** ${article.created_at || '未知'}

---

${article.content || '无内容'}

---
---

`;
    }).join('\n');

    const blob = new Blob([markdown], { type: 'text/markdown;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `articles-${new Date().toISOString().split('T')[0]}.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 导出主题为文本格式
export function exportTopicsToText(topics: any[]): void {
    if (topics.length === 0) {
        throw new Error('没有主题可导出');
    }

    const text = topics.map((topic, index) => {
        return `${index + 1}. ${topic.title}
   描述: ${topic.description || '无'}
   关键词: ${topic.keywords || '无'}
   分类: ${topic.category || '未分类'}
   状态: ${topic.used ? '已使用' : '未使用'}
`;
    }).join('\n');

    const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `topics-${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 导出关键词为文本格式
export function exportKeywordsToText(keywords: any[]): void {
    if (keywords.length === 0) {
        throw new Error('没有关键词可导出');
    }

    // 按分组组织关键词
    const grouped: Record<string, any[]> = {};
    for (const kw of keywords) {
        const group = kw.group_name || '未分组';
        if (!grouped[group]) grouped[group] = [];
        grouped[group].push(kw);
    }

    let text = '';
    for (const [group, kws] of Object.entries(grouped)) {
        text += `## ${group}\n`;
        text += kws.map(k => `- ${k.keyword} (使用次数: ${k.use_count})`).join('\n');
        text += '\n\n';
    }

    const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `keywords-${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 验证导入数据格式
export function validateImportData(data: any): { valid: boolean; error?: string } {
    if (!data || typeof data !== 'object') {
        return { valid: false, error: '无效的数据格式' };
    }

    if (!data.version) {
        return { valid: false, error: '缺少版本信息' };
    }

    if (!data.data) {
        return { valid: false, error: '缺少数据内容' };
    }

    // v1.0.0 必需的表
    const requiredTables = ['users', 'wordpress_sites', 'articles', 'ai_settings'];
    for (const table of requiredTables) {
        if (!Array.isArray(data.data[table])) {
            return { valid: false, error: `缺少或无效的表: ${table}` };
        }
    }

    return { valid: true };
}

// 导入数据（覆盖模式）
export async function importData(
    data: ExportData,
    options: { clearExisting: boolean } = { clearExisting: true }
): Promise<{ success: boolean; message: string; stats: Record<string, number> }> {
    try {
        const stats: Record<string, number> = {};

        if (options.clearExisting) {
            // 清除现有数据
            await Promise.all([
                db.users.clear(),
                db.wordpress_sites.clear(),
                db.articles.clear(),
                db.ai_settings.clear(),
                db.article_templates.clear(),
                db.keywords.clear(),
                db.topics.clear(),
            ]);
        }

        // 导入用户
        if (data.data.users?.length > 0) {
            await db.users.bulkPut(data.data.users);
            stats.users = data.data.users.length;
        }

        // 导入站点
        if (data.data.wordpress_sites?.length > 0) {
            await db.wordpress_sites.bulkPut(data.data.wordpress_sites);
            stats.wordpress_sites = data.data.wordpress_sites.length;
        }

        // 导入文章
        if (data.data.articles?.length > 0) {
            await db.articles.bulkPut(data.data.articles);
            stats.articles = data.data.articles.length;
        }

        // 导入 AI 设置
        if (data.data.ai_settings?.length > 0) {
            await db.ai_settings.bulkPut(data.data.ai_settings);
            stats.ai_settings = data.data.ai_settings.length;
        }

        // 导入模板 (v2.0.0+)
        if (data.data.article_templates?.length > 0) {
            await db.article_templates.bulkPut(data.data.article_templates);
            stats.article_templates = data.data.article_templates.length;
        }

        // 导入关键词 (v2.0.0+)
        if (data.data.keywords?.length > 0) {
            await db.keywords.bulkPut(data.data.keywords);
            stats.keywords = data.data.keywords.length;
        }

        // 导入主题 (v2.0.0+)
        if (data.data.topics?.length > 0) {
            await db.topics.bulkPut(data.data.topics);
            stats.topics = data.data.topics.length;
        }

        return {
            success: true,
            message: '数据导入成功',
            stats,
        };
    } catch (error) {
        return {
            success: false,
            message: error instanceof Error ? error.message : '导入失败',
            stats: {},
        };
    }
}

// 读取导入文件
export function readImportFile(file: File): Promise<ExportData> {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();

        reader.onload = (e) => {
            try {
                const content = e.target?.result as string;
                const data = JSON.parse(content);
                resolve(data);
            } catch (error) {
                reject(new Error('无法解析文件内容'));
            }
        };

        reader.onerror = () => {
            reject(new Error('读取文件失败'));
        };

        reader.readAsText(file);
    });
}

// 获取数据统计
export async function getDataStats(): Promise<Record<string, number>> {
    const [users, sites, articles, settings, templates, keywords, topics] = await Promise.all([
        db.users.count(),
        db.wordpress_sites.count(),
        db.articles.count(),
        db.ai_settings.count(),
        db.article_templates.count(),
        db.keywords.count(),
        db.topics.count(),
    ]);

    return {
        users,
        wordpress_sites: sites,
        articles,
        ai_settings: settings,
        article_templates: templates,
        keywords,
        topics,
    };
}

// 获取用于显示的表名映射
export const TABLE_NAMES: Record<string, string> = {
    users: '用户',
    wordpress_sites: '站点',
    articles: '文章',
    ai_settings: 'AI 设置',
    article_templates: '模板',
    keywords: '关键词',
    topics: '主题',
};
