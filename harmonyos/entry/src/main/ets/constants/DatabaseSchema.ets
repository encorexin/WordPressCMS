// 数据库 Schema 常量 — 表名、建表 SQL、版本号
// 运行时使用 relationalStore.SecurityLevel.S1

export class DatabaseSchema {
  static readonly DB_NAME: string = 'WordPressCMS.db'
  static readonly DB_VERSION: number = 2
  static readonly LEGACY_SCHEMA_VERSION: number = 1
  static readonly SENSITIVE_FIELD_COLUMNS: string[] = [
    'wordpress_sites.app_password',
    'ai_settings.api_key',
    'ai_settings.image_api_key'
  ]
  static readonly SENSITIVE_FIELD_MIGRATION_NOTE: string =
    '阶段 03 起新写入统一使用带前缀的字段密文，读取继续兼容旧明文与旧 JSON 密文，暂不做静默回写迁移。'

  // 表名
  static readonly TABLE_USERS: string = 'users'
  static readonly TABLE_SITES: string = 'wordpress_sites'
  static readonly TABLE_ARTICLES: string = 'articles'
  static readonly TABLE_AI_SETTINGS: string = 'ai_settings'
  static readonly TABLE_TEMPLATES: string = 'article_templates'
  static readonly TABLE_KEYWORDS: string = 'keywords'
  static readonly TABLE_TOPICS: string = 'topics'
  static readonly TABLE_VERSIONS: string = 'article_versions'
  static readonly TABLE_SCHEMA_METADATA: string = 'schema_metadata'
  static readonly META_KEY_SCHEMA_VERSION: string = 'schema_version'

  // 建表 SQL
  static readonly SQL_CREATE_USERS: string =
    'CREATE TABLE IF NOT EXISTS users (' +
    'id TEXT PRIMARY KEY, ' +
    'email TEXT NOT NULL UNIQUE, ' +
    'password_hash TEXT NOT NULL, ' +
    'role TEXT DEFAULT \'user\', ' +
    'created_at TEXT NOT NULL)'

  static readonly SQL_CREATE_SITES: string =
    'CREATE TABLE IF NOT EXISTS wordpress_sites (' +
    'id TEXT PRIMARY KEY, ' +
    'user_id TEXT NOT NULL, ' +
    'site_name TEXT NOT NULL, ' +
    'site_url TEXT NOT NULL, ' +
    'username TEXT NOT NULL, ' +
    'app_password TEXT NOT NULL, ' +
    'status TEXT DEFAULT \'active\', ' +
    'created_at TEXT NOT NULL, ' +
    'updated_at TEXT NOT NULL)'

  static readonly SQL_CREATE_ARTICLES: string =
    'CREATE TABLE IF NOT EXISTS articles (' +
    'id TEXT PRIMARY KEY, ' +
    'user_id TEXT NOT NULL, ' +
    'site_id TEXT, ' +
    'title TEXT NOT NULL, ' +
    'content TEXT, ' +
    'keywords TEXT, ' +
    'template TEXT, ' +
    'status TEXT DEFAULT \'draft\', ' +
    'wordpress_post_id TEXT, ' +
    'word_count INTEGER DEFAULT 0, ' +
    'tokens_used INTEGER DEFAULT 0, ' +
    'created_at TEXT NOT NULL, ' +
    'updated_at TEXT NOT NULL)'

  static readonly SQL_CREATE_AI_SETTINGS: string =
    'CREATE TABLE IF NOT EXISTS ai_settings (' +
    'id TEXT PRIMARY KEY, ' +
    'user_id TEXT NOT NULL, ' +
    'name TEXT NOT NULL, ' +
    'is_default INTEGER DEFAULT 0, ' +
    'api_endpoint TEXT, ' +
    'api_key TEXT, ' +
    'model TEXT, ' +
    'system_prompt TEXT, ' +
    'image_provider TEXT, ' +
    'image_api_key TEXT, ' +
    'image_endpoint TEXT, ' +
    'image_model TEXT, ' +
    'image_enabled INTEGER DEFAULT 0, ' +
    'slug_model TEXT, ' +
    'slug_enabled INTEGER DEFAULT 1, ' +
    'tokens_used INTEGER DEFAULT 0, ' +
    'created_at TEXT NOT NULL, ' +
    'updated_at TEXT NOT NULL)'

  static readonly SQL_CREATE_TEMPLATES: string =
    'CREATE TABLE IF NOT EXISTS article_templates (' +
    'id TEXT PRIMARY KEY, ' +
    'user_id TEXT NOT NULL, ' +
    'name TEXT NOT NULL, ' +
    'description TEXT, ' +
    'system_prompt TEXT NOT NULL, ' +
    'created_at TEXT NOT NULL, ' +
    'updated_at TEXT NOT NULL)'

  static readonly SQL_CREATE_KEYWORDS: string =
    'CREATE TABLE IF NOT EXISTS keywords (' +
    'id TEXT PRIMARY KEY, ' +
    'user_id TEXT NOT NULL, ' +
    'keyword TEXT NOT NULL, ' +
    'group_name TEXT, ' +
    'use_count INTEGER DEFAULT 0, ' +
    'created_at TEXT NOT NULL)'

  static readonly SQL_CREATE_TOPICS: string =
    'CREATE TABLE IF NOT EXISTS topics (' +
    'id TEXT PRIMARY KEY, ' +
    'user_id TEXT NOT NULL, ' +
    'title TEXT NOT NULL, ' +
    'description TEXT, ' +
    'keywords TEXT, ' +
    'category TEXT, ' +
    'used INTEGER DEFAULT 0, ' +
    'created_at TEXT NOT NULL)'

  static readonly SQL_CREATE_VERSIONS: string =
    'CREATE TABLE IF NOT EXISTS article_versions (' +
    'id TEXT PRIMARY KEY, ' +
    'article_id TEXT NOT NULL, ' +
    'user_id TEXT NOT NULL, ' +
    'site_id TEXT, ' +
    'title TEXT, ' +
    'content TEXT, ' +
    'keywords TEXT, ' +
    'template TEXT, ' +
    'wordpress_post_id TEXT, ' +
    'status TEXT DEFAULT \'draft\', ' +
    'version_number INTEGER NOT NULL, ' +
    'created_at TEXT NOT NULL)'

  static readonly SQL_CREATE_SCHEMA_METADATA: string =
    'CREATE TABLE IF NOT EXISTS schema_metadata (' +
    'meta_key TEXT PRIMARY KEY, ' +
    'meta_value INTEGER NOT NULL, ' +
    'updated_at TEXT NOT NULL)'

  static readonly SQL_ALTER_VERSIONS_ADD_SITE_ID: string =
    'ALTER TABLE article_versions ADD COLUMN site_id TEXT'

  static readonly SQL_ALTER_VERSIONS_ADD_WP_POST_ID: string =
    'ALTER TABLE article_versions ADD COLUMN wordpress_post_id TEXT'

  static readonly SQL_ALTER_VERSIONS_ADD_STATUS: string =
    'ALTER TABLE article_versions ADD COLUMN status TEXT DEFAULT \'draft\''

  static readonly SQL_ALTER_ARTICLES_ADD_WORD_COUNT: string =
    'ALTER TABLE articles ADD COLUMN word_count INTEGER DEFAULT 0'

  static readonly SQL_ALTER_ARTICLES_ADD_TOKENS_USED: string =
    'ALTER TABLE articles ADD COLUMN tokens_used INTEGER DEFAULT 0'

  static readonly SQL_ALTER_AI_SETTINGS_ADD_TOKENS_USED: string =
    'ALTER TABLE ai_settings ADD COLUMN tokens_used INTEGER DEFAULT 0'

  static readonly SQL_CREATE_INDEX_SITES_USER_ID: string =
    'CREATE INDEX IF NOT EXISTS idx_sites_user_id ON wordpress_sites(user_id)'

  static readonly SQL_CREATE_INDEX_ARTICLES_USER_ID: string =
    'CREATE INDEX IF NOT EXISTS idx_articles_user_id ON articles(user_id)'

  static readonly SQL_CREATE_INDEX_ARTICLES_SITE_ID: string =
    'CREATE INDEX IF NOT EXISTS idx_articles_site_id ON articles(site_id)'

  static readonly SQL_CREATE_INDEX_AI_SETTINGS_USER_ID: string =
    'CREATE INDEX IF NOT EXISTS idx_ai_settings_user_id ON ai_settings(user_id)'

  static readonly SQL_CREATE_INDEX_KEYWORDS_USER_GROUP: string =
    'CREATE INDEX IF NOT EXISTS idx_keywords_user_group ON keywords(user_id, group_name)'

  static readonly SQL_CREATE_INDEX_TOPICS_USER_CATEGORY: string =
    'CREATE INDEX IF NOT EXISTS idx_topics_user_category ON topics(user_id, category)'

  static readonly SQL_CREATE_INDEX_VERSIONS_ARTICLE_VERSION: string =
    'CREATE INDEX IF NOT EXISTS idx_versions_article_version ON article_versions(article_id, version_number)'

  // 所有建表 SQL 有序列表
  static readonly ALL_CREATE_TABLES: string[] = [
    DatabaseSchema.SQL_CREATE_USERS,
    DatabaseSchema.SQL_CREATE_SITES,
    DatabaseSchema.SQL_CREATE_ARTICLES,
    DatabaseSchema.SQL_CREATE_AI_SETTINGS,
    DatabaseSchema.SQL_CREATE_TEMPLATES,
    DatabaseSchema.SQL_CREATE_KEYWORDS,
    DatabaseSchema.SQL_CREATE_TOPICS,
    DatabaseSchema.SQL_CREATE_VERSIONS,
    DatabaseSchema.SQL_CREATE_SCHEMA_METADATA
  ]

  static readonly VERSION_1_TO_2_MIGRATIONS: string[] = [
    DatabaseSchema.SQL_ALTER_VERSIONS_ADD_SITE_ID,
    DatabaseSchema.SQL_ALTER_VERSIONS_ADD_WP_POST_ID,
    DatabaseSchema.SQL_ALTER_VERSIONS_ADD_STATUS,
    DatabaseSchema.SQL_ALTER_ARTICLES_ADD_WORD_COUNT,
    DatabaseSchema.SQL_ALTER_ARTICLES_ADD_TOKENS_USED,
    DatabaseSchema.SQL_ALTER_AI_SETTINGS_ADD_TOKENS_USED,
    DatabaseSchema.SQL_CREATE_INDEX_SITES_USER_ID,
    DatabaseSchema.SQL_CREATE_INDEX_ARTICLES_USER_ID,
    DatabaseSchema.SQL_CREATE_INDEX_ARTICLES_SITE_ID,
    DatabaseSchema.SQL_CREATE_INDEX_AI_SETTINGS_USER_ID,
    DatabaseSchema.SQL_CREATE_INDEX_KEYWORDS_USER_GROUP,
    DatabaseSchema.SQL_CREATE_INDEX_TOPICS_USER_CATEGORY,
    DatabaseSchema.SQL_CREATE_INDEX_VERSIONS_ARTICLE_VERSION
  ]
}
