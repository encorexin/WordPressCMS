import Dexie, { type EntityTable } from "dexie";

import type {
    AISettings,
    ArticleTemplate,
    ArticleVersion,
    Keyword,
    LocalArticle,
    LocalUser,
    LocalWordPressSite,
    Topic,
} from "./models";

type LegacyDatabase = Dexie & {
    users: EntityTable<LocalUser, "id">;
    wordpress_sites: EntityTable<LocalWordPressSite, "id">;
    articles: EntityTable<LocalArticle, "id">;
    ai_settings: EntityTable<AISettings, "id">;
    article_templates: EntityTable<ArticleTemplate, "id">;
    keywords: EntityTable<Keyword, "id">;
    topics: EntityTable<Topic, "id">;
    article_versions: EntityTable<ArticleVersion, "id">;
};

// 保留旧版 Dexie 全表定义，仅供迁移与明文兼容导出使用。
const legacyDb = new Dexie("WordPressCMS") as LegacyDatabase;

legacyDb.version(7).stores({
    users: "id, email, role, created_at",
    wordpress_sites: "id, user_id, site_name, status, created_at",
    articles: "id, user_id, site_id, title, status, created_at",
    ai_settings: "id, user_id, name, is_default",
    article_templates: "id, user_id, name, created_at",
    keywords: "id, user_id, keyword, group_name, use_count",
    topics: "id, user_id, title, category, used, created_at",
    article_versions: "id, article_id, user_id, version_number, created_at",
});

export { legacyDb };
