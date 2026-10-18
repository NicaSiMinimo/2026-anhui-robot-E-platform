import webSocket from '@ohos.net.webSocket';
import { promptAction, router } from '@kit.ArkUI';
import PreferenceUtil from './PreferenceUtil';
import { CommonParameters } from '../constants/CommonParameters';

const TAG = '[webSocket]'
const ws = webSocket.createWebSocket()

export async function bind(){
  await connectWebSokect()
  await  ws.on('open',(err,value)=>{
    if (!err) {
      console.log(TAG,'连接成功')
    }
  })

  await  ws.on('message',(err,value)=>{
    if (!err) {
      console.log(TAG,value,"订阅成功")
    }else {
      console.log(TAG,'订阅错误')

    }
  })

}


function connectWebSokect(){
//  let ip =  PreferenceUtil.getIP()
  ws.connect('ws://'+CommonParameters.IP+':9000',(err,value)=>{
    if (!err) {
      console.log(TAG,"连接成功",CommonParameters.IP)
      promptAction.showToast({
        message: '连接成功',
        duration: 2000, // 停留时间（毫秒）
        bottom: 50, // 距离底部的距离
      });    }else {
      console.log(TAG,'连接错误',CommonParameters.IP)
      // promptAction.showToast({
      //   message: '请确认设备处于同一局域网中',
      //   duration: 2000, // 停留时间（毫秒）
      //   bottom: 50, // 距离底部的距离
      // });
    }
  })
}

export function send(data:string){
  ws.send(data,(err,value)=>{
    if (!err) {
      console.log(TAG,value,"发送消息成功")
    }else {
      console.log(TAG,'发送消息错误')

    }
  })
}