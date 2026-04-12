// 设计令牌常量 — 严格对照 HarmonyOS Design 规范

export class Colors {
  // 品牌色
  static readonly PRIMARY: string = '#007DFF'

  // 背景色
  static readonly BG_PRIMARY: string = '#FFFFFF'
  static readonly BG_DARK: string = '#121212'
  static readonly BG_SECONDARY: string = '#F2F3F5'
  static readonly BG_CARD: string = '#FFFFFF'
  static readonly BG_CARD_DARK: string = '#1E1E1E'

  // 文字色
  static readonly TEXT_PRIMARY: string = '#121212'
  static readonly TEXT_SECONDARY: string = '#666666'
  static readonly TEXT_HINT: string = '#999999'
  static readonly TEXT_ON_PRIMARY: string = '#FFFFFF'

  // 边框和分隔
  static readonly BORDER: string = '#E4E5E7'
  static readonly DIVIDER: string = '#E4E5E7'
  static readonly ARROW: string = '#B6B7B9'

  // 语义色
  static readonly SUCCESS: string = '#00B578'
  static readonly WARNING: string = '#FF8800'
  static readonly ERROR: string = '#FA2C2C'

  // 按钮状态
  static readonly PRIMARY_PRESSED: string = '#0066CC'
  static readonly PRIMARY_DISABLED: string = '#99CCFF'

  // 状态背景色
  static readonly STATUS_PUBLISHED_BG: string = '#E6F7F0'
  static readonly STATUS_PUBLISHED_TEXT: string = '#00B578'
  static readonly STATUS_DRAFT_BG: string = '#F2F3F5'
  static readonly STATUS_DRAFT_TEXT: string = '#666666'
  static readonly STATUS_PENDING_BG: string = '#FFF3E0'
  static readonly STATUS_PENDING_TEXT: string = '#FF8800'
  static readonly STATUS_GENERATING_BG: string = '#E6F0FF'
  static readonly STATUS_GENERATING_TEXT: string = '#007DFF'
}

// 资源化颜色令牌（支持 base/dark 资源限定符自动切换）
export class ResourceColors {
  static readonly PRIMARY: ResourceColor = $r('app.color.primary')
  static readonly PRIMARY_PRESSED: ResourceColor = $r('app.color.primary_pressed')
  static readonly PRIMARY_DISABLED: ResourceColor = $r('app.color.primary_disabled')

  static readonly BG_PRIMARY: ResourceColor = $r('app.color.bg_primary')
  static readonly BG_SECONDARY: ResourceColor = $r('app.color.bg_secondary')
  static readonly BG_CARD: ResourceColor = $r('app.color.bg_card')
  static readonly OVERLAY_MASK: ResourceColor = $r('app.color.overlay_mask')
  static readonly OVERLAY_MASK_STRONG: ResourceColor = $r('app.color.overlay_mask_strong')
  static readonly SHADOW_FLOATING: ResourceColor = $r('app.color.shadow_floating')
  static readonly INFO_SOFT_BG: ResourceColor = $r('app.color.info_soft_bg')
  static readonly SUCCESS_SOFT_BG: ResourceColor = $r('app.color.success_soft_bg')
  static readonly WARNING_SOFT_BG: ResourceColor = $r('app.color.warning_soft_bg')
  static readonly ERROR_SOFT_BG: ResourceColor = $r('app.color.error_soft_bg')

  static readonly TEXT_PRIMARY: ResourceColor = $r('app.color.text_primary')
  static readonly TEXT_SECONDARY: ResourceColor = $r('app.color.text_secondary')
  static readonly TEXT_HINT: ResourceColor = $r('app.color.text_hint')
  static readonly TEXT_ON_PRIMARY: ResourceColor = $r('app.color.text_on_primary')

  static readonly BORDER: ResourceColor = $r('app.color.border')
  static readonly DIVIDER: ResourceColor = $r('app.color.divider')
  static readonly ARROW: ResourceColor = $r('app.color.arrow')

  static readonly SUCCESS: ResourceColor = $r('app.color.success')
  static readonly WARNING: ResourceColor = $r('app.color.warning')
  static readonly ERROR: ResourceColor = $r('app.color.error')

  // 状态背景色（支持深浅模式）
  static readonly STATUS_PUBLISHED_BG: ResourceColor = $r('app.color.success_soft_bg')
  static readonly STATUS_PUBLISHED_TEXT: ResourceColor = $r('app.color.success')
  static readonly STATUS_DRAFT_BG: ResourceColor = $r('app.color.bg_secondary')
  static readonly STATUS_DRAFT_TEXT: ResourceColor = $r('app.color.text_secondary')
  static readonly STATUS_PENDING_BG: ResourceColor = $r('app.color.warning_soft_bg')
  static readonly STATUS_PENDING_TEXT: ResourceColor = $r('app.color.warning')
  static readonly STATUS_GENERATING_BG: ResourceColor = $r('app.color.info_soft_bg')
  static readonly STATUS_GENERATING_TEXT: ResourceColor = $r('app.color.primary')
}

export class Typography {
  static readonly TITLE_LARGE: number = 32
  static readonly TITLE: number = 24
  static readonly SUBTITLE: number = 20
  static readonly BODY_LARGE: number = 16
  static readonly BODY: number = 14
  static readonly CAPTION: number = 12
  static readonly LABEL: number = 11
}

export class Spacing {
  static readonly XS: number = 4
  static readonly SM: number = 8
  static readonly MD: number = 12
  static readonly BASE: number = 16
  static readonly LG: number = 24
  static readonly XL: number = 32
  static readonly SAFE_MARGIN: number = 16
}

export class Radius {
  static readonly SM: number = 8
  static readonly MD: number = 12
  static readonly LG: number = 16
  static readonly XL: number = 20
  static readonly FULL: number = 9999
}

export class ComponentSize {
  static readonly BUTTON_HEIGHT: number = 48
  static readonly BUTTON_HEIGHT_COMPACT: number = 40
  static readonly INPUT_HEIGHT: number = 48
  static readonly LIST_ITEM_HEIGHT: number = 64
  static readonly LIST_ITEM_HEIGHT_LARGE: number = 72
  static readonly ICON_SM: number = 16
  static readonly ICON_MD: number = 24
  static readonly ICON_LG: number = 32
  static readonly TAB_BAR_HEIGHT: number = 56
}

export class AnimDuration {
  static readonly FAST: number = 150
  static readonly NORMAL: number = 300
  static readonly SLOW: number = 500
}
