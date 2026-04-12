// 关键词条目卡片组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Keyword } from '../../models/Keyword'

@Reusable
@Component
export struct KeywordItemCardComponent {
  @Prop keyword: Keyword = new Keyword()
  @Prop stateLabel: string = ''
  @Prop stateHint: string = ''
  @Prop writeActionLabel: string = '写文章'
  onWrite: () => void = () => {}
  onDelete: () => void = () => {}

  /**
   * @Reusable 组件复用时重置内部状态
   * 当前组件无 @State 内部状态，但保留此生命周期以防护后续新增状态时遗漏
   */
  aboutToReuse(): void {
    // 当前无内部 @State 需要重置，@Prop 由父组件同步
  }

  build() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text(this.keyword.keyword)
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.stateLabel)
          .fontSize(Typography.LABEL)
          .fontColor(this.keyword.useCount > 0 ? ResourceColors.SUCCESS : ResourceColors.PRIMARY)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
          .borderRadius(Radius.FULL)
      }
      .width('100%')

      Text(this.stateHint)
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .width('100%')

      Row({ space: Spacing.SM }) {
        Text(this.keyword.useCount > 0 ? `已带入编辑器 ${this.keyword.useCount} 次` : '尚未带入文章编辑器')
          .layoutWeight(1)
          .fontSize(Typography.CAPTION)
          .fontColor(this.keyword.useCount > 0 ? ResourceColors.PRIMARY : ResourceColors.TEXT_HINT)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
          .borderRadius(Radius.FULL)
          .backgroundColor(ResourceColors.BG_SECONDARY)

        Button(this.writeActionLabel, { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .backgroundColor(ResourceColors.PRIMARY)
          .onClick(() => {
            this.onWrite()
          })

        Button('删除', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(ResourceColors.BORDER)
          .onClick(() => {
            this.onDelete()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(ResourceColors.BG_PRIMARY)
  }
}
