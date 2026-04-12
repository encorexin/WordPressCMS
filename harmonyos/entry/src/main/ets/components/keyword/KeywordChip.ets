// 关键词标签组件 — 提取自 KeywordsPage.ets

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Keyword } from '../../models/Keyword'

@Component
export struct KeywordChipComponent {
  keyword: Keyword = new Keyword()
  onDelete: () => void = () => {}

  build() {
    Row({ space: Spacing.XS }) {
      Text(this.keyword.keyword)
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      if (this.keyword.useCount > 0) {
        Text(`${this.keyword.useCount}`)
          .fontSize(Typography.LABEL)
          .fontColor(ResourceColors.TEXT_SECONDARY)
      }

      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(ComponentSize.ICON_SM)
        .fontColor([ResourceColors.TEXT_HINT])
        .onClick(() => {
          this.onDelete()
        })
    }
    .padding({ left: Spacing.MD, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
    .borderRadius(Radius.FULL)
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .borderWidth(1)
    .borderColor(ResourceColors.BORDER)
    .margin({ right: Spacing.SM, bottom: Spacing.SM })
  }
}
