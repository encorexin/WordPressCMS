// 文章版本数据模型

export class ArticleVersion {
  id: string = ''
  articleId: string = ''
  userId: string = ''
  siteId: string = ''
  title: string = ''
  content: string = ''
  keywords: string = ''
  template: string = ''
  wordpressPostId: string = ''
  status: string = 'draft'
  versionNumber: number = 0
  createdAt: string = ''
}
