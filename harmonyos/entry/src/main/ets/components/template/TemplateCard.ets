// 模板卡片组件 — 提取自 TemplatesPage.ets

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { ArticleTemplate } from '../../models/ArticleTemplate'

@Reusable
@Component
export struct TemplateCardComponent {
  @Prop template: ArticleTemplate = new ArticleTemplate()
  onEdit: () => void = () => {}
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
      // 模板名称
      Text(this.template.name)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 描述
      if (this.template.description.length > 0) {
        Text(this.template.description)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 系统提示词预览
      Column({ space: Spacing.XS }) {
        Text('系统提示词')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_HINT)
        Text(this.template.systemPrompt)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .fontFamily('monospace')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(Spacing.SM)
      .backgroundColor(ResourceColors.BG_SECONDARY)
      .borderRadius(Radius.MD)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Row({ space: Spacing.SM }) {
        Button('编辑', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.onEdit()
          })

        Button('删除', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.onDelete()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_CARD)
    .borderWidth(1)
    .borderColor(ResourceColors.BORDER)
  }
}
