// 关键词标签组件 — 提取自 KeywordsPage.ets

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Keyword } from '../../models/Keyword'

@Component
export struct KeywordChipComponent {
  keyword: Keyword = new Keyword()
  onDelete: () => void = () => {}

  build() {
    Row({ space: Spacing.XS }) {
      Text(this.keyword.keyword)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_PRIMARY)

      if (this.keyword.useCount > 0) {
        Text(`${this.keyword.useCount}`)
          .fontSize(Typography.LABEL)
          .fontColor(Colors.TEXT_SECONDARY)
      }

      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(ComponentSize.ICON_SM)
        .fontColor([Colors.TEXT_HINT])
        .onClick(() => {
          this.onDelete()
        })
    }
    .padding({ left: Spacing.MD, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
    .borderRadius(Radius.FULL)
    .backgroundColor(Colors.BG_PRIMARY)
    .borderWidth(1)
    .borderColor(Colors.BORDER)
    .margin({ right: Spacing.SM, bottom: Spacing.SM })
  }
}
