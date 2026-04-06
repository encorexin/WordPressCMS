// 分类选择器组件 — 提取自 ArticleEditorPage.ets 分类选择逻辑

import { Colors, Typography, Spacing, Radius } from '../../constants/DesignTokens'

@Component
export struct CategoryPickerComponent {
  @Prop categories: string[] = []
  @Prop selectedCategory: string = ''
  onSelect: (cat: string) => void = (_cat: string) => {}

  build() {
    Column({ space: Spacing.XS }) {
      Text('分类选择')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')

      Scroll() {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.categories, (cat: string) => {
            Text(cat)
              .fontSize(Typography.BODY)
              .fontColor(this.selectedCategory === cat ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)
              .backgroundColor(this.selectedCategory === cat ? Colors.PRIMARY : Colors.BG_SECONDARY)
              .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
              .borderRadius(Radius.FULL)
              .borderWidth(1)
              .borderColor(this.selectedCategory === cat ? Colors.PRIMARY : Colors.BORDER)
              .margin({ right: Spacing.SM, bottom: Spacing.SM })
              .onClick(() => {
                this.onSelect(cat)
              })
          }, (cat: string) => cat)
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }
}
