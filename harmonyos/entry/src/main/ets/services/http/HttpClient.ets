// 通用 HTTP 客户端 — 封装 @ohos.net.http

import http from '@ohos.net.http'
import { util } from '@kit.ArkTS'
import { Logger } from '../../utils/Logger'

// 通用响应
export class HttpResponse {
  code: number = 0
  data: string = ''
  success: boolean = false
}

// 请求选项
export class RequestOptions {
  method: http.RequestMethod = http.RequestMethod.GET
  headers: Record<string, string> = {}
  body: string = ''
  timeout: number = 30000
}

export class HttpClient {

  // 普通请求（返回完整响应）
  static async request(url: string, options: RequestOptions): Promise<HttpResponse> {
    const result = new HttpResponse()
    const httpRequest = http.createHttp()

    try {
      const httpOptions: http.HttpRequestOptions = {
        method: options.method,
        header: options.headers,
        readTimeout: options.timeout,
        connectTimeout: 15000
      }

      if (options.body.length > 0) {
        httpOptions.extraData = options.body
      }

      const response = await httpRequest.request(url, httpOptions)
      result.code = response.responseCode
      result.data = response.result as string
      result.success = response.responseCode >= 200 && response.responseCode < 300
    } catch (err) {
      Logger.error('HTTP request failed: %{public}s', String(err))
      result.code = -1
      result.data = String(err)
      result.success = false
    } finally {
      httpRequest.destroy()
    }

    return result
  }

  // GET
  static async get(url: string, headers?: Record<string, string>, timeout?: number): Promise<HttpResponse> {
    const options = new RequestOptions()
    options.method = http.RequestMethod.GET
    if (headers) {
      options.headers = headers
    }
    if (timeout !== undefined && timeout > 0) {
      options.timeout = timeout
    }
    return HttpClient.request(url, options)
  }

  // POST JSON
  static async postJson(url: string, body: string, headers?: Record<string, string>): Promise<HttpResponse> {
    const options = new RequestOptions()
    options.method = http.RequestMethod.POST
    options.body = body
    options.headers = {
      'Content-Type': 'application/json'
    }
    if (headers) {
      const keys = Object.keys(headers)
      for (let i = 0; i < keys.length; i++) {
        options.headers[keys[i]] = headers[keys[i]]
      }
    }
    return HttpClient.request(url, options)
  }

  // 流式请求（SSE）— 返回 HttpRequest 实例供调用方监听事件
  static requestStream(
    url: string,
    body: string,
    headers: Record<string, string>,
    onData: (chunk: ArrayBuffer) => void,
    onComplete: () => void,
    onError: (err: string) => void
  ): http.HttpRequest {
    const httpRequest = http.createHttp()

    const streamHeaders: Record<string, string> = {
      'Content-Type': 'application/json'
    }
    const keys = Object.keys(headers)
    for (let i = 0; i < keys.length; i++) {
      streamHeaders[keys[i]] = headers[keys[i]]
    }

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      onData(data)
    })

    httpRequest.on('dataEnd', () => {
      onComplete()
      httpRequest.off('dataReceive')
      httpRequest.off('dataEnd')
      httpRequest.destroy()
    })

    const streamOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: streamHeaders,
      extraData: body,
      readTimeout: 120000,
      connectTimeout: 15000,
      expectDataType: http.HttpDataType.STRING
    }

    httpRequest.requestInStream(url, streamOptions).then((code: number) => {
      if (code < 200 || code >= 300) {
        onError(`Stream response code: ${code}`)
        httpRequest.destroy()
      }
    }).catch((err: Error) => {
      onError(String(err))
      httpRequest.destroy()
    })

    return httpRequest
  }

  // 创建 Basic Auth 头
  static createBasicAuth(username: string, password: string): string {
    try {
      const raw = `${username}:${password}`
      const helper = new util.Base64Helper()
      const encoder = new util.TextEncoder()
      const encoded = encoder.encodeInto(raw)
      const base64Str = helper.encodeToStringSync(encoded)
      return `Basic ${base64Str}`
    } catch (err) {
      throw new Error(`Failed to create basic auth header: ${String(err)}`)
    }
  }
}
