import { distributedKVStore } from '@kit.ArkData';
import { bundleManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = "[sqlutil]"

export default class KVUtils {
  private kvManager: distributedKVStore.KVManager | undefined = undefined;
  private context = getContext(this);
  private kvStore: distributedKVStore.SingleKVStore | undefined = undefined;
  private bundleName: string = 'com.example.interconnection';
  private isInitialized = false; // 新增初始化状态标识
  private initPromise: Promise<void>; // 初始化Promise

  constructor() {
    this.initPromise = new Promise((resolve) => {

      let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
    bundleManager.getBundleInfoForSelf(bundleFlags, (err, data) => {
      this.bundleName = data.name;
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        context: this.context,
        bundleName: this.bundleName
      };
      this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      const options: distributedKVStore.Options = {
        createIfMissing: true, //数据库文件不存在时是否创建数据库
        backup: false, //是否备份数据库文件
        autoSync: true, //是否自动同步
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION, //数据库类型
        encrypt: true, //是否加密
        securityLevel: distributedKVStore.SecurityLevel.S1//安全等级
      };
      //获取kvStore实例
      this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(`harmony_utils_store`, options,
        (err, store: distributedKVStore.SingleKVStore) => {
          if (err) {
            //获取失败
            return;
          }
          //获取成功
          this.kvStore = store;
          this.isInitialized = true; // 标记初始化完成
          resolve(); // 解析Promise

          console.log(TAG, 'KVStore is initialized');
        });
    })
    });


  }
  async ensureInitialized() {
    if (!this.isInitialized) {
      await this.initPromise;
    }
  }
  //向数据库中写入数据
  async put(key: string, value: string | number | boolean) {
     this.kvStore!.put(key, value, (err: BusinessError) => {
      if (err != undefined) {
        console.error(TAG, `Failed to put.code is ${err.code},message is ${err.message}`);
        return;
      }
      console.info(TAG, "Succeeded in putting");
    });
  }

  async get(key: string): Promise<boolean | string | number | Uint8Array | null> {
    try {
      const data = await this.kvStore!.get(key);
      console.info(TAG, `Succeeded in getting data.data=${data}`);
      return data;
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to get. code is ${error.code}, message is ${error.message}`);
      return null;
    }
  }

  //删除key对应的数据
  delete(key: string) {
    this.kvStore!.delete(key, (err) => {
      if (err !== undefined) {
        hilog.error(0x0000, 'KVUtils', `Failed to delete data. Code:${err.code},message:${err.message}`);
        return;
      }
      hilog.info(0x0000, 'KVUtils', 'Succeeded in deleting data.');
    });
  }

  async  registerDataChangeListener(
    key: string,
    callback: (newValue: string | number | boolean | Uint8Array) => void
  ){


    try {

      await this.ensureInitialized(); // 等待初始化完成
      if (this.kvStore == undefined) {
        console.error(TAG, 'KVStore not initialized');
        // while (this.kvStore == undefined){
        //   console.error(TAG, 'KVStore not initialized');
        //
        // }
      }
      //订阅
        this.kvStore!.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, (data) => {
          console.info(TAG, `dataChange callback call data: ${data}`);
          const changedEntry = data.updateEntries.find(e => e.key === key)?.value.value.toString();

          console.info(TAG, `dataChange callback call data: ${changedEntry}`);

          if (changedEntry) {
            callback(changedEntry+''); // 直接传递新值
          }



      })

    } catch (e) {
      let error = e as BusinessError;
      console.error(TAG, `An unexpected error occurred. code:${error.code},message:${error.message}`);
    }
  }

  async syncDevice(deviceIds:  string[]) {
    try {
      // 1000表示最大延迟时间为1000ms
      this.kvStore?.sync(deviceIds, distributedKVStore.SyncMode.PUSH_PULL);
      console.log(`syncDevice开始`);

    } catch (e) {
      let error = e as BusinessError;
      console.error(`An unexpected error occurred. Code:${error.code},message:${error.message}`);
    }

  }



}

export let kvUtil = new KVUtils()

