import { preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BusinessError } from '@kit.BasicServicesKit';
import { EventBus } from './emmiter';
import json from '@ohos.util.json';

type PreferenceValueType = string | number | boolean | object | null;

const TAG: string = 'PreferenceUtil'
const FAVORITE_LIST_KEY = 'list_key'

const CONFIG_FILE_NAME = 'configPreference'  // 文件名
const FONT_SIZE_KEY = 'font_size_key'  // key
const IS_FIRST_OPEN = 'is_first_open'  // key

interface deviceItem {
  device_id: string;
  device_name: string;
  cmd_type: string;
  device_type: string;
  service_cnt: number;
  service_name1: string;
  // 以下字段在 cmd_type 为 'publish' 时存在
  topic?: string; // 使用可选属性，表示可能不存在
  messagejson?: Record<string, string | number>; // 使用键值对对象表示 messagejson
}


interface GeneratedTypeLiteralInterface_1 {
  success: boolean;
  isexists: boolean;
  message: string;
}

interface GeneratedTypeLiteralInterface_2 {
  success: boolean;
  isexists: boolean;
  message: string;
  isPublic:boolean
}

class PreferenceUtil {

  private _preference?: preferences.Preferences | undefined;

  getPreferenceFile(context: Context, fileName: string) {
    this._preference = preferences.getPreferencesSync(context, { name: fileName })
    return this
  }

  // 获取首选项实例
  getConfigPreference(context: Context): PreferenceUtil {
    return this.getPreferenceFile(context, CONFIG_FILE_NAME)
  }

  // 保存信息，传入key、value
  saveConfig(key: string, value: preferences.ValueType) {
    this._preference?.putSync(key, value)

    this._preference?.flush((err: BusinessError) => {
      if (err) {
        hilog.error(0x000, TAG, 'save config failed code =' + err.code + ', message =' + err.message)
      } else hilog.info(0x000, TAG, 'save config success')
    })
  }

  // 删除 key
  deleteKey(key: string) {
    this._preference?.deleteSync(key)
    this._preference?.flush((err: BusinessError) => {
      if (err) {
        hilog.error(0x000, TAG, 'delete config failed code =' + err.code + ', message =' + err.message)
      } else hilog.info(0x000, TAG, 'delete config success')
    })
  }

  // 清除首选项内容
  clearPreference() {
    this._preference?.clearSync()
    this._preference?.flush((err: BusinessError) => {
      if (err) {
        hilog.error(0x000, TAG, 'clear config failed code =' + err.code + ', message =' + err.message)
      } else hilog.info(0x000, TAG, 'clear config success')
    })
  }


  // T 泛型，返回该类型数据
  private getConfig<T>(name: string, defValue: preferences.ValueType): T {
    return this._preference?.getSync(name, defValue) as T
  }


  // 下述为工具类封装的业务场景示例
  getIsFirstOpen() {
    return this.getConfig<boolean>(IS_FIRST_OPEN, false)
  }

  saveIsFirstOpen(value: boolean) {
    this.saveConfig(IS_FIRST_OPEN, value)
  }

  saveIP(value: string) {
    this.saveConfig("robotIp", value)
  }
  getIP() {
    return this.getConfig<string>("robotIp", false)
  }
  getChangeFontSize() {
    return this.getConfig<number>(FONT_SIZE_KEY, 0)
  }



  // 添加设备到数组，并检查 device_id 是否已存在
 async  addDevice(item: deviceItem): Promise<GeneratedTypeLiteralInterface_2> {

     let isPublic = false
   console.log(TAG, 'addDevice is running');
    try {
      // 检查设备是否已存在
      if(item.cmd_type == "publish"){
        isPublic = true
      }
      if (this.isDeviceExists(item.device_id) && item.cmd_type == "publish" && item.messagejson) {
        console.log( TAG, `Device ${item.device_id} already exists`);
        await this.updateDeviceWithSplice(item.device_id,item)
        EventBus.send('ischange', true)

        return { success: true, isexists: true, message: '设备已存在',isPublic:isPublic };
      }

     else if(item.cmd_type == "sync"&& this.getIsFirstOpen()&&!this.isDeviceExists(item.device_id)){

        EventBus.send('newDevice', item.device_name)

      const currentList = this.getDeviceList();
      currentList.push(item);

      this.saveDeviceList(currentList);

      hilog.info(0x000, TAG, `Added device ${item.device_id} successfully, cmd_type: ${item.cmd_type}`);
      return { success: true, isexists: false, message: '添加成功',isPublic:isPublic};
      }
     else{
       return { success: false, isexists: false, message: '添加失败',isPublic:isPublic};

     }
    } catch (error) {

      hilog.error(0x000, TAG, `Add device failed: ${error}`);
      console.log(TAG, 'addDevice is error');

      return { success: false, isexists: false, message: `添加失败: ${error}`,isPublic:isPublic };

    }
  }

  // 从设备数组中移除设备
  removeDevice(deviceId: string): boolean {
    try {
      const currentList = this.getDeviceList();
      const updatedList = currentList.filter(item => item.device_id !== deviceId);

      if (updatedList.length === currentList.length) {
        hilog.warn(0x000, TAG, `Device ${deviceId} not found`);
        return false;
      }

      this.saveDeviceList(updatedList);
      hilog.info(0x000, TAG, `Removed device ${deviceId}`);
      return true;
    } catch (error) {
      hilog.error(0x000, TAG, `Remove device failed: ${error}`);
      return false;
    }
  }

  // 获取设备列表
  getDeviceList(): deviceItem[] {
    try {
      const listJson = this.getConfig<string>(FAVORITE_LIST_KEY, '[]');
      // 使用类型断言避免 any 类型
      const parsedList = JSON.parse(listJson) as deviceItem[];

      return parsedList;
    } catch (error) {
      hilog.error(0x000, TAG, `Get device list failed: ${error}`);
      return [];
    }
  }

  // 检查设备是否存在[1,4](@ref)
  isDeviceExists(deviceId: string): boolean {
    const currentList = this.getDeviceList();
    return currentList.some(item => item.device_id === deviceId);
  }

  // 根据 device_id 获取特定设备，可检查其 cmd_type 和附加字段
  getDeviceById(deviceId: string): deviceItem | undefined {
    const currentList = this.getDeviceList();
    return currentList.find(item => item.device_id === deviceId);
  }
  // 清空设备列表
  clearAllDevices(): void {
    this.saveDeviceList([]);
    hilog.info(0x000, TAG, 'Cleared all devices');
  }

  // 获取设备数量
  getDeviceCount(): number {
    return this.getDeviceList().length;
  }

  // 使用 splice 方法替换数组元素
  updateDeviceWithSplice(deviceId: string, newDevice: deviceItem): boolean {
    try {
      const currentList = this.getDeviceList();
      const itemIndex = currentList.findIndex(item => item.device_id === deviceId);

      if (itemIndex === -1) {
        hilog.warn(0x000, TAG, `Device ${deviceId} not found for update`);
        return false;
      }

      // 使用 splice 方法替换指定位置的元素 [9,10,11](@ref)
      currentList.splice(itemIndex, 1, newDevice);

      this.saveDeviceList(currentList);
      hilog.info(0x000, TAG, `Updated device ${deviceId} using splice method`);
      return true;
    } catch (error) {
      hilog.error(0x000, TAG, `Update device failed: ${error}`);
      return false;
    }
  }

  // 保存设备列表到首选项
  private saveDeviceList(list: deviceItem[]): void {
    try {
      const listJson = JSON.stringify(list);
      this.saveConfig(FAVORITE_LIST_KEY, listJson);
    } catch (error) {
      hilog.error(0x000, TAG, `Save device list failed: ${error}`);
    }
  }


}

export default new PreferenceUtil()
