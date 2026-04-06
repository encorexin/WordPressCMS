// 模板表单对话框组件 — 提取自 TemplatesPage.ets

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { ArticleTemplate } from '../../models/ArticleTemplate'

@Component
export struct TemplateFormDialogComponent {
  @Prop @Watch('onShowChange') show: boolean = false
  @Prop @Watch('onEditingTemplateChange') editingTemplate: ArticleTemplate | null = null
  onSave: (name: string, desc: string, prompt: string) => void =
    (_name: string, _desc: string, _prompt: string) => {}
  onClose: () => void = () => {}

  @State private formName: string = ''
  @State private formDescription: string = ''
  @State private formSystemPrompt: string = ''
  @State private isSubmitting: boolean = false

  aboutToAppear(): void {
    this.resetForm()
  }

  onShowChange(): void {
    if (this.show) {
      this.resetForm()
    }
  }

  onEditingTemplateChange(): void {
    this.resetForm()
  }

  private resetForm(): void {
    if (this.editingTemplate !== null) {
      this.formName = this.editingTemplate.name
      this.formDescription = this.editingTemplate.description
      this.formSystemPrompt = this.editingTemplate.systemPrompt
    } else {
      this.formName = ''
      this.formDescription = ''
      this.formSystemPrompt = ''
    }
  }

  build() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          if (!this.isSubmitting) {
            this.onClose()
          }
        })

      // 底部弹窗
      Column() {
        // 标题
        Row() {
          Text(this.editingTemplate !== null ? '编辑模板' : '新建模板')
            .fontSize(Typography.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
          Blank()
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([Colors.TEXT_SECONDARY])
            .accessibilityText('关闭')
            .onClick(() => {
              if (!this.isSubmitting) {
                this.onClose()
              }
            })
        }
        .width('100%')
        .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.BASE, bottom: Spacing.SM })

        Text('创建自定义的文章生成模板')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_HINT)
          .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })

        // 可滚动表单
        Scroll() {
          Column({ space: Spacing.MD }) {
            // 模板名称
            Column({ space: Spacing.XS }) {
              Text('模板名称')
                .fontSize(Typography.BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
              TextInput({ text: this.formName, placeholder: '如：技术教程、产品评测' })
                .height(ComponentSize.BUTTON_HEIGHT)
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .onChange((value: string) => { this.formName = value })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 描述
            Column({ space: Spacing.XS }) {
              Text('描述（可选）')
                .fontSize(Typography.BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
              TextInput({ text: this.formDescription, placeholder: '简单描述这个模板的用途' })
                .height(ComponentSize.BUTTON_HEIGHT)
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .onChange((value: string) => { this.formDescription = value })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 系统提示词
            Column({ space: Spacing.XS }) {
              Text('系统提示词')
                .fontSize(Typography.BODY)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
              TextArea({ text: this.formSystemPrompt, placeholder: '定义 AI 的角色和生成要求...' })
                .height(200)
                .fontSize(Typography.LABEL)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .fontFamily('monospace')
                .onChange((value: string) => { this.formSystemPrompt = value })
              Text('提示：使用 {keywords} 和 {template} 作为占位符')
                .fontSize(Typography.LABEL)
                .fontColor(Colors.TEXT_HINT)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.LG })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 底部按钮
        Row({ space: Spacing.SM }) {
          Button('取消', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .borderRadius(Radius.SM)
            .backgroundColor(Colors.BG_PRIMARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .border({ width: 1, color: Colors.DIVIDER })
            .onClick(() => { this.onClose() })
          Button(this.isSubmitting ? '保存中...' : '保存', { type: ButtonType.Normal })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .borderRadius(Radius.SM)
            .backgroundColor(Colors.PRIMARY)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.onSave(this.formName, this.formDescription, this.formSystemPrompt)
            })
        }
        .width('100%')
        .padding(Spacing.BASE)
      }
      .width('100%')
      .height('85%')
      .backgroundColor(Colors.BG_CARD)
      .borderRadius({ topLeft: Radius.LG, topRight: Radius.LG })
      .position({ x: 0, y: '100%' })
      .translate({ y: this.show ? '-85%' : '0' })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }
}
