import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uint8ArrayToString } from './Utils';
import { CommonParameters } from '../constants/CommonParameters';
import { kvUtil } from './distkv';
import PreferenceUtil from './PreferenceUtil';
import json from '@ohos.util.json';
// 07686582488  xhqy
const TAG = "[udpSocket]"
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
// 创建UDP socket
let udpSocket = socket.constructUDPSocketInstance();
export async  function   receveMessage( ){
  // 绑定本地IP和端口
  udpSocket.bind({ address: '0.0.0.0', port: 3863, family: 1 },  (err: BusinessError) => {
    if (err) {
      console.error('bind failed, err: ' + JSON.stringify(err));
      return;
    }
    console.log('bind success');
    // 接收UDP数据
    udpSocket?.on('message', async (data: socket.SocketMessageInfo) => {
      console.log(TAG,'received data: ' +json.stringify(data) );
      // 判断是否扫描中

      // let stringData = uint8ArrayToHexStr(new Uint8Array(data.message));
      let stringData = uint8ArrayToString(new Uint8Array(data.message));
     // await kvUtil.put("stringData",stringData+"")
        console.log(TAG,'stringData:', stringData);
      if (JSON.parse(stringData).device_id == "robotDog") {
        console.log(TAG,JSON.parse(stringData).device_id)
       PreferenceUtil.saveIP(data.remoteInfo.address)
        console.log(TAG,data.remoteInfo.address)

      }
        // console.log(TAG,"getIsFirstOpen",PreferenceUtil.getIsFirstOpen())
      try {

        let addDeviceResult = await PreferenceUtil.addDevice(JSON.parse(stringData));
        console.log(TAG, 'addDevice result:', addDeviceResult);
      }catch (e) {
        console.error(TAG, 'caller error:', e);
      }


      console.log(TAG,'stringData2:', stringData);
      console.log('from address: ' + data.remoteInfo.address);
      console.log('from port: ' + data.remoteInfo.port);
      // this.udpDevice = new UdpDevice()
      // this.udpDevice.deviceName = (JSON.parse(stringData) as Record<string, string>[])['name'].replace('/r', '').replace('/n', '')
      // this.udpDevice.mac = (JSON.parse(stringData) as Record<string, string>[])['mac'].replace(/:/g, '').replace('/r', '').replace('/n', '')
      // this.udpDevice.ip = data.remoteInfo.address
      // this.udpDevice.port = data.remoteInfo.port


    });
  });

  let udpextraoptions: socket.UDPExtraOptions = {
    receiveBufferSize: 100000,
    sendBufferSize: 100000,
    reuseAddress: false,
    socketTimeout: 6000,
    broadcast: true //一定要设置，不然不允许发送广播
  }
  await udpSocket.setExtraOptions(udpextraoptions).then(() => {
    console.log('setExtraOptions success');
  }).catch((err: BusinessError) => {
    console.log('setExtraOptions fail');
  });
}

interface GeneratedObjectLiteralInterface_1 {
  address: string;
  port: number;
  family: number;
}

export function sendMessage(ledSwith:boolean){
  let remoteAddress: GeneratedObjectLiteralInterface_1  = { address: '255.255.255.255', port: 3863, family: 1 }
  let data:deviceItem = {
    "device_id":    "123456",
    "device_name":  "def",
    "cmd_type":     "publish",
    "device_type":  "def",
    "service_cnt":  1,
    "service_name1":        "ledswitch",
    "topic":        "led12",
    "messagejson":  {
      "valtcnt":      2,
      "valtype_1":    "ledswitch",
      "valnum_1":     ledSwith?"on":"off"
    }
  }
  udpSocket?.send({ data:json.stringify(data), address: remoteAddress })
    .then(async (datas) => {

      console.log(TAG,"发送数据成功",json.stringify(data))

    })
    .catch((e:Error) => {
      console.log(TAG,"发送数据失败",e)
    })
}

export function   close() {


  udpSocket?.off('message')
  udpSocket?.close()
}