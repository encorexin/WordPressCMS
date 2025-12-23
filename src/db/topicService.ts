import { db, generateId, getTimestamp, type Topic } from './database';
export type { Topic };

// 获取用户的所有主题
export async function getTopics(userId: string): Promise<Topic[]> {
    return await db.topics
        .where('user_id')
        .equals(userId)
        .reverse()
        .sortBy('created_at');
}

// 获取未使用的主题
export async function getUnusedTopics(userId: string): Promise<Topic[]> {
    return await db.topics
        .where('user_id')
        .equals(userId)
        .filter(topic => !topic.used)
        .reverse()
        .sortBy('created_at');
}

// 按分类获取主题
export async function getTopicsByCategory(userId: string): Promise<Record<string, Topic[]>> {
    const topics = await getTopics(userId);
    const grouped: Record<string, Topic[]> = {};

    for (const topic of topics) {
        const category = topic.category || '未分类';
        if (!grouped[category]) {
            grouped[category] = [];
        }
        grouped[category].push(topic);
    }

    return grouped;
}

// 创建主题
export async function createTopic(
    userId: string,
    data: { title: string; description: string; keywords: string; category: string }
): Promise<Topic> {
    const topic: Topic = {
        id: generateId(),
        user_id: userId,
        title: data.title,
        description: data.description,
        keywords: data.keywords,
        category: data.category || '未分类',
        used: false,
        created_at: getTimestamp(),
    };

    await db.topics.add(topic);
    return topic;
}

// 批量创建主题
export async function createTopicsBatch(
    userId: string,
    topics: { title: string; description: string; keywords: string; category: string }[]
): Promise<number> {
    let created = 0;
    for (const data of topics) {
        if (data.title.trim()) {
            await createTopic(userId, data);
            created++;
        }
    }
    return created;
}

// 更新主题
export async function updateTopic(
    topicId: string,
    data: Partial<{ title: string; description: string; keywords: string; category: string; used: boolean }>
): Promise<Topic | null> {
    await db.topics.update(topicId, data);
    return await db.topics.get(topicId) ?? null;
}

// 标记主题为已使用
export async function markTopicAsUsed(topicId: string): Promise<void> {
    await db.topics.update(topicId, { used: true });
}

// 删除主题
export async function deleteTopic(topicId: string): Promise<void> {
    await db.topics.delete(topicId);
}

// 删除所有已使用的主题
export async function deleteUsedTopics(userId: string): Promise<number> {
    const usedTopics = await db.topics
        .where('user_id')
        .equals(userId)
        .filter(topic => topic.used)
        .toArray();

    await db.topics.bulkDelete(usedTopics.map(t => t.id));
    return usedTopics.length;
}

// 获取所有分类
export async function getCategories(userId: string): Promise<string[]> {
    const topics = await getTopics(userId);
    const categories = new Set<string>();

    for (const topic of topics) {
        categories.add(topic.category || '未分类');
    }

    return Array.from(categories);
}

// 搜索主题
export async function searchTopics(userId: string, query: string): Promise<Topic[]> {
    const topics = await getTopics(userId);
    const lowerQuery = query.toLowerCase();
    return topics.filter(topic =>
        topic.title.toLowerCase().includes(lowerQuery) ||
        topic.description.toLowerCase().includes(lowerQuery) ||
        topic.keywords.toLowerCase().includes(lowerQuery)
    );
}
