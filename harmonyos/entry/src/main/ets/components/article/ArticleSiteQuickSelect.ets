import { ResourceColors, Typography, Spacing } from '../../constants/DesignTokens'
import { WordPressSite } from '../../models/WordPressSite'

@Component
export struct ArticleSiteQuickSelectComponent {
  @Prop sites: WordPressSite[] = []
  @Prop selectedSiteId: string = ''
  onSelectSite: (site: WordPressSite) => void = (_site: WordPressSite) => {}

  private getSelectedSiteName(): string {
    const found = this.sites.find((site: WordPressSite) => site.id === this.selectedSiteId)
    return found ? found.siteName : '选择站点'
  }

  build() {
    Row({ space: Spacing.SM }) {
      Text('发布站点')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .flexShrink(0)

      if (this.sites.length > 0) {
        Select(this.sites.map((site: WordPressSite) => {
          const option: SelectOption = { value: site.siteName }
          return option
        }))
          .selected(this.sites.findIndex((site: WordPressSite) => site.id === this.selectedSiteId))
          .value(this.getSelectedSiteName())
          .font({ size: Typography.BODY })
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .selectedOptionFont({ size: Typography.BODY })
          .selectedOptionFontColor(ResourceColors.PRIMARY)
          .optionFont({ size: Typography.BODY })
          .optionFontColor(ResourceColors.TEXT_PRIMARY)
          .onSelect((index: number) => {
            if (index >= 0 && index < this.sites.length) {
              this.onSelectSite(this.sites[index])
            }
          })
          .layoutWeight(1)
          .height(36)
      } else {
        Text('暂无站点')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_HINT)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
  }
}
