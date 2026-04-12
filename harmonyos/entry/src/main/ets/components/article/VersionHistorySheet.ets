// 版本历史底部弹窗组件 — 提取自 ArticleEditorPage.ets

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { ArticleVersion } from '../../models/ArticleVersion'
import { formatDateTime } from '../../utils/DateUtil'

@Component
export struct VersionHistorySheetComponent {
  @Prop versions: ArticleVersion[] = []
  onRestore: (version: ArticleVersion) => void = (_version: ArticleVersion) => {}
  onClose: () => void = () => {}

  @State private isVisible: boolean = false
  private animTimer: number = -1

  aboutToAppear(): void {
    this.animTimer = setTimeout(() => {
      this.isVisible = true
    }, 10)
  }

  aboutToDisappear(): void {
    if (this.animTimer !== -1) {
      clearTimeout(this.animTimer)
      this.animTimer = -1
    }
  }

  build() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
        .onClick(() => {
          this.onClose()
        })

      // 底部弹窗内容
      Column({ space: Spacing.BASE }) {
        // 标题 + 关闭
        Row() {
          Text('版本历史')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([ResourceColors.TEXT_HINT])
            .onClick(() => {
              this.onClose()
            })
        }
        .width('100%')

        // 版本列表
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
          .alignItems(HorizontalAlign.Center)
        } else {
          Scroll() {
            Column({ space: 0 }) {
              ForEach(this.versions, (version: ArticleVersion) => {
                Row() {
                  Column({ space: Spacing.XS }) {
                    Text(`版本 ${version.versionNumber}`)
                      .fontSize(Typography.BODY)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(ResourceColors.TEXT_PRIMARY)
                    Text(version.content.length > 80
                      ? version.content.substring(0, 80) + '...'
                      : version.content)
                      .fontSize(Typography.CAPTION)
                      .fontColor(ResourceColors.TEXT_SECONDARY)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(formatDateTime(version.createdAt))
                      .fontSize(Typography.LABEL)
                      .fontColor(ResourceColors.TEXT_HINT)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Button('恢复')
                    .type(ButtonType.Normal)
                    .fontSize(Typography.CAPTION)
                    .fontColor(ResourceColors.PRIMARY)
                    .backgroundColor('transparent')
                    .borderWidth(1)
                    .borderColor(ResourceColors.PRIMARY)
                    .borderRadius(Radius.SM)
                    .height(32)
                    .padding({ left: Spacing.MD, right: Spacing.MD })
                    .onClick(() => {
                      this.onRestore(version)
                    })
                }
                .width('100%')
                .padding({ top: Spacing.SM, bottom: Spacing.SM })
                .border({ width: { bottom: 0.5 }, color: ResourceColors.DIVIDER })
              }, (version: ArticleVersion) => version.id)
            }
            .width('100%')
          }
          .constraintSize({ maxHeight: 400 })
          .scrollBar(BarState.Auto)
        }
      }
      .width('100%')
      .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.XL })
      .borderRadius({ topLeft: Radius.XL, topRight: Radius.XL })
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .position({ x: 0, y: '100%' })
      .translate({ y: this.isVisible ? '-100%' : '0' })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }
}
