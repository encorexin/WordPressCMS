// 文章数据模型

export class Article {
  id: string = ''
  userId: string = ''
  siteId: string = ''
  title: string = ''
  content: string = ''
  keywords: string = ''
  template: string = ''
  status: string = 'draft'
  wordpressPostId: string = ''
  wordCount: number = 0
  tokensUsed: number = 0
  createdAt: string = ''
  updatedAt: string = ''
}
