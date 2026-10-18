import socket from '@ohos.net.socket';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';


let udpSocket = socket.constructUDPSocketInstance();

interface GeneratedObjectLiteralInterface_1 {
  address: string;
  port: number;
  family: number;
}

interface GeneratedObjectLiteralInterface_2 {
  address: string;
  port: number;
  family: number;
}

export class UdpConnector{
  msgHistory: string = ''
  //要发送的信息
  sendMsg: string = ''
  //本地端口
  localPort: number = 9990

  //服务端IP地址
  // serverIp: string = "192.168.5.1"
  serverIp: string = "192.168.1.6"

  //服务端端口
  serverPort: number = 1111


  //发送消息到目的ip和端口
  sendMsg2Target() {
    //目的ip和端口
    let remoteAddress: GeneratedObjectLiteralInterface_1 = { address: this.serverIp, port: this.serverPort, family: 1 }
    udpSocket.send({ data: this.sendMsg, address: remoteAddress })
      .then(async () => {
        this.msgHistory += "我:" + this.sendMsg + await this.getCurrentTimeString() + "\r\n"
      })
      .catch((e:Error) => {
        this.msgHistory += '发送失败' + e.message + "\r\n";
      })
  }


  async bindUdpIpPort(){
    let localAddress: GeneratedObjectLiteralInterface_2 = { address: "0.0.0.0", port: this.localPort, family: 1 }

    // 绑定本地IP和端口

    await udpSocket.bind(localAddress)
      .then(() => {
        this.msgHistory = 'bind success' + "\r\n";
      })
      .catch((e:Error) => {
        this.msgHistory = 'bind fail' + e.message + "\r\n";
      })

    //收到消息时的处理
    udpSocket.on("message", async (value) => {
      let msg = this.buf2String(value.message)
      let remoteIP = value.remoteInfo.address
      let remotePort = value.remoteInfo.port.toString()
      //对端ip地址和端口的字符串形式
      let remoteAddr = "[" + remoteIP + ":" + remotePort + "]:"
      let time = await this.getCurrentTimeString()
      this.msgHistory += remoteAddr + msg + time + "\r\n"
    })
  }

  udpClose(){
    udpSocket?.off('message')
    udpSocket?.close()
  }

  //同步获取当前时间的字符串形式
  async  getCurrentTimeString() {
  let time = ""
  await  systemDateTime.getDate().then(
    (date) => {
      time = date.getHours().toString() + ":" + date.getMinutes().toString()
        + ":" + date.getSeconds().toString()
    }
  )
  return "[" + time + "]"
}

  //ArrayBuffer转utf8字符串
   buf2String(buf: ArrayBuffer) {
  let msgArray = new Uint8Array(buf);
  let textDecoder = util.TextDecoder.create("utf-8");
  return textDecoder.decodeWithStream(msgArray)
}
}