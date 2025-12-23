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
    };
}

// 导出所有数据
export async function exportAllData(): Promise<ExportData> {
    const [users, wordpress_sites, articles, ai_settings] = await Promise.all([
        db.users.toArray(),
        db.wordpress_sites.toArray(),
        db.articles.toArray(),
        db.ai_settings.toArray(),
    ]);

    return {
        version: '1.0.0',
        exportedAt: new Date().toISOString(),
        data: {
            users,
            wordpress_sites,
            articles,
            ai_settings,
        },
    };
}

// 下载导出文件
export function downloadExportFile(data: ExportData): void {
    const json = JSON.stringify(data, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `wordpress-cms-backup-${new Date().toISOString().split('T')[0]}.json`;
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
            ]);
        }

        // 导入用户
        if (data.data.users.length > 0) {
            await db.users.bulkPut(data.data.users);
            stats.users = data.data.users.length;
        }

        // 导入站点
        if (data.data.wordpress_sites.length > 0) {
            await db.wordpress_sites.bulkPut(data.data.wordpress_sites);
            stats.wordpress_sites = data.data.wordpress_sites.length;
        }

        // 导入文章
        if (data.data.articles.length > 0) {
            await db.articles.bulkPut(data.data.articles);
            stats.articles = data.data.articles.length;
        }

        // 导入 AI 设置
        if (data.data.ai_settings.length > 0) {
            await db.ai_settings.bulkPut(data.data.ai_settings);
            stats.ai_settings = data.data.ai_settings.length;
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
    const [users, sites, articles, settings] = await Promise.all([
        db.users.count(),
        db.wordpress_sites.count(),
        db.articles.count(),
        db.ai_settings.count(),
    ]);

    return {
        users,
        wordpress_sites: sites,
        articles,
        ai_settings: settings,
    };
}
