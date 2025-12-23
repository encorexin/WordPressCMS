import { db, generateId, getTimestamp, type Keyword } from './database';
export type { Keyword };

// 获取用户的所有关键词
export async function getKeywords(userId: string): Promise<Keyword[]> {
    return await db.keywords
        .where('user_id')
        .equals(userId)
        .reverse()
        .sortBy('use_count');
}

// 按分组获取关键词
export async function getKeywordsByGroup(userId: string): Promise<Record<string, Keyword[]>> {
    const keywords = await getKeywords(userId);
    const grouped: Record<string, Keyword[]> = {};

    for (const kw of keywords) {
        const group = kw.group_name || '未分组';
        if (!grouped[group]) {
            grouped[group] = [];
        }
        grouped[group].push(kw);
    }

    return grouped;
}

// 获取所有分组名称
export async function getGroups(userId: string): Promise<string[]> {
    const keywords = await getKeywords(userId);
    const groups = new Set<string>();

    for (const kw of keywords) {
        groups.add(kw.group_name || '未分组');
    }

    return Array.from(groups);
}

// 创建关键词
export async function createKeyword(
    userId: string,
    data: { keyword: string; group_name?: string }
): Promise<Keyword> {
    // 检查是否已存在
    const existing = await db.keywords
        .where('user_id')
        .equals(userId)
        .filter(kw => kw.keyword === data.keyword)
        .first();

    if (existing) {
        throw new Error('关键词已存在');
    }

    const keyword: Keyword = {
        id: generateId(),
        user_id: userId,
        keyword: data.keyword,
        group_name: data.group_name || '未分组',
        use_count: 0,
        created_at: getTimestamp(),
    };

    await db.keywords.add(keyword);
    return keyword;
}

// 批量创建关键词
export async function createKeywordsBatch(
    userId: string,
    keywords: string[],
    groupName: string = '未分组'
): Promise<{ created: number; skipped: number }> {
    let created = 0;
    let skipped = 0;

    for (const kw of keywords) {
        const trimmed = kw.trim();
        if (!trimmed) continue;

        try {
            await createKeyword(userId, { keyword: trimmed, group_name: groupName });
            created++;
        } catch {
            skipped++;
        }
    }

    return { created, skipped };
}

// 更新关键词
export async function updateKeyword(
    keywordId: string,
    data: Partial<{ keyword: string; group_name: string }>
): Promise<Keyword | null> {
    await db.keywords.update(keywordId, data);
    return await db.keywords.get(keywordId) ?? null;
}

// 删除关键词
export async function deleteKeyword(keywordId: string): Promise<void> {
    await db.keywords.delete(keywordId);
}

// 删除分组下所有关键词
export async function deleteKeywordsByGroup(userId: string, groupName: string): Promise<number> {
    const keywords = await db.keywords
        .where('user_id')
        .equals(userId)
        .filter(kw => kw.group_name === groupName)
        .toArray();

    await db.keywords.bulkDelete(keywords.map(kw => kw.id));
    return keywords.length;
}

// 增加关键词使用次数
export async function incrementKeywordUsage(keywordId: string): Promise<void> {
    const keyword = await db.keywords.get(keywordId);
    if (keyword) {
        await db.keywords.update(keywordId, {
            use_count: keyword.use_count + 1,
        });
    }
}

// 搜索关键词
export async function searchKeywords(userId: string, query: string): Promise<Keyword[]> {
    const keywords = await getKeywords(userId);
    const lowerQuery = query.toLowerCase();
    return keywords.filter(kw =>
        kw.keyword.toLowerCase().includes(lowerQuery)
    );
}
