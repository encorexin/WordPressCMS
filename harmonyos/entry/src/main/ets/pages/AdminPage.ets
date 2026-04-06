// 用户管理页面 — 对标 React Admin.tsx

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { User } from '../models/User'
import { UserDao } from '../services/db/UserDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'

@Component
export struct AdminPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''
  @StorageProp('currentUserRole') currentUserRole: string = 'user'

  @State users: User[] = []
  @State isLoading: boolean = true

  aboutToAppear(): void {
    this.loadUsers()
  }

  // ========== 构建 UI ==========

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部工具栏
          this.ToolbarArea()

          // 内容区
          if (this.currentUserRole !== 'admin') {
            this.AccessDeniedView()
          } else if (this.isLoading) {
            this.LoadingView()
          } else if (this.users.length === 0) {
            this.EmptyView()
          } else {
            this.UserList()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BG_PRIMARY)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========== 工具栏 ==========

  @Builder
  ToolbarArea() {
    Row() {
      // 标题 + 用户数量
      Column({ space: Spacing.XS }) {
        Text('用户管理')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)
        Text(`共 ${this.users.length} 位用户`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 占位
      Row()
        .width(60)
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }

  // ========== 加载中 ==========

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(Colors.PRIMARY)
      Text('加载中...')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ========== 空状态 ==========

  @Builder
  EmptyView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.person_2'))
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无用户')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('系统中没有任何用户数据')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 无权访问 ==========

  @Builder
  AccessDeniedView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(64)
        .fontColor([Colors.ERROR])
        .opacity(0.5)

      Text('无权访问')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('仅管理员可以访问此页面')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)

      Button('返回', { type: ButtonType.Capsule })
        .width(120)
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .margin({ top: Spacing.MD })
        .onClick(() => {
          this.navPathStack.pop()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 用户列表 ==========

  @Builder
  UserList() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        ForEach(this.users, (user: User) => {
          this.UserCard(user)
        }, (user: User) => user.id)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  UserCard(user: User) {
    Column({ space: Spacing.MD }) {
      // 第一行：邮箱 + 角色徽章
      Row() {
        Row({ space: Spacing.SM }) {
          SymbolGlyph($r('sys.symbol.person_2'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([Colors.PRIMARY])

          Text(user.email)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)

        this.RoleBadge(user.role)
      }
      .width('100%')

      // 第二行：用户 ID + 创建日期
      Row({ space: Spacing.MD }) {
        Text(`ID: ${user.id.substring(0, 8)}`)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_HINT)

        Text(`注册于: ${this.formatDate(user.createdAt)}`)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_HINT)
      }
      .width('100%')

      // 第三行：操作按钮
      Row({ space: Spacing.SM }) {
        if (user.id === this.currentUserId) {
          Text('当前用户')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.PRIMARY)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 4, bottom: 4 })
            .borderRadius(Radius.SM)
            .backgroundColor('#E8F3FF')
        } else {
          Button(user.role === 'admin' ? '设为普通用户' : '设为管理员', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.BG_SECONDARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontSize(Typography.BODY)
            .onClick(() => {
              this.confirmToggleRole(user)
            })

          Button('删除', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.ERROR)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY)
            .onClick(() => {
              this.confirmDeleteUser(user)
            })
        }

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  RoleBadge(role: string) {
    if (role === 'admin') {
      Row({ space: Spacing.XS }) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(12)
          .fontColor([Colors.TEXT_ON_PRIMARY])

        Text('管理员')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: Spacing.SM, right: Spacing.SM, top: 4, bottom: 4 })
      .borderRadius(Radius.FULL)
      .backgroundColor(Colors.PRIMARY)
    } else {
      Text('普通用户')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .padding({ left: Spacing.SM, right: Spacing.SM, top: 4, bottom: 4 })
        .borderRadius(Radius.FULL)
        .backgroundColor(Colors.BG_PRIMARY)
        .borderWidth(1)
        .borderColor(Colors.BORDER)
    }
  }

  // ========== 业务逻辑 ==========

  private async loadUsers(): Promise<void> {
    if (this.currentUserRole !== 'admin') {
      this.isLoading = false
      return
    }

    this.isLoading = true
    try {
      this.users = await UserDao.findAll()
    } catch (err) {
      Logger.error('Load users failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载用户列表失败' })
    } finally {
      this.isLoading = false
    }
  }

  private confirmToggleRole(user: User): void {
    if (user.id === this.currentUserId) {
      UiFeedback.showToast({ message: '不能修改自己的角色' })
      return
    }

    const newRole = user.role === 'admin' ? 'user' : 'admin'
    const roleLabel = newRole === 'admin' ? '管理员' : '普通用户'

    UiFeedback.showConfirm({
      title: '确认更改角色',
      message: `确定要将 ${user.email} 的角色更改为"${roleLabel}"吗？`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认更改',
        fontColor: Colors.PRIMARY,
        action: () => {
          this.handleToggleRole(user.id, newRole)
        }
      }
    })
  }

  private async handleToggleRole(userId: string, newRole: string): Promise<void> {
    try {
      await UserDao.updateRole(userId, newRole)
      UiFeedback.showToast({ message: '角色更新成功', duration: 2000 })
      await this.loadUsers()
    } catch (err) {
      Logger.error('Update role failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '角色更新失败' })
    }
  }

  private confirmDeleteUser(user: User): void {
    if (user.id === this.currentUserId) {
      UiFeedback.showToast({ message: '不能删除自己' })
      return
    }

    UiFeedback.showConfirm({
      title: '确认删除',
      message: `确定要删除用户 ${user.email} 吗？此操作无法撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认删除',
        fontColor: Colors.ERROR,
        action: () => {
          this.handleDeleteUser(user.id)
        }
      }
    })
  }

  private async handleDeleteUser(userId: string): Promise<void> {
    try {
      await UserDao.deleteById(userId)
      UiFeedback.showToast({ message: '用户已删除', duration: 2000 })
      await this.loadUsers()
    } catch (err) {
      Logger.error('Delete user failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }

  private formatDate(timestamp: string): string {
    if (timestamp.length === 0) {
      return '未知'
    }
    try {
      const date = new Date(timestamp)
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, '0')
      const day = date.getDate().toString().padStart(2, '0')
      const hours = date.getHours().toString().padStart(2, '0')
      const minutes = date.getMinutes().toString().padStart(2, '0')
      return `${year}-${month}-${day} ${hours}:${minutes}`
    } catch {
      return timestamp
    }
  }
}
