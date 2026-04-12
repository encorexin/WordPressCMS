// 路由名称常量 — 对应 main_pages.json 注册的页面

export class Routes {
  static readonly LOGIN: string = 'LoginPage'
  static readonly DASHBOARD: string = 'DashboardPage'
  static readonly SITES: string = 'SitesPage'
  static readonly ARTICLES: string = 'ArticlesPage'
  static readonly ARTICLE_EDITOR: string = 'ArticleEditorPage'
  static readonly TOPICS: string = 'TopicsPage'
  static readonly TEMPLATES: string = 'TemplatesPage'
  static readonly KEYWORDS: string = 'KeywordsPage'
  static readonly AI_SETTINGS: string = 'AISettingsPage'
  static readonly DATA_MANAGEMENT: string = 'DataManagementPage'
  static readonly ADMIN: string = 'AdminPage'
  static readonly ABOUT: string = 'AboutPage'
}

/** 文章编辑器导航参数 — 替代 param['xxx'] 动态属性访问 */
export class ArticleEditorNavParam {
  articleId: string = 'new'
  sourceType: string = 'article'
  sourceId: string = ''
  initialTitle: string = ''
  initialKeywords: string = ''
}

/** 创建文章编辑器导航参数的便捷方法 */
export function createArticleEditorParam(options: Partial<ArticleEditorNavParam>): ArticleEditorNavParam {
  const param = new ArticleEditorNavParam()
  if (options.articleId !== undefined) { param.articleId = options.articleId }
  if (options.sourceType !== undefined) { param.sourceType = options.sourceType }
  if (options.sourceId !== undefined) { param.sourceId = options.sourceId }
  if (options.initialTitle !== undefined) { param.initialTitle = options.initialTitle }
  if (options.initialKeywords !== undefined) { param.initialKeywords = options.initialKeywords }
  return param
}
