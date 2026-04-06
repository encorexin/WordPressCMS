// 搜索栏组件

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索...'
  @Prop value: string = ''
  onTextChange: (text: string) => void = () => {}
  onSearch: (text: string) => void = () => {}

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.TEXT_HINT])
        .margin({ right: Spacing.SM })
        .accessibilityText('搜索')

      TextInput({ placeholder: this.placeholder, text: this.value })
        .layoutWeight(1)
        .height(40)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_PRIMARY)
        .placeholderColor(Colors.TEXT_HINT)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => {
          this.onTextChange(value)
        })
        .onSubmit(() => {
          this.onSearch(this.value)
        })

      if (this.value.length > 0) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([Colors.TEXT_HINT])
          .margin({ left: Spacing.SM })
          .onClick(() => {
            this.onTextChange('')
          })
      }
    }
    .width('100%')
    .height(ComponentSize.INPUT_HEIGHT)
    .padding({ left: Spacing.BASE, right: Spacing.BASE })
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
    .alignItems(VerticalAlign.Center)
  }
}
