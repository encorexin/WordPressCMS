import webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  private webController: webview.WebviewController = new webview.WebviewController();
  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  getMimeType(path: string): string {
    const ext = path.split('.').pop()?.toLowerCase() || '';
    const types: Record<string, string> = {
      'html': 'text/html', 'htm': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript', 'mjs': 'application/javascript',
      'json': 'application/json',
      'png': 'image/png',
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon',
      'woff': 'font/woff',
      'woff2': 'font/woff2',
      'ttf': 'font/ttf',
      'otf': 'font/otf',
      'eot': 'application/vnd.ms-fontobject',
    };
    return types[ext] || 'application/octet-stream';
  }

  build() {
    Column() {
      Web({ 
        src: $rawfile('index.html'), 
        controller: this.webController 
      })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.None)
        .darkMode(WebDarkMode.Auto)
        .width('100%')
        .height('100%')
        .onPageBegin((event: OnPageBeginEvent) => {
          console.info('[WebView] Page begin: ' + event?.url);
        })
        .onPageEnd((event: OnPageEndEvent) => {
          console.info('[WebView] Page end: ' + event?.url);
        })
        .onErrorReceive((event: OnErrorReceiveEvent) => {
          console.error('[WebView] Error: ' + event?.error.getErrorInfo());
        })
        .onInterceptRequest((event: OnInterceptRequestEvent) => {
          if (!event || !this.context) {
            return new WebResourceResponse();
          }
          
          const request = event.request;
          const url = request.getRequestUrl();
          console.info('[WebView] Intercept: ' + url);
          
          let filePath = url;
          if (url.startsWith('resource://rawfile/')) {
            filePath = url.substring('resource://rawfile/'.length);
          } else if (url.includes('/rawfile/')) {
            const parts = url.split('/rawfile/');
            filePath = parts.length > 1 ? parts[1] : '';
          }
          
          filePath = decodeURIComponent(filePath);
          console.info('[WebView] Loading: ' + filePath);
          
          try {
            const rawData = this.context.resourceManager.getRawFileContentSync(filePath);
            const mimeType = this.getMimeType(filePath);
            console.info('[WebView] Loaded: ' + filePath + ' (' + mimeType + ')');
            return new WebResourceResponse(mimeType, 'UTF-8', rawData);
          } catch (e) {
            console.error('[WebView] Failed to load: ' + filePath + ', error: ' + e);
            return new WebResourceResponse();
          }
        })
    }
    .width('100%')
    .height('100%')
  }
}
