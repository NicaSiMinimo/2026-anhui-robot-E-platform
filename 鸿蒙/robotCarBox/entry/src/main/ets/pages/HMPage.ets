import webSocket from '@ohos.net.webSocket';
import { MessageEvent } from '@kit.ArkTS';

const ws = webSocket.createWebSocket()


interface GeneratedObjectLiteralInterface_2 {
  x: number;
  y: number;
  z: number;
}

interface GeneratedObjectLiteralInterface_3 {
  x: number;
  y: number;
  z: number;
}

interface GeneratedObjectLiteralInterface_4 {
  linear: GeneratedObjectLiteralInterface_2;
  angular: GeneratedObjectLiteralInterface_3;
}

interface GeneratedObjectLiteralInterface_5 {
  op: string;
  topic: string;
  msg: GeneratedObjectLiteralInterface_4;
}

interface GeneratedTypeLiteralInterface_1 {
  topic: string;
  msg: string;
}

interface GeneratedObjectLiteralInterface_1 {
  op: string;
  topic: string;
  type: string;
}

@Entry
@Component
struct ROS2ControlPanel {
  // 状态变量
  @State ipAddress: string = ''
  @State isConnected: boolean = false
  @State statusText: string = '未连接'

  // 传感器数据
  @State temperature: string = '--'
  @State humidity: string = '--'
  @State distance: string = '--'
  @State light: string = '--'

  // 距离和光照警告状态
  @State distanceWarning: boolean = false
  @State lightWarning: boolean = false

  // 摇杆状态
  @State stickX: number = 0
  @State stickY: number = 0
  @State isJoystickActive: boolean = false

  // WebSocket连接
  private heartbeatTimer: number | null = null

  // 连接ROS
  connectROS() {
    if (!this.ipAddress) {
      this.statusText = '请输入IP地址'
      return
    }

    const url = `ws://${this.ipAddress}:9090`

    ws.connect(url).then(()=> {
      this.isConnected = true
      this.statusText = '已连接'
      this.subscribeTopics()
      this.stopHeartbeat()
    })

    // this.ws.onerror = () => {
    //   this.isConnected = false
    //   this.statusText = '连接失败'
    //   this.stopHeartbeat()
    // }

    ws.close(() => {
      this.isConnected = false
      this.statusText = '连接已断开'
      this.stopHeartbeat()
    })

    ws.on("message",() => {
      this.handleMessage('event.data')
    })

    try {
      ws.connect(url)
    } catch (e) {
      this.statusText = '连接异常'
    }
  }

  // 订阅ROS话题
  subscribeTopics() {
    const topics = ['/temperature', '/humidity', '/distance', '/light']
    topics.forEach(topic => {
      const subscribeMsg: GeneratedObjectLiteralInterface_1 = {
        op: 'subscribe',
        topic: topic,
        type: 'std_msgs/msg/Float32'
      }
      this.sendWebSocketMessage(JSON.stringify(subscribeMsg))
    })
  }

  // 发送消息
  sendWebSocketMessage(message: string) {
    if (ws) {
      ws.send(message)
    }
  }

  // 处理消息
  handleMessage(data: string) {
    try {
      const msg: GeneratedTypeLiteralInterface_1 = JSON.parse(data)
      if (msg.topic && msg.msg && msg.msg !== undefined) {
        const value = parseFloat(msg.msg).toFixed(1)

        switch (msg.topic) {
          case '/temperature':
            this.temperature = value
            break
          case '/humidity':
            this.humidity = value
            break
          case '/distance':
            this.distance = value
            this.distanceWarning = parseFloat(value) < 15
            break
          case '/light':
            this.light = value
            this.lightWarning = parseFloat(value) < 50
            break
        }
      }
    } catch (e) {
      console.error('解析消息失败:', e)
    }
  }

  // 发送速度控制
  sendVel(lin: number, ang: number) {
    const twistMsg: GeneratedObjectLiteralInterface_5 = {
      op: 'publish',
      topic: '/cmd_vel',
      msg: ({
        linear: ({ x: lin, y: 0, z: 0 } as GeneratedObjectLiteralInterface_2),
        angular: ({ x: 0, y: 0, z: ang } as GeneratedObjectLiteralInterface_3)
      } as GeneratedObjectLiteralInterface_4)
    }
    this.sendWebSocketMessage(JSON.stringify(twistMsg))
  }



  stopHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer)
      this.heartbeatTimer = null
    }
  }

  // 摇杆触摸事件处理
  onTouchStart() {
    this.isJoystickActive = true
  }

  onTouchEnd() {
    this.isJoystickActive = false
    this.resetJoystick()
    this.sendVel(0, 0)
  }

  onTouchMove(event: TouchEvent) {
    if (!this.isJoystickActive || !this.isConnected) return

    const touch = event.touches[0]
    const joystickWidth = 160
    const center = joystickWidth / 2
    const maxRadius = 50

    // 计算相对位置
    const x = touch.x - center
    const y = touch.y - center

    // 限制在范围内
    const distance = Math.sqrt(x * x + y * y)
    let finalX = x
    let finalY = y

    if (distance > maxRadius) {
      finalX = (x / distance) * maxRadius
      finalY = (y / distance) * maxRadius
    }

    // 更新摇杆位置
    this.stickX = finalX
    this.stickY = finalY

    // 计算速度命令
    const lin = -finalY / maxRadius * 0.5
    const ang = -finalX / maxRadius * 1.0

    this.sendVel(lin, ang)
  }

  resetJoystick() {
    this.stickX = 0
    this.stickY = 0
  }

  // 组件销毁时清理
  aboutToDisappear() {

    this.stopHeartbeat()
  }

  build() {
    Column({ space: 10 }) {
      // 顶部标题栏
      Row() {
        Text('🤖 ROS2 机器人控制')
          .fontSize(18)
          .fontColor('#00d4ff')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(50)
      .backgroundColor('#000000')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 连接区域
      Row({ space: 10 }) {
        TextInput({ placeholder: '机器人IP' })
          .width('65%')
          .height(40)
          .backgroundColor('#ffffff')
          .fontColor('#000000')
          .placeholderColor('#999999')
          .onChange((value: string) => {
            this.ipAddress = value
          })

        Button('连接')
          .width('25%')
          .height(40)
          .backgroundColor('#00d4ff')
          .fontColor('#000000')
          .borderRadius(8)
          .onClick(() => {
            this.connectROS()
          })
      }
      .width('100%')
      .padding({ left: 10, right: 10 })

      // 状态显示
      Text(this.statusText)
        .fontSize(14)
        .fontColor(this.isConnected ? '#00ff00' : '#ff0000')
        .width('100%')
        .textAlign(TextAlign.Center)

      // 传感器数据卡片
      Grid() {
        GridItem() {
          this.SensorCard('🌡 温度', this.temperature, false)
        }

        GridItem() {
          this.SensorCard('💧 湿度', this.humidity, false)
        }

        GridItem() {
          this.SensorCard('📏 距离', this.distance, this.distanceWarning)
        }

        GridItem() {
          this.SensorCard('☀ 光照', this.light, this.lightWarning)
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .padding({ left: 10, right: 10 })

      // 摇杆区域
      Stack({ alignContent: Alignment.Center }) {
        Stack({ alignContent: Alignment.Center }) {
          // 摇杆底座
          Circle({ width: 160, height: 160 })
            .fill('#222222')
            .strokeWidth(2)
            .stroke('#333333')

          // 摇杆按钮
          Circle({ width: 60, height: 60 })
            .fill('#00d4ff')
            .offset({ x: this.stickX, y: this.stickY })
        }
        .width(160)
        .height(160)
        .onTouch((event: TouchEvent) => {
          switch (event.type) {
            case TouchType.Down:
              this.onTouchStart()
              break
            case TouchType.Up:
              this.onTouchEnd()
              break
            case TouchType.Move:
              this.onTouchMove(event)
              break
          }
        })
      }
      .width('100%')
      .height(220)
      .backgroundColor('#000000')
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#111111')
  }

  // 传感器卡片组件
  @Builder SensorCard(title: string, value: string, isWarning: boolean) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontColor('#aaaaaa')

      Text(value)
        .fontSize(22)
        .fontColor(isWarning ? '#ff0000' : '#eeeeee')
    }
    .width('100%')
    .height(80)
    .backgroundColor('#1e1e1e')
    .borderRadius(10)
    .padding(15)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}