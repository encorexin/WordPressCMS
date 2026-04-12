import UIAbility from '@ohos.app.ability.UIAbility'
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry'
import hilog from '@ohos.hilog'
import { Hypium } from '@ohos/hypium'
import testsuite from '../test/List.test'

export default class TestAbility extends UIAbility {
  onCreate(want: object, launchParam: object): void {
    hilog.info(0x0000, 'WordPressCMS_Test', '%{public}s', 'TestAbility onCreate')
    hilog.info(0x0000, 'WordPressCMS_Test', '%{public}s', JSON.stringify(want) ?? '')
    hilog.info(0x0000, 'WordPressCMS_Test', '%{public}s', JSON.stringify(launchParam) ?? '')

    const abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator()
    const abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments()
    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite)
  }
}
