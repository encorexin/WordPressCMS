// UI 反馈工具 — 集中处理 toast / confirm 弹窗，捕获异常并记录日志

import promptAction from '@ohos.promptAction'
import { Logger } from './Logger'

type ConfirmHandler = (options: ConfirmOptions) => void

export interface ToastOptions {
  message: string
  duration?: number
}

export interface ConfirmButton {
  value: string
  fontColor?: string
  action: () => void
}

export interface ConfirmOptions {
  title: string
  message: string
  autoCancel?: boolean
  primaryButton: ConfirmButton
  secondaryButton: ConfirmButton
}

export class UiFeedback {
  private static confirmHandler: ConfirmHandler | null = null

  static setConfirmHandler(handler: ConfirmHandler | null): void {
    UiFeedback.confirmHandler = handler
  }

  static showToast(options: ToastOptions): void {
    try {
      promptAction.openToast({ message: options.message, duration: options.duration })
    } catch (err) {
      Logger.error('UiFeedback.showToast failed: %{public}s', String(err))
    }
  }

  static showConfirm(options: ConfirmOptions): void {
    try {
      if (UiFeedback.confirmHandler === null) {
        Logger.error('UiFeedback.showConfirm failed: confirm handler unavailable')
        return
      }

      UiFeedback.confirmHandler(options)
    } catch (err) {
      Logger.error('UiFeedback.showConfirm failed: %{public}s', String(err))
    }
  }
}
