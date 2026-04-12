// 站点表单对话框组件 — 提取自 SitesPage.ets

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { WordPressSite } from '../../models/WordPressSite'

@Component
export struct SiteFormDialogComponent {
  @Prop @Watch('onShowChange') show: boolean = false
  @Prop @Watch('onEditingSiteChange') editingSite: WordPressSite | null = null
  onSave: (name: string, url: string, username: string, password: string) => void =
    (_name: string, _url: string, _username: string, _password: string) => {}
  onClose: () => void = () => {}

  @State private formSiteName: string = ''
  @State private formSiteUrl: string = ''
  @State private formUsername: string = ''
  @State private formAppPassword: string = ''
  @State private isSubmitting: boolean = false

  aboutToAppear(): void {
    this.resetForm()
  }

  onShowChange(): void {
    if (this.show) {
      this.resetForm()
    }
  }

  onEditingSiteChange(): void {
    this.resetForm()
  }

  private resetForm(): void {
    if (this.editingSite !== null) {
      this.formSiteName = this.editingSite.siteName
      this.formSiteUrl = this.editingSite.siteUrl
      this.formUsername = this.editingSite.username
      this.formAppPassword = this.editingSite.appPassword
    } else {
      this.formSiteName = ''
      this.formSiteUrl = ''
      this.formUsername = ''
      this.formAppPassword = ''
    }
  }

  build() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
        .onClick(() => {
          if (!this.isSubmitting) {
            this.onClose()
          }
        })

      // 底部弹窗内容
      Column({ space: Spacing.BASE }) {
        // 标题 + 关闭
        Row() {
          Text(this.editingSite !== null ? '编辑站点' : '添加 WordPress 站点')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([ResourceColors.TEXT_HINT])
            .accessibilityText('关闭')
            .onClick(() => {
              if (!this.isSubmitting) {
                this.onClose()
              }
            })
        }
        .width('100%')

        Text('填写 WordPress 网站的连接信息，应用程序密码可在 WordPress 后台生成')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        // 站点名称
        Column({ space: Spacing.XS }) {
          Text('站点名称')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: '我的 WordPress 站点', text: this.formSiteName })
            .height(ComponentSize.INPUT_HEIGHT)
            .borderRadius(Radius.MD)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .padding({ left: Spacing.BASE, right: Spacing.BASE })
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .enabled(!this.isSubmitting)
            .onChange((v: string) => { this.formSiteName = v })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 站点地址
        Column({ space: Spacing.XS }) {
          Text('站点地址')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: 'https://example.com', text: this.formSiteUrl })
            .height(ComponentSize.INPUT_HEIGHT)
            .borderRadius(Radius.MD)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .padding({ left: Spacing.BASE, right: Spacing.BASE })
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .enabled(!this.isSubmitting)
            .onChange((v: string) => { this.formSiteUrl = v })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 用户名
        Column({ space: Spacing.XS }) {
          Text('用户名')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: 'admin', text: this.formUsername })
            .height(ComponentSize.INPUT_HEIGHT)
            .borderRadius(Radius.MD)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .padding({ left: Spacing.BASE, right: Spacing.BASE })
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .enabled(!this.isSubmitting)
            .onChange((v: string) => { this.formUsername = v })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 应用程序密码
        Column({ space: Spacing.XS }) {
          Text('应用程序密码')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          TextInput({ placeholder: 'xxxx xxxx xxxx xxxx xxxx xxxx', text: this.formAppPassword })
            .type(InputType.Password)
            .height(ComponentSize.INPUT_HEIGHT)
            .borderRadius(Radius.MD)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .padding({ left: Spacing.BASE, right: Spacing.BASE })
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .enabled(!this.isSubmitting)
            .onChange((v: string) => { this.formAppPassword = v })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 提交按钮
        Button(this.isSubmitting ? '保存中...' : (this.editingSite !== null ? '更新' : '添加'), { type: ButtonType.Capsule })
          .width('100%')
          .height(ComponentSize.BUTTON_HEIGHT)
          .backgroundColor(ResourceColors.PRIMARY)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isSubmitting)
          .margin({ top: Spacing.SM })
          .onClick(() => {
            this.onSave(this.formSiteName, this.formSiteUrl, this.formUsername, this.formAppPassword)
          })
      }
      .width('100%')
      .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.XL })
      .borderRadius({ topLeft: Radius.XL, topRight: Radius.XL })
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .position({ x: 0, y: '100%' })
      .translate({ y: this.show ? '-100%' : '0' })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }
}
