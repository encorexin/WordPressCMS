import UIAbility from '@ohos.app.ability.UIAbility'
import hilog from '@ohos.hilog'
import window from '@ohos.window'
import Want from '@ohos.app.ability.Want'
import AbilityConstant from '@ohos.app.ability.AbilityConstant'
import { DatabaseHelper } from '../services/db/DatabaseHelper'
import { AppStore } from '../stores/AppStore'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'WordPressCMS', '%{public}s', 'Ability onCreate')

    // 初始化全局状态
    AppStore.initialize()
  }

  onDestroy(): void {
    hilog.info(0x0000, 'WordPressCMS', '%{public}s', 'Ability onDestroy')
    DatabaseHelper.close()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'WordPressCMS', '%{public}s', 'Ability onWindowStageCreate')

    // 数据库初始化完成后再加载页面
    DatabaseHelper.initialize(this.context).then(() => {
      hilog.info(0x0000, 'WordPressCMS', 'Database initialized')
      windowStage.loadContent('pages/Index', (err: Error) => {
        if (err) {
          hilog.error(0x0000, 'WordPressCMS', 'Failed to load content: %{public}s', err.message ?? '')
          return
        }
        hilog.info(0x0000, 'WordPressCMS', 'Content loaded successfully.')
      })
    }).catch((err: Error) => {
      hilog.error(0x0000, 'WordPressCMS', 'Database init failed: %{public}s', String(err))
      // 即使数据库初始化失败也加载页面，让用户看到错误提示
      windowStage.loadContent('pages/Index')
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'WordPressCMS', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(0x0000, 'WordPressCMS', '%{public}s', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(0x0000, 'WordPressCMS', '%{public}s', 'Ability onBackground')
  }
}
