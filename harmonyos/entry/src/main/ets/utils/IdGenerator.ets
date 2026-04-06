// UUID 生成器 — 生成 v4 UUID

import util from '@ohos.util'

export function generateId(): string {
  try {
    return util.generateRandomUUID(true)
  } catch (err) {
    throw new Error(`Failed to generate UUID: ${String(err)}`)
  }
}
