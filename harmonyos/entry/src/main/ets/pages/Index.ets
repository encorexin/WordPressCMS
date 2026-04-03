import webview from '@ohos.web.webview';

@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ 
        src: $rawfile('index.html'), 
        controller: this.controller 
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
          console.info('Page begin: ' + event?.url);
        })
        .onPageEnd((event: OnPageEndEvent) => {
          console.info('Page end: ' + event?.url);
        })
        .onErrorReceive((event: OnErrorReceiveEvent) => {
          console.error('Error: ' + event?.error.getErrorInfo());
        })
    }
    .width('100%')
    .height('100%')
  }
}
