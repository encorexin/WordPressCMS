import {
  type AISettings,
  type ArticleTemplate,
  db,
  type Keyword,
  type LocalArticle,
  type LocalUser,
  type LocalWordPressSite,
  type Topic,
} from "./database";
import { exportEncryptedData, importEncryptedData } from "./encryptedApi";
import { hasEncryptionKey } from "./encryptedDatabase";

// 数据库记录联合类型
type DatabaseRecord =
  | LocalUser
  | LocalWordPressSite
  | LocalArticle
  | AISettings
  | ArticleTemplate
  | Keyword
  | Topic;

// 未加密的导出数据结构
export interface ExportDataPlain {
  users: LocalUser[];
  wordpress_sites: LocalWordPressSite[];
  articles: LocalArticle[];
  ai_settings: AISettings[];
  article_templates: ArticleTemplate[];
  keywords: Keyword[];
  topics: Topic[];
}

// 导出数据结构
export interface ExportData {
  version: string;
  exportedAt: string;
  encrypted: boolean;
  data: ExportDataPlain | Record<string, unknown>; // 加密数据时存储为 Record
}

// 单独导出结构
export interface SingleExportData {
  type: string;
  exportedAt: string;
  count: number;
  encrypted: boolean;
  data: DatabaseRecord[];
}

// 导出所有数据
export async function exportAllData(userId?: string, encrypt: boolean = true): Promise<ExportData> {
  // 如果用户选择加密导出且已登录解密
  if (encrypt && userId && hasEncryptionKey()) {
    const encryptedData = await exportEncryptedData(userId);
    return {
      version: "3.0.0",
      exportedAt: new Date().toISOString(),
      encrypted: true,
      data: encryptedData.data,
    };
  }

  // 导出未加密数据（向后兼容或用户选择不加密）
  const [users, wordpress_sites, articles, ai_settings, article_templates, keywords, topics] =
    await Promise.all([
      db.users.toArray(),
      db.wordpress_sites.toArray(),
      db.articles.toArray(),
      db.ai_settings.toArray(),
      db.article_templates.toArray(),
      db.keywords.toArray(),
      db.topics.toArray(),
    ]);

  return {
    version: "3.0.0",
    exportedAt: new Date().toISOString(),
    encrypted: false,
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

// 导出单个表数据（明文，便于查看）
export async function exportTableData(
  tableName: string,
  userId?: string
): Promise<SingleExportData> {
  // 如果用户已登录且已解密，从加密存储获取
  if (userId && hasEncryptionKey()) {
    const {
      getEncryptedArticles,
      getEncryptedSites,
      getEncryptedTemplates,
      getEncryptedKeywords,
      getEncryptedTopics,
      getEncryptedAISettings,
    } = await import("./encryptedDatabase");

    let data: DatabaseRecord[] = [];
    switch (tableName) {
      case "articles":
        data = await getEncryptedArticles(userId);
        break;
      case "wordpress_sites":
        data = await getEncryptedSites(userId);
        break;
      case "article_templates":
        data = await getEncryptedTemplates(userId);
        break;
      case "keywords":
        data = await getEncryptedKeywords(userId);
        break;
      case "topics":
        data = await getEncryptedTopics(userId);
        break;
      case "ai_settings": {
        const settings = await getEncryptedAISettings(userId);
        data = settings ? [settings] : [];
        break;
      }
      default:
        throw new Error(`不支持的表: ${tableName}`);
    }

    return {
      type: tableName,
      exportedAt: new Date().toISOString(),
      count: data.length,
      encrypted: false, // 单个表导出为明文（便于查看）
      data,
    };
  }

  // 否则从旧数据库获取（向后兼容）
  let data: DatabaseRecord[] = [];
  switch (tableName) {
    case "articles":
      data = await db.articles.toArray();
      break;
    case "wordpress_sites":
      data = await db.wordpress_sites.toArray();
      break;
    case "article_templates":
      data = await db.article_templates.toArray();
      break;
    case "keywords":
      data = await db.keywords.toArray();
      break;
    case "topics":
      data = await db.topics.toArray();
      break;
    case "ai_settings":
      data = await db.ai_settings.toArray();
      break;
    default:
      throw new Error(`不支持的表: ${tableName}`);
  }

  return {
    type: tableName,
    exportedAt: new Date().toISOString(),
    count: data.length,
    encrypted: false,
    data,
  };
}

// 加密导出单个表数据
export async function exportEncryptedTableData(
  tableName: string,
  userId?: string
): Promise<ExportData> {
  if (!userId || !hasEncryptionKey()) {
    throw new Error("未登录或数据未解密，无法导出加密数据");
  }

  const {
    getEncryptedArticles,
    getEncryptedSites,
    getEncryptedTemplates,
    getEncryptedKeywords,
    getEncryptedTopics,
    getEncryptedAISettings,
  } = await import("./encryptedDatabase");

  let data: DatabaseRecord[] = [];
  switch (tableName) {
    case "articles":
      data = await getEncryptedArticles(userId);
      break;
    case "wordpress_sites":
      data = await getEncryptedSites(userId);
      break;
    case "article_templates":
      data = await getEncryptedTemplates(userId);
      break;
    case "keywords":
      data = await getEncryptedKeywords(userId);
      break;
    case "topics":
      data = await getEncryptedTopics(userId);
      break;
    case "ai_settings": {
      const settings = await getEncryptedAISettings(userId);
      data = settings ? [settings] : [];
      break;
    }
    default:
      throw new Error(`不支持的表: ${tableName}`);
  }

  // 使用加密格式导出
  const encryptedPayload = {
    [tableName]: data,
  };

  return {
    version: "3.0.0",
    exportedAt: new Date().toISOString(),
    encrypted: true,
    data: encryptedPayload,
  };
}

// 下载 JSON 导出文件
export function downloadExportFile(data: ExportData | SingleExportData, filename?: string): void {
  const json = JSON.stringify(data, null, 2);
  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);

  const defaultFilename =
    "type" in data
      ? `${data.type}-${new Date().toISOString().split("T")[0]}.json`
      : `wordpress-cms-backup-${new Date().toISOString().split("T")[0]}.json`;

  const a = document.createElement("a");
  a.href = url;
  a.download = filename || defaultFilename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 导出为 CSV 格式
export function exportToCSV(data: Record<string, unknown>[], filename: string): void {
  if (data.length === 0) {
    throw new Error("没有数据可导出");
  }

  // 获取所有列名
  const headers = Object.keys(data[0]);

  // 构建 CSV 内容
  const csvContent = [
    headers.join(","),
    ...data.map((row) =>
      headers
        .map((header) => {
          const value = row[header];
          // 处理特殊字符
          if (value === null || value === undefined) return "";
          const str = String(value);
          // 如果包含逗号、引号或换行，用引号包裹
          if (str.includes(",") || str.includes('"') || str.includes("\n")) {
            return `"${str.replace(/"/g, '""')}"`;
          }
          return str;
        })
        .join(",")
    ),
  ].join("\n");

  const blob = new Blob(["\ufeff" + csvContent], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);

  const a = document.createElement("a");
  a.href = url;
  a.download = `${filename}-${new Date().toISOString().split("T")[0]}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 导出文章为 Markdown 格式
export function exportArticlesToMarkdown(articles: LocalArticle[]): void {
  if (articles.length === 0) {
    throw new Error("没有文章可导出");
  }

  const markdown = articles
    .map((article) => {
      return `# ${article.title || "无标题"}

**关键词:** ${article.keywords || "无"}
**模板:** ${article.template || "默认"}
**状态:** ${article.status || "未知"}
**创建时间:** ${article.created_at || "未知"}

---

${article.content || "无内容"}

---
---

`;
    })
    .join("\n");

  const blob = new Blob([markdown], { type: "text/markdown;charset=utf-8" });
  const url = URL.createObjectURL(blob);

  const a = document.createElement("a");
  a.href = url;
  a.download = `articles-${new Date().toISOString().split("T")[0]}.md`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 导出主题为文本格式
export function exportTopicsToText(topics: Topic[]): void {
  if (topics.length === 0) {
    throw new Error("没有主题可导出");
  }

  const text = topics
    .map((topic, index) => {
      return `${index + 1}. ${topic.title}
   描述: ${topic.description || "无"}
   关键词: ${topic.keywords || "无"}
   分类: ${topic.category || "未分类"}
   状态: ${topic.used ? "已使用" : "未使用"}
`;
    })
    .join("\n");

  const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);

  const a = document.createElement("a");
  a.href = url;
  a.download = `topics-${new Date().toISOString().split("T")[0]}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 导出关键词为文本格式
export function exportKeywordsToText(keywords: Keyword[]): void {
  if (keywords.length === 0) {
    throw new Error("没有关键词可导出");
  }

  // 按分组组织关键词
  const grouped: Record<string, Keyword[]> = {};
  for (const kw of keywords) {
    const group = kw.group_name || "未分组";
    if (!grouped[group]) grouped[group] = [];
    grouped[group].push(kw);
  }

  let text = "";
  for (const [group, kws] of Object.entries(grouped)) {
    text += `## ${group}\n`;
    text += kws.map((k) => `- ${k.keyword} (使用次数: ${k.use_count})`).join("\n");
    text += "\n\n";
  }

  const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);

  const a = document.createElement("a");
  a.href = url;
  a.download = `keywords-${new Date().toISOString().split("T")[0]}.txt`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 下载单篇文章
export function downloadSingleArticle(
  article: {
    title: string;
    content: string;
    keywords?: string;
    template?: string;
    status?: string;
    created_at?: string;
  },
  format: "markdown" | "txt" | "html" = "markdown"
): void {
  let content: string;
  let mimeType: string;
  let extension: string;

  const safeTitle = (article.title || "无标题").replace(/[<>:"/\\|?*]/g, "_");

  switch (format) {
    case "markdown":
      content = `# ${article.title || "无标题"}

**关键词:** ${article.keywords || "无"}
**模板:** ${article.template || "默认"}
**状态:** ${article.status || "草稿"}
**创建时间:** ${article.created_at || "未知"}

---

${article.content || ""}
`;
      mimeType = "text/markdown;charset=utf-8";
      extension = "md";
      break;

    case "txt":
      content = `${article.title || "无标题"}
========================================

关键词: ${article.keywords || "无"}
模板: ${article.template || "默认"}
状态: ${article.status || "草稿"}
创建时间: ${article.created_at || "未知"}

----------------------------------------

${article.content || ""}
`;
      mimeType = "text/plain;charset=utf-8";
      extension = "txt";
      break;

    case "html":
      content = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${article.title || "无标题"}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; }
        h1 { border-bottom: 2px solid #333; padding-bottom: 10px; }
        .meta { color: #666; font-size: 0.9em; margin-bottom: 20px; }
        .content { white-space: pre-wrap; }
    </style>
</head>
<body>
    <h1>${article.title || "无标题"}</h1>
    <div class="meta">
        <p>关键词: ${article.keywords || "无"} | 模板: ${article.template || "默认"} | 状态: ${article.status || "草稿"}</p>
        <p>创建时间: ${article.created_at || "未知"}</p>
    </div>
    <hr>
    <div class="content">${article.content || ""}</div>
</body>
</html>`;
      mimeType = "text/html;charset=utf-8";
      extension = "html";
      break;
  }

  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);

  const a = document.createElement("a");
  a.href = url;
  a.download = `${safeTitle}.${extension}`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 导出 AI 设置（包含生图 API 配置）
export async function exportAISettingsToJSON(userId?: string): Promise<void> {
  let ai_settings: AISettings[] = [];

  if (userId && hasEncryptionKey()) {
    const { getEncryptedAISettings } = await import("./encryptedDatabase");
    const settings = await getEncryptedAISettings(userId);
    if (settings) {
      ai_settings = [settings];
    }
  } else {
    ai_settings = await db.ai_settings.toArray();
  }

  // 过滤敏感信息，只保留部分 API key 用于参考
  const safeSettings = ai_settings.map((setting) => ({
    ...setting,
    api_key: setting.api_key ? `${setting.api_key.slice(0, 8)}...` : "",
    image_api_key: setting.image_api_key ? `${setting.image_api_key.slice(0, 8)}...` : "",
  }));

  const exportData = {
    type: "ai_settings",
    exportedAt: new Date().toISOString(),
    count: safeSettings.length,
    note: "API Key 已部分隐藏，导入后需要重新输入完整的 API Key",
    data: safeSettings,
  };

  const json = JSON.stringify(exportData, null, 2);
  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);

  const a = document.createElement("a");
  a.href = url;
  a.download = `ai-settings-${new Date().toISOString().split("T")[0]}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 导出完整 AI 设置（包含完整 API key，谨慎使用）
export async function exportAISettingsFull(userId?: string): Promise<object> {
  if (userId && hasEncryptionKey()) {
    const { getEncryptedAISettings } = await import("./encryptedDatabase");
    const settings = await getEncryptedAISettings(userId);
    return settings || {};
  }
  const settings = await db.ai_settings.toArray();
  return settings[0] || {};
}

// 读取导入文件
export function readImportFile(file: File): Promise<ExportData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target?.result as string);
        resolve(data);
      } catch (error) {
        reject(new Error("文件格式错误，无法解析 JSON"));
      }
    };
    reader.onerror = () => reject(new Error("读取文件失败"));
    reader.readAsText(file);
  });
}

// 验证导入数据
export function validateImportData(data: unknown): data is ExportData {
  if (typeof data !== "object" || data === null) {
    return false;
  }

  const exportData = data as ExportData;

  // 检查必要字段
  if (!exportData.version || !exportData.exportedAt) {
    return false;
  }

  // 检查是否为加密数据
  if (exportData.encrypted && exportData.data) {
    return true;
  }

  // 检查未加密数据的结构
  if (!exportData.data || typeof exportData.data !== "object") {
    return false;
  }

  return true;
}

// 导入数据
export async function importData(
  data: ExportData,
  userId?: string,
  options: { merge?: boolean; overwrite?: boolean } = {}
): Promise<{ success: boolean; imported: number; errors: string[] }> {
  const errors: string[] = [];
  let imported = 0;

  try {
    // 如果是加密数据且用户已登录
    if (data.encrypted && userId && hasEncryptionKey()) {
      await importEncryptedData(userId, {
        version: 1,
        timestamp: data.exportedAt,
        data: data.data as Record<string, unknown>,
      });
      return { success: true, imported: 1, errors: [] };
    }

    // 否则按未加密数据处理（向后兼容）
    const { merge = true, overwrite = false } = options;
    const plainData = data.data as ExportDataPlain;

    // 导入文章
    if (plainData.articles?.length) {
      for (const article of plainData.articles) {
        try {
          if (overwrite) {
            await db.articles.put(article);
          } else if (merge) {
            const existing = await db.articles.get(article.id);
            if (!existing) {
              await db.articles.add(article);
              imported++;
            }
          } else {
            await db.articles.add(article);
            imported++;
          }
        } catch (error) {
          errors.push(`文章 "${article.title}" 导入失败`);
        }
      }
    }

    // 导入站点
    if (plainData.wordpress_sites?.length) {
      for (const site of plainData.wordpress_sites) {
        try {
          if (overwrite) {
            await db.wordpress_sites.put(site);
          } else if (merge) {
            const existing = await db.wordpress_sites.get(site.id);
            if (!existing) {
              await db.wordpress_sites.add(site);
              imported++;
            }
          } else {
            await db.wordpress_sites.add(site);
            imported++;
          }
        } catch (error) {
          errors.push(`站点 "${site.site_name}" 导入失败`);
        }
      }
    }

    // 导入模板
    if (plainData.article_templates?.length) {
      for (const template of plainData.article_templates) {
        try {
          if (overwrite) {
            await db.article_templates.put(template);
          } else if (merge) {
            const existing = await db.article_templates.get(template.id);
            if (!existing) {
              await db.article_templates.add(template);
              imported++;
            }
          } else {
            await db.article_templates.add(template);
            imported++;
          }
        } catch (error) {
          errors.push(`模板 "${template.name}" 导入失败`);
        }
      }
    }

    // 导入关键词
    if (plainData.keywords?.length) {
      for (const keyword of plainData.keywords) {
        try {
          if (overwrite) {
            await db.keywords.put(keyword);
          } else if (merge) {
            const existing = await db.keywords.get(keyword.id);
            if (!existing) {
              await db.keywords.add(keyword);
              imported++;
            }
          } else {
            await db.keywords.add(keyword);
            imported++;
          }
        } catch (error) {
          errors.push(`关键词 "${keyword.keyword}" 导入失败`);
        }
      }
    }

    // 导入主题
    if (plainData.topics?.length) {
      for (const topic of plainData.topics) {
        try {
          if (overwrite) {
            await db.topics.put(topic);
          } else if (merge) {
            const existing = await db.topics.get(topic.id);
            if (!existing) {
              await db.topics.add(topic);
              imported++;
            }
          } else {
            await db.topics.add(topic);
            imported++;
          }
        } catch (error) {
          errors.push(`主题 "${topic.title}" 导入失败`);
        }
      }
    }

    // 导入 AI 设置
    if (plainData.ai_settings?.length) {
      for (const setting of plainData.ai_settings) {
        try {
          if (overwrite) {
            await db.ai_settings.put(setting);
          } else if (merge) {
            const existing = await db.ai_settings.get(setting.id);
            if (!existing) {
              await db.ai_settings.add(setting);
              imported++;
            }
          } else {
            await db.ai_settings.add(setting);
            imported++;
          }
        } catch (error) {
          errors.push("AI 设置导入失败");
        }
      }
    }

    return { success: true, imported, errors };
  } catch (error) {
    return {
      success: false,
      imported,
      errors: [...errors, (error as Error).message],
    };
  }
}

// 获取数据统计
export async function getDataStats(): Promise<Record<string, number>> {
  const [articles, sites, templates, keywords, topics, aiSettings] = await Promise.all([
    db.articles.count(),
    db.wordpress_sites.count(),
    db.article_templates.count(),
    db.keywords.count(),
    db.topics.count(),
    db.ai_settings.count(),
  ]);

  return {
    articles,
    wordpress_sites: sites,
    article_templates: templates,
    keywords,
    topics,
    ai_settings: aiSettings,
  };
}

// 表名映射
export const TABLE_NAMES: Record<string, string> = {
  articles: "文章",
  wordpress_sites: "WordPress 站点",
  article_templates: "文章模板",
  keywords: "关键词",
  topics: "主题",
  ai_settings: "AI 设置",
};

// 支持的导出格式
export const EXPORT_FORMATS = [
  { value: "json", label: "JSON (完整数据)" },
  { value: "csv", label: "CSV (表格数据)" },
  { value: "markdown", label: "Markdown (文章)" },
  { value: "txt", label: "文本 (关键词/主题)" },
] as const;
