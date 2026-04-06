// 登录/注册页面 — 对标 React Login.tsx

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { AuthService, AuthResult } from '../services/auth/AuthService'
import { Logger } from '../utils/Logger'
import { isValidEmail } from '../utils/Sanitizer'
import { UiFeedback } from '../utils/UiFeedback'

@Component
export struct LoginPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack

  // 登录/注册切换
  @State activeTab: number = 0  // 0=登录, 1=注册

  // 登录表单
  @State loginEmail: string = ''
  @State loginPassword: string = ''

  // 注册表单
  @State registerEmail: string = ''
  @State registerPassword: string = ''
  @State confirmPassword: string = ''

  // 加载态
  @State isLoading: boolean = false

  build() {
    Column() {
      // 顶部留白
      Blank().height('15%')

      // Logo 区域
      Column() {
        Row() {
          Text('W')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_ON_PRIMARY)
        }
        .width(56)
        .height(56)
        .borderRadius(Radius.LG)
        .backgroundColor(Colors.PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Text('WordPress CMS')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)
          .margin({ top: Spacing.MD })

        Text('登录以继续使用')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: Spacing.XS })

        Row() {
          SymbolGlyph($r('sys.symbol.lock_shield'))
            .fontSize(Typography.CAPTION)
            .fontColor([Colors.TEXT_HINT])
          Text('数据存储在本地，不上传服务器')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_HINT)
            .margin({ left: Spacing.XS })
        }
        .margin({ top: Spacing.SM })
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: Spacing.XL })

      // Tab 切换 — 登录/注册
      Row() {
        Text('登录')
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.activeTab === 0 ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: Spacing.MD, bottom: Spacing.MD })
          .borderWidth({ bottom: 2 })
          .borderColor(this.activeTab === 0 ? Colors.PRIMARY : 'transparent')
          .onClick(() => {
            if (!this.isLoading) {
              this.activeTab = 0
            }
          })

        Text('注册')
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.activeTab === 1 ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: Spacing.MD, bottom: Spacing.MD })
          .borderWidth({ bottom: 2 })
          .borderColor(this.activeTab === 1 ? Colors.PRIMARY : 'transparent')
          .onClick(() => {
            if (!this.isLoading) {
              this.activeTab = 1
            }
          })
      }
      .width('100%')
      .margin({ bottom: Spacing.LG })

      // 表单区域
      if (this.activeTab === 0) {
        this.LoginForm()
      } else {
        this.RegisterForm()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(Colors.BG_PRIMARY)
  }

  @Builder
  LoginForm() {
    Column({ space: Spacing.BASE }) {
      // 邮箱输入
      Column({ space: Spacing.XS }) {
        Text('邮箱')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入邮箱', text: this.loginEmail })
          .type(InputType.Email)
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isLoading)
          .onChange((value: string) => {
            this.loginEmail = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 密码输入
      Column({ space: Spacing.XS }) {
        Text('密码')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入密码', text: this.loginPassword })
          .type(InputType.Password)
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isLoading)
          .onChange((value: string) => {
            this.loginPassword = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 登录按钮
      Button(this.isLoading ? '登录中...' : '登录', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleLogin()
        })
        .margin({ top: Spacing.SM })
    }
    .width('100%')
  }

  @Builder
  RegisterForm() {
    Column({ space: Spacing.BASE }) {
      // 邮箱输入
      Column({ space: Spacing.XS }) {
        Text('邮箱')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入邮箱', text: this.registerEmail })
          .type(InputType.Email)
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isLoading)
          .onChange((value: string) => {
            this.registerEmail = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 密码输入
      Column({ space: Spacing.XS }) {
        Text('密码')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入密码（至少6位）', text: this.registerPassword })
          .type(InputType.Password)
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isLoading)
          .onChange((value: string) => {
            this.registerPassword = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 确认密码
      Column({ space: Spacing.XS }) {
        Text('确认密码')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
          .type(InputType.Password)
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isLoading)
          .onChange((value: string) => {
            this.confirmPassword = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 注册按钮
      Button(this.isLoading ? '注册中...' : '注册', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleRegister()
        })
        .margin({ top: Spacing.SM })
    }
    .width('100%')
  }

  // ========== 业务逻辑 ==========

  private async handleLogin(): Promise<void> {
    if (this.loginEmail.length === 0 || this.loginPassword.length === 0) {
      UiFeedback.showToast({ message: '请填写邮箱和密码' })
      return
    }

    this.isLoading = true
    try {
      const result: AuthResult = await AuthService.login(this.loginEmail, this.loginPassword)
      if (result.success && result.user !== null) {
        AuthService.applySession(result.user)
        UiFeedback.showToast({ message: '登录成功' })
      } else {
        UiFeedback.showToast({ message: result.error })
      }
    } catch (err) {
      Logger.error('Login error: %{public}s', String(err))
      UiFeedback.showToast({ message: '登录失败，请重试' })
    } finally {
      this.isLoading = false
    }
  }

  private async handleRegister(): Promise<void> {
    if (this.registerEmail.length === 0 || this.registerPassword.length === 0 || this.confirmPassword.length === 0) {
      UiFeedback.showToast({ message: '请填写所有字段' })
      return
    }
    if (!isValidEmail(this.registerEmail)) {
      UiFeedback.showToast({ message: '请输入有效的邮箱地址' })
      return
    }
    if (this.registerPassword !== this.confirmPassword) {
      UiFeedback.showToast({ message: '两次输入的密码不一致' })
      return
    }
    if (this.registerPassword.length < 6) {
      UiFeedback.showToast({ message: '密码长度至少6位' })
      return
    }

    this.isLoading = true
    try {
      const result: AuthResult = await AuthService.register(this.registerEmail, this.registerPassword)
      if (result.success && result.user !== null) {
        AuthService.applySession(result.user)
        UiFeedback.showToast({ message: '注册成功，已自动登录' })
      } else {
        UiFeedback.showToast({ message: result.error })
      }
    } catch (err) {
      Logger.error('Register error: %{public}s', String(err))
      UiFeedback.showToast({ message: '注册失败，请重试' })
    } finally {
      this.isLoading = false
    }
  }
}
