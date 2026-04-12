// 文章列表项卡片组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Article } from '../../models/Article'
import { formatRelativeTime } from '../../utils/DateUtil'
import { ContentMetrics } from '../../utils/ContentMetrics'

@Reusable
@Component
export struct ArticleListItemCardComponent {
  @Prop article: Article = new Article()
  @Prop batchMode: boolean = false
  @Prop isSelected: boolean = false
  @Prop siteName: string = ''
  onToggleSelection: () => void = () => {}
  onOpen: () => void = () => {}
  onPreview: () => void = () => {}
  onDelete: () => void = () => {}

  /**
   * @Reusable 组件复用时重置内部状态
   * 当前组件无 @State 内部状态，保留生命周期以便后续扩展
   */
  aboutToReuse(): void {
    // No internal state to reset.
  }

  build() {
    Column({ space: Spacing.MD }) {
      Column({ space: Spacing.MD }) {
        Row() {
          if (this.batchMode) {
            Checkbox()
              .select(this.isSelected)
              .selectedColor(ResourceColors.PRIMARY)
              .margin({ right: Spacing.SM })
              .onChange((_value: boolean) => {
                this.onToggleSelection()
              })
          }

          Text(this.article.title.length > 0 ? this.article.title : '无标题')
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(this.getStatusLabel(this.article.status))
            .fontSize(Typography.LABEL)
            .fontColor(this.getStatusColor(this.article.status))
            .backgroundColor(this.getStatusBgColor(this.article.status))
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .borderRadius(Radius.FULL)
            .margin({ left: Spacing.SM })
        }
        .width('100%')

        if (this.article.content.length > 0) {
          Text(this.getContentExcerpt(this.article.content))
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Column({ space: Spacing.SM }) {
          Row({ space: Spacing.SM }) {
            if (this.siteName.length > 0) {
              Text(this.siteName)
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.PRIMARY)
                .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
                .borderRadius(Radius.SM)
                .backgroundColor(ResourceColors.BG_PRIMARY)
            } else {
              Text('未关联站点')
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.TEXT_HINT)
                .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
                .borderRadius(Radius.SM)
                .backgroundColor(ResourceColors.BG_PRIMARY)
            }

            Text(`${this.getWordCount()} 字`)
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.TEXT_HINT)
              .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
              .borderRadius(Radius.SM)
              .backgroundColor(ResourceColors.BG_PRIMARY)

            Blank().layoutWeight(1)

            Text(this.getDisplayTime())
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.TEXT_HINT)
              .flexShrink(0)
          }
          .width('100%')

          if (this.article.keywords.length > 0) {
            Row({ space: 4 }) {
              Text('关键词:')
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.TEXT_HINT)
                .flexShrink(0)
              Text(this.article.keywords)
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.TEXT_SECONDARY)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.SM)
            .backgroundColor(ResourceColors.BG_PRIMARY)
          }
        }
        .width('100%')
      }
      .width('100%')
      .onClick(() => {
        if (!this.batchMode) {
          this.onOpen()
        } else {
          this.onToggleSelection()
        }
      })

      Row({ space: Spacing.SM }) {
        Button(this.batchMode ? '查看详情' : this.getPrimaryActionLabel(this.article.status), { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT)
          .backgroundColor(ResourceColors.PRIMARY)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.onOpen()
          })

        if (this.article.status === 'published' && this.article.wordpressPostId.length > 0) {
          Button('预览', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(ResourceColors.PRIMARY)
            .onClick(() => {
              this.onPreview()
            })
        }

        Button('删除', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(ResourceColors.BORDER)
          .onClick(() => {
            this.onDelete()
          })
      }
      .width('100%')
      .margin({ top: Spacing.XS })
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.BASE, bottom: Spacing.LG })
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  private getContentExcerpt(content: string): string {
    const cleaned = content.replace(/[#*_`>\-\[\]\(\)]/g, '').replace(/\s+/g, ' ').trim()
    if (cleaned.length <= 120) {
      return cleaned
    }
    return `${cleaned.substring(0, 120)}...`
  }

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'published':
        return '已发布'
      case 'draft':
        return '草稿'
      case 'pending':
        return '待处理'
      case 'generating':
        return '生成中'
      default:
        return status
    }
  }

  private getStatusColor(status: string): ResourceColor {
    switch (status) {
      case 'published':
        return ResourceColors.SUCCESS
      case 'draft':
        return ResourceColors.TEXT_SECONDARY
      case 'pending':
        return ResourceColors.WARNING
      case 'generating':
        return ResourceColors.PRIMARY
      default:
        return ResourceColors.TEXT_HINT
    }
  }

  private getStatusBgColor(status: string): ResourceColor {
    switch (status) {
      case 'published':
        return ResourceColors.SUCCESS_SOFT_BG
      case 'draft':
        return ResourceColors.BG_SECONDARY
      case 'pending':
        return ResourceColors.INFO_SOFT_BG
      case 'generating':
        return ResourceColors.INFO_SOFT_BG
      default:
        return ResourceColors.BG_SECONDARY
    }
  }

  private getPrimaryActionLabel(status: string): string {
    switch (status) {
      case 'published':
        return '维护内容'
      case 'pending':
        return '继续处理'
      case 'generating':
        return '查看进度'
      case 'draft':
        return '继续编辑'
      default:
        return '打开文章'
    }
  }

  private getWordCount(): number {
    if (this.article.wordCount > 0) {
      return this.article.wordCount
    }
    return ContentMetrics.countWords(this.article.content)
  }

  private getDisplayTime(): string {
    const updatedAt = this.article.updatedAt.length > 0 ? this.article.updatedAt : this.article.createdAt
    return formatRelativeTime(updatedAt)
  }
}
