// 日期工具 — 格式化和时间戳

export function getTimestamp(): string {
  return new Date().toISOString()
}

export function formatDate(isoString: string): string {
  if (isoString.length === 0) {
    return ''
  }
  const date = new Date(isoString)
  if (isNaN(date.getTime())) {
    return ''
  }
  const year = date.getFullYear()
  const month = padZero(date.getMonth() + 1)
  const day = padZero(date.getDate())
  return `${year}-${month}-${day}`
}

export function formatDateTime(isoString: string): string {
  if (isoString.length === 0) {
    return ''
  }
  const date = new Date(isoString)
  if (isNaN(date.getTime())) {
    return ''
  }
  const year = date.getFullYear()
  const month = padZero(date.getMonth() + 1)
  const day = padZero(date.getDate())
  const hours = padZero(date.getHours())
  const minutes = padZero(date.getMinutes())
  return `${year}-${month}-${day} ${hours}:${minutes}`
}

export function formatRelativeTime(isoString: string): string {
  if (isoString.length === 0) {
    return ''
  }
  const date = new Date(isoString)
  if (isNaN(date.getTime())) {
    return ''
  }
  const now = Date.now()
  const target = date.getTime()
  const diff = now - target
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 30) {
    return formatDate(isoString)
  } else if (days > 0) {
    return `${days}天前`
  } else if (hours > 0) {
    return `${hours}小时前`
  } else if (minutes > 0) {
    return `${minutes}分钟前`
  } else {
    return '刚刚'
  }
}

function padZero(num: number): string {
  return num < 10 ? `0${num}` : `${num}`
}
