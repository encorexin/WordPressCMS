// 文章卡片组件 — 提取自 ArticlesPage.ets

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Article } from '../../models/Article'
import { formatRelativeTime } from '../../utils/DateUtil'

@Component
export struct ArticleCardComponent {
  @Prop article: Article = new Article()
  onTap: () => void = () => {}
  onDelete: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      Column({ space: Spacing.MD }) {
        // 标题行 + 状态标签
        Row() {
          Text(this.article.title.length > 0 ? this.article.title : '无标题')
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 状态标签
          Text(this.getStatusLabel(this.article.status))
            .fontSize(Typography.LABEL)
            .fontColor(this.getStatusColor(this.article.status))
            .backgroundColor(this.getStatusBgColor(this.article.status))
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .borderRadius(Radius.FULL)
            .margin({ left: Spacing.SM })
        }
        .width('100%')

        Text(this.getStatusDescription(this.article.status))
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)
          .width('100%')

        // 元信息行（站点 + 日期 + 关键词）
        Row({ space: Spacing.MD }) {
          Text(this.getSiteLabel())
            .fontSize(Typography.CAPTION)
            .fontColor(this.article.siteId.length > 0 ? Colors.PRIMARY : Colors.TEXT_HINT)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.SM)
            .backgroundColor(Colors.BG_PRIMARY)

          if (this.article.keywords.length > 0) {
            Row({ space: 4 }) {
              Text('关键词:')
                .fontSize(Typography.CAPTION)
                .fontColor(Colors.TEXT_HINT)
              Text(this.article.keywords)
                .fontSize(Typography.CAPTION)
                .fontColor(Colors.TEXT_SECONDARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 120 })
            }
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.SM)
            .backgroundColor(Colors.BG_PRIMARY)
          }

          Text(formatRelativeTime(this.article.updatedAt))
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_HINT)
        }
        .width('100%')
      }
      .width('100%')
      .onClick(() => {
        this.onTap()
      })

      Row({ space: Spacing.SM }) {
        Button(this.getPrimaryActionLabel(this.article.status), { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.onTap()
          })

        Button('删除', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.ERROR)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.onDelete()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'published': return '已发布'
      case 'draft': return '草稿'
      case 'pending': return '待处理'
      case 'generating': return '生成中'
      default: return status
    }
  }

  private getStatusDescription(status: string): string {
    switch (status) {
      case 'published': return '已发布到站点，可继续维护内容并保持版本更新'
      case 'draft': return '未发布草稿，可继续补充标题、关键词和正文'
      case 'pending': return '待处理内容，请检查后继续编辑或进入发布流程'
      case 'generating': return 'AI 正在生成内容，可进入编辑器继续查看进度'
      default: return '可进入编辑器继续管理这篇文章'
    }
  }

  private getPrimaryActionLabel(status: string): string {
    switch (status) {
      case 'published': return '维护内容'
      case 'pending': return '继续处理'
      case 'generating': return '查看进度'
      case 'draft': return '继续编辑'
      default: return '打开文章'
    }
  }

  private getSiteLabel(): string {
    return this.article.siteId.length > 0 ? '已关联站点' : '未关联站点'
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'published': return Colors.STATUS_PUBLISHED_TEXT
      case 'draft': return Colors.STATUS_DRAFT_TEXT
      case 'pending': return Colors.STATUS_PENDING_TEXT
      case 'generating': return Colors.STATUS_GENERATING_TEXT
      default: return Colors.TEXT_HINT
    }
  }

  private getStatusBgColor(status: string): string {
    switch (status) {
      case 'published': return Colors.STATUS_PUBLISHED_BG
      case 'draft': return Colors.STATUS_DRAFT_BG
      case 'pending': return Colors.STATUS_PENDING_BG
      case 'generating': return Colors.STATUS_GENERATING_BG
      default: return Colors.BG_SECONDARY
    }
  }
}
