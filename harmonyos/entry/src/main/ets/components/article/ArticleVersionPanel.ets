import { ResourceColors, Typography, Spacing, Radius } from '../../constants/DesignTokens'
import { ArticleVersion } from '../../models/ArticleVersion'
import { formatDateTime } from '../../utils/DateUtil'
import { ContentMetrics } from '../../utils/ContentMetrics'

@Component
export struct ArticleVersionPanelComponent {
  @Prop versions: ArticleVersion[] = []
  @Prop expandedVersionIds: string[] = []
  onToggleExpand: (versionId: string) => void = (_versionId: string) => {}
  onDelete: (version: ArticleVersion) => void = (_version: ArticleVersion) => {}
  onRestore: (version: ArticleVersion) => void = (_version: ArticleVersion) => {}

  private isExpanded(versionId: string): boolean {
    return this.expandedVersionIds.includes(versionId)
  }

  private getContentLength(content: string): number {
    return ContentMetrics.countWords(content)
  }

  @Builder
  private buildVersionItem(version: ArticleVersion): void {
    Column({ space: Spacing.XS }) {
      Row() {
        Column({ space: Spacing.XS }) {
          Row({ space: Spacing.SM }) {
            Text(`版本 ${version.versionNumber}`)
              .fontSize(Typography.BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(ResourceColors.TEXT_PRIMARY)

            Text(version.status === 'published' ? '已发布' : '草稿')
              .fontSize(Typography.LABEL)
              .fontColor(version.status === 'published' ? ResourceColors.SUCCESS : ResourceColors.TEXT_HINT)
              .padding({ left: Spacing.XS, right: Spacing.XS })
              .backgroundColor(version.status === 'published'
                ? ResourceColors.SUCCESS_SOFT_BG
                : ResourceColors.BG_SECONDARY)
              .borderRadius(Radius.SM)
          }

          Text(version.title)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: Spacing.SM }) {
            Text(formatDateTime(version.createdAt))
              .fontSize(Typography.LABEL)
              .fontColor(ResourceColors.TEXT_HINT)
            Text(`| ${this.getContentLength(version.content)} 字`)
              .fontSize(Typography.LABEL)
              .fontColor(ResourceColors.TEXT_HINT)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Row({ space: Spacing.SM }) {
          Button(this.isExpanded(version.id) ? '收起' : '详情')
            .type(ButtonType.Normal)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)
            .backgroundColor(Color.Transparent)
            .height(32)
            .padding({ left: Spacing.SM, right: Spacing.SM })
            .onClick(() => {
              this.onToggleExpand(version.id)
            })

          Button('删除')
            .type(ButtonType.Normal)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.ERROR)
            .backgroundColor(Color.Transparent)
            .height(32)
            .padding({ left: Spacing.SM, right: Spacing.SM })
            .onClick(() => {
              this.onDelete(version)
            })

          Button('恢复')
            .type(ButtonType.Normal)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(ResourceColors.PRIMARY)
            .borderRadius(Radius.SM)
            .height(32)
            .padding({ left: Spacing.MD, right: Spacing.MD })
            .onClick(() => {
              this.onRestore(version)
            })
        }
      }
      .width('100%')

      if (this.isExpanded(version.id)) {
        Column({ space: Spacing.XS }) {
          Divider()
            .width('100%')
            .strokeWidth(0.5)
            .color(ResourceColors.DIVIDER)
            .margin({ top: Spacing.SM, bottom: Spacing.SM })

          Text('内容预览:')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)

          Text(version.content.length > 200 ? version.content.substring(0, 200) + '...' : version.content)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (version.content.length > 200) {
            Text(`...共 ${this.getContentLength(version.content)} 字`)
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.TEXT_HINT)
          }
        }
        .width('100%')
        .padding({ top: Spacing.XS })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
    .border({ width: { bottom: 0.5 }, color: ResourceColors.DIVIDER })
  }

  build() {
    Column({ space: Spacing.MD }) {
      if (this.versions.length === 0) {
        Column({ space: Spacing.SM }) {
          Text('暂无版本历史')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_HINT)
          Text('保存文章后会自动创建版本')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_HINT)
        }
        .width('100%')
        .padding({ top: Spacing.LG, bottom: Spacing.LG })
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.versions, (version: ArticleVersion) => {
          this.buildVersionItem(version)
        }, (version: ArticleVersion) => version.id)
      }
    }
    .width('100%')
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }
}
