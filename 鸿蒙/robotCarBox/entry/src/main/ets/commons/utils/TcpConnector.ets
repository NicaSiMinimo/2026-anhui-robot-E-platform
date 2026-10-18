import socket from '@ohos.net.socket';
import systemDateTime from '@ohos.systemDateTime';
import util from '@ohos.util';
import promptAction from '@ohos.promptAction';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { CommonParameters } from '../constants/CommonParameters';
import { logger } from '.';
import { BusinessError } from '@kit.BasicServicesKit';

//执行TCP通讯的对象
let tcpSocket = socket.constructTCPSocketInstance();

// 原始字符串
// {"temp":25.6, "humi":50.5;}

// 定义参数对象类型
interface QueryParams {

  humi?: number;
  temp?: number;

}

function parseQueryString(query: string): Record<string, string> {
  const params: Record<string, string> = {};
  const pairs = query.split('&');

  for (const pair of pairs) {
    const parts = pair.split('=');
    const key = parts[0];
    const value = parts[1];
    params[key] = value; // 允许动态键，但需确保后续使用时的类型安全
  }
  return params;
}


// // 调用示例
// let queryString = "uid=333&topic=2222&humi=4444&temperature=555&smoggy=666";
// const params = parseQueryString(queryString) as QueryParams;
// console.log(JSON.stringify(params)); // 输出解析后的对象


class TcpConnector {

  //获取应用上下文
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  //连接、通讯历史记录
  msgHistory: string = ''
  //要发送的信息
  sendMsg: string = ''
  //本地端口
  localPort: number = 9990

  //服务端IP地址
  // serverIp: string = "192.168.5.1"
  // serverIp: string = "192.168.1.6"

  //服务端端口
  // serverPort: number = 1111
  // serverPort: number = 8888

  //是否可以连接
  canConnect: boolean = false
  //是否可以发送消息
  canSend: boolean = false
  scroller: Scroller = new Scroller()
  // publi_mes:string =  "cmd=2&uid="+CommonParameters.secret_key+"&topic="+CommonParameters.public_topic+"\r\n"
  // sub_mes:string =  "cmd=1&uid="+CommonParameters.secret_key+"&topic="+CommonParameters.sub_topic+"\r\n"

  //与服务器建立连接
  tcppub(serverIp:string,serverPort:number) {
    this.bind2Port();
    this.connect2Server(serverIp,serverPort);
    //确定发布的主题
    // this.sendMsg2Server(this.publi_mes);
  }
  tcpsub(serverIp:string,serverPort:number) {
    this.bind2Port();
    this.connect2Server(serverIp,serverPort);
    //确定发布的主题
    // this.sendMsg2Server(this.sub_mes);
  }
  //发送消息到服务端
  sendMsg2Server(dat:string) {
    this.sendMsg = dat;
    tcpSocket.send({data:this.sendMsg})
      .then(async () => {
        console.log('TCP Send ok')
      })
  }

  //绑定本地端口
  async bind2Port() {
    //本地地址
    let localAddress:add = { address: "0.0.0.0", port: this.localPort, family: 1 }

    await tcpSocket.bind(localAddress)
      .then(() => {
        this.msgHistory = 'bind success' + "\r\n";
        this.canConnect = true
        console.log('TCP bind success')
        promptAction.showToast({
          message: 'TCP bind success',//显示什么文字
          duration: 400//显示tip的时间--ms
        })
      })

    // 数据格式
    //  uid=333&topic=2222&humi=4444+&temperature=555&smoggy=666
    //
    //
    //
    //
    //



    tcpSocket.on("message", async (value) => {
      let msg = buf2String(value.message)

      const params = parseQueryString(msg) as QueryParams;
      console.log(JSON.stringify(params)); // 输出解析后的对象
      logger.info(msg)

      promptAction.showToast({
        message: JSON.stringify(params),//显示什么文字
        duration: 400//显示tip的时间--ms
      })
      // if(params.uid != CommonParameters.secret_key||params.topic != CommonParameters.sub_topic){
      //   return
      // }
      // {"temp":25.6, "humi":50.5;}
      if (params.temp) {
        CommonParameters.temp = params.temp
      }
      if (params.humi) {
        CommonParameters.humi = params.humi
      }


    })
  }

  closeConnect(){
    tcpSocket.close().then(() => {
      console.log('close success');
    }).catch((err: BusinessError) => {
      console.log('close fail');
    });
    tcpSocket.off('message');

  }

  //连接服务端
  connect2Server(serverIp:string,serverPort:number) {
    //本地地址
    let serverAddress:add = { address: serverIp, port: serverPort, family: 1 }

    tcpSocket.connect({address: serverAddress,
      timeout: 3000})
      .then(() => {
        this.msgHistory = 'connect success ' + "\r\n";
        this.canSend = true
        console.log('TCP connect success')
        promptAction.showToast({
          message: 'TCP connect success',//显示什么文字
          duration: 600//显示tip的时间--ms
        })
      })
  }
}


function getWeekdayIndex() {
  const today = new Date();
  const defaultDayIndex = today.getDay(); // 默认返回0(周日)到6(周六)
  // 调整索引：0(周一)到6(周日)
  return (defaultDayIndex + 6) % 7;
}

//ArrayBuffer转utf8字符串
function buf2String(buf: ArrayBuffer) {
  let msgArray = new Uint8Array(buf);
  let textDecoder = util.TextDecoder.create("utf-8");
  return textDecoder.decodeWithStream(msgArray)
}

interface add{
  address:string,
  port: number,
  family:number
}
export let tcpConnector = new TcpConnector()