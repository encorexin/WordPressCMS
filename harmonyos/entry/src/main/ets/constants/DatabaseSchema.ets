// 数据库 Schema 常量 — 表名、建表 SQL、版本号
// 运行时使用 relationalStore.SecurityLevel.S1

export class DatabaseSchema {
  static readonly DB_NAME: string = 'WordPressCMS.db'
  static readonly DB_VERSION: number = 1

  // 表名
  static readonly TABLE_USERS: string = 'users'
  static readonly TABLE_SITES: string = 'wordpress_sites'
  static readonly TABLE_ARTICLES: string = 'articles'
  static readonly TABLE_AI_SETTINGS: string = 'ai_settings'
  static readonly TABLE_TEMPLATES: string = 'article_templates'
  static readonly TABLE_KEYWORDS: string = 'keywords'
  static readonly TABLE_TOPICS: string = 'topics'
  static readonly TABLE_VERSIONS: string = 'article_versions'

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

  static readonly SQL_ALTER_VERSIONS_ADD_SITE_ID: string =
    'ALTER TABLE article_versions ADD COLUMN site_id TEXT'

  static readonly SQL_ALTER_VERSIONS_ADD_WP_POST_ID: string =
    'ALTER TABLE article_versions ADD COLUMN wordpress_post_id TEXT'

  static readonly SQL_ALTER_VERSIONS_ADD_STATUS: string =
    'ALTER TABLE article_versions ADD COLUMN status TEXT DEFAULT \'draft\''

  // 所有建表 SQL 有序列表
  static readonly ALL_CREATE_TABLES: string[] = [
    DatabaseSchema.SQL_CREATE_USERS,
    DatabaseSchema.SQL_CREATE_SITES,
    DatabaseSchema.SQL_CREATE_ARTICLES,
    DatabaseSchema.SQL_CREATE_AI_SETTINGS,
    DatabaseSchema.SQL_CREATE_TEMPLATES,
    DatabaseSchema.SQL_CREATE_KEYWORDS,
    DatabaseSchema.SQL_CREATE_TOPICS,
    DatabaseSchema.SQL_CREATE_VERSIONS
  ]

  static readonly ALL_SAFE_ALTERS: string[] = [
    DatabaseSchema.SQL_ALTER_VERSIONS_ADD_SITE_ID,
    DatabaseSchema.SQL_ALTER_VERSIONS_ADD_WP_POST_ID,
    DatabaseSchema.SQL_ALTER_VERSIONS_ADD_STATUS
  ]
}
