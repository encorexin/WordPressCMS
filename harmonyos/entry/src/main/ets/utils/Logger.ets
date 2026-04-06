// 分级日志工具

import hilog from '@ohos.hilog'

const DOMAIN: number = 0x0000
const TAG: string = 'WordPressCMS'

export class Logger {
  static debug(msg: string, ...args: string[]): void {
    let formatted = msg
    for (let i = 0; i < args.length; i++) {
      formatted = formatted.replace('%{public}s', args[i])
    }
    hilog.debug(DOMAIN, TAG, formatted)
  }

  static info(msg: string, ...args: string[]): void {
    let formatted = msg
    for (let i = 0; i < args.length; i++) {
      formatted = formatted.replace('%{public}s', args[i])
    }
    hilog.info(DOMAIN, TAG, formatted)
  }

  static warn(msg: string, ...args: string[]): void {
    let formatted = msg
    for (let i = 0; i < args.length; i++) {
      formatted = formatted.replace('%{public}s', args[i])
    }
    hilog.warn(DOMAIN, TAG, formatted)
  }

  static error(msg: string, ...args: string[]): void {
    let formatted = msg
    for (let i = 0; i < args.length; i++) {
      formatted = formatted.replace('%{public}s', args[i])
    }
    hilog.error(DOMAIN, TAG, formatted)
  }
}
