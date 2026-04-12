import { ResourceColors, Typography, Spacing, Radius } from '../../constants/DesignTokens'

@Component
export struct ArticleEditorFormatToolbarComponent {
  onInsertMarkdown: (prefix: string, suffix: string, placeholder: string) => void =
    (_prefix: string, _suffix: string, _placeholder: string) => {}

  @Builder
  private buildActionButton(label: string, width: number, fontSize: number,
    onClick: () => void, fontWeight: FontWeight = FontWeight.Normal,
    fontStyle: FontStyle = FontStyle.Normal): void {
    Text(label)
      .fontSize(fontSize)
      .fontWeight(fontWeight)
      .fontStyle(fontStyle)
      .fontColor(ResourceColors.TEXT_PRIMARY)
      .width(width)
      .height(32)
      .textAlign(TextAlign.Center)
      .backgroundColor(ResourceColors.BG_SECONDARY)
      .borderRadius(Radius.SM)
      .onClick(() => {
        onClick()
      })
  }

  build() {
    Scroll() {
      Row({ space: Spacing.XS }) {
        this.buildActionButton('B', 32, Typography.BODY, () => {
          this.onInsertMarkdown('**', '**', '粗体文本')
        }, FontWeight.Bold)

        this.buildActionButton('I', 32, Typography.BODY, () => {
          this.onInsertMarkdown('*', '*', '斜体文本')
        }, FontWeight.Normal, FontStyle.Italic)

        this.buildActionButton('H1', 36, Typography.CAPTION, () => {
          this.onInsertMarkdown('\n# ', '\n', '标题\n')
        }, FontWeight.Bold)

        this.buildActionButton('H2', 36, Typography.CAPTION, () => {
          this.onInsertMarkdown('\n## ', '\n', '小标题\n')
        }, FontWeight.Bold)

        this.buildActionButton('H3', 36, Typography.CAPTION, () => {
          this.onInsertMarkdown('\n### ', '\n', '子标题\n')
        }, FontWeight.Bold)

        this.buildActionButton('UL', 32, Typography.CAPTION, () => {
          this.onInsertMarkdown('\n- ', '\n', '列表项\n')
        })

        this.buildActionButton('OL', 32, Typography.CAPTION, () => {
          this.onInsertMarkdown('\n1. ', '\n', '列表项\n')
        })

        this.buildActionButton('` `', 40, Typography.CAPTION, () => {
          this.onInsertMarkdown('`', '`', '代码')
        })

        this.buildActionButton('{}', 32, Typography.CAPTION, () => {
          this.onInsertMarkdown('\n```\n', '\n```\n', '代码块\n')
        })

        this.buildActionButton('Link', 44, Typography.CAPTION, () => {
          this.onInsertMarkdown('[', '](URL)', '链接文本')
        })

        this.buildActionButton('Img', 40, Typography.CAPTION, () => {
          this.onInsertMarkdown('![', '](URL)', '图片描述')
        })
      }
      .padding({ left: Spacing.XS, right: Spacing.XS })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .scrollBar(BarState.Off)
  }
}
