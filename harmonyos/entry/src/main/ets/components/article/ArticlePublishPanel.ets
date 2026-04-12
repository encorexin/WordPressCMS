import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { WordPressCategory } from '../../services/http/WordPressApi'

@Component
export struct ArticlePublishPanelComponent {
  @Prop categories: WordPressCategory[] = []
  @Prop selectedCategories: number[] = []
  @Link postSlug: string
  @Prop generatingSlug: boolean = false
  @Prop wordpressPostId: string = ''
  onToggleCategory: (categoryId: number) => void = (_categoryId: number) => {}
  onGenerateSlug: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      if (this.categories.length > 0) {
        Column({ space: Spacing.XS }) {
          Text('文章分类')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.categories, (category: WordPressCategory) => {
              Button(category.name)
                .type(ButtonType.Normal)
                .fontSize(Typography.CAPTION)
                .fontColor(this.selectedCategories.includes(category.id)
                  ? ResourceColors.TEXT_ON_PRIMARY
                  : ResourceColors.TEXT_PRIMARY)
                .backgroundColor(this.selectedCategories.includes(category.id)
                  ? ResourceColors.PRIMARY
                  : Color.Transparent)
                .borderWidth(1)
                .borderColor(this.selectedCategories.includes(category.id)
                  ? ResourceColors.PRIMARY
                  : ResourceColors.BORDER)
                .borderRadius(Radius.FULL)
                .height(32)
                .padding({ left: Spacing.MD, right: Spacing.MD })
                .margin({ right: Spacing.SM, bottom: Spacing.SM })
                .onClick(() => {
                  this.onToggleCategory(category.id)
                })
            }, (category: WordPressCategory) => String(category.id))
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      Column({ space: Spacing.XS }) {
        Text('文章别名 (Slug)')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        Row({ space: Spacing.SM }) {
          TextInput({ text: $$this.postSlug, placeholder: '自动生成或手动输入' })
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .height(ComponentSize.INPUT_HEIGHT)
            .layoutWeight(1)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .borderRadius(Radius.SM)

          Button(this.generatingSlug ? '...' : 'AI')
            .type(ButtonType.Normal)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(ResourceColors.PRIMARY)
            .borderRadius(Radius.SM)
            .height(ComponentSize.INPUT_HEIGHT)
            .width(56)
            .enabled(!this.generatingSlug)
            .onClick(() => {
              this.onGenerateSlug()
            })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.wordpressPostId.length > 0) {
        Row({ space: Spacing.SM }) {
          Circle({ width: 8, height: 8 })
            .fill(ResourceColors.SUCCESS)
          Text(`已发布 · Post ID: ${this.wordpressPostId}`)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.SUCCESS)
            .padding({ left: Spacing.XS, right: Spacing.XS, top: 2, bottom: 2 })
            .backgroundColor(ResourceColors.SUCCESS_SOFT_BG)
            .borderRadius(Radius.SM)
        }
        .width('100%')
      }
    }
    .width('100%')
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }
}
