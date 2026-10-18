import { promptAction, router } from "@kit.ArkUI"
import { CommonParameters } from "../constants/CommonParameters"
import PreferenceUtil from "../utils/PreferenceUtil"
import { bind } from "../utils/webSokectUils"

interface DownButtonParamsType{
  name:string,
  id:number,
  url:string,
  isSelect:Resource,
  Select:Resource
}


const  DownButtonParams:DownButtonParamsType[] = [
  {
  name:'设备',
  id:0,
  url:'pages/Equipment',
  isSelect:$rawfile('AP.png'),
  Select:$rawfile('AP2.png'),
},{
  name:'控制',
  id:1,
  url:'pages/Index',
  isSelect:$rawfile('home1.png'),
  Select:$rawfile('home2.png'),
}
]


@Component
@Entry
export struct DownButton{
  build() {
    Row(){
      ForEach(DownButtonParams,(item:DownButtonParamsType)=>{
        ChildItem({ item: item })
      })

    }
    .padding(10)
    .width("90%")
    .height("10%")
    .position({x:'5%',y:'85%'})
    .borderRadius(30) // 设置圆角半径为10像素
    .backgroundColor('rgba(255,255,255,0.1)')
    .shadow({ radius: 90, color: '#00a6e8' })

  }
}

@Component
struct ChildItem {
  @Prop item: DownButtonParamsType;

  build() {
Flex({direction:FlexDirection.Column,justifyContent:FlexAlign.SpaceAround,alignItems:ItemAlign.Center}){
  Image(CommonParameters.selectedButton === this.item.id ? this.item.Select:this.item.isSelect)
    .height('50%')
  Text(this.item.name)
    .fontColor(CommonParameters.selectedButton === this.item.id ? '#00d7fb':'#8c93a1')

}
  .width('50%')
      .height('100%')
      .backgroundColor('rgba(255,255,255,0)') // 设置黑色背景
      .onTouch(() =>{
        if(CommonParameters.selectedButton !== this.item.id && this.item.id == 1 && !PreferenceUtil.isDeviceExists("robotDog")){
          this.getUIContext().getPromptAction().showToast({
            message: "请先扫描添加机械狗设备",
            duration: 2000,
            showMode: promptAction.ToastShowMode.DEFAULT,
            bottom: 80
          });
          return
        }else{

          bind()
        }
        if (CommonParameters.selectedButton !== this.item.id) {
          CommonParameters.selectedButton = this.item.id
          router.replace({ url: this.item.url })
          router.clear()
        }

      }) // 选中此按钮
  }
}