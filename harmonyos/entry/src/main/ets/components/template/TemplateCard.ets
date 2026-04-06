// 模板卡片组件 — 提取自 TemplatesPage.ets

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { ArticleTemplate } from '../../models/ArticleTemplate'

@Component
export struct TemplateCardComponent {
  @Prop template: ArticleTemplate = new ArticleTemplate()
  onEdit: () => void = () => {}
  onDelete: () => void = () => {}

  build() {
    Column({ space: Spacing.SM }) {
      // 模板名称
      Text(this.template.name)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 描述
      if (this.template.description.length > 0) {
        Text(this.template.description)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 系统提示词预览
      Column({ space: Spacing.XS }) {
        Text('系统提示词')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_HINT)
        Text(this.template.systemPrompt)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)
          .fontFamily('monospace')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(Spacing.SM)
      .backgroundColor(Colors.BG_SECONDARY)
      .borderRadius(Radius.MD)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Row({ space: Spacing.SM }) {
        Button('编辑', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.onEdit()
          })

        Button('删除', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.ERROR)
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
    .backgroundColor(Colors.BG_CARD)
    .borderWidth(1)
    .borderColor(Colors.BORDER)
  }
}
