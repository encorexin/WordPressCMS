import daoMapperTest from './DaoMapper.test'
import retryServiceTest from './RetryService.test'

export default function testsuite(): void {
  daoMapperTest()
  retryServiceTest()
}
