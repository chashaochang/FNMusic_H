# 飞牛音乐鸿蒙客户端

飞牛音乐鸿蒙客户端是一个基于 HarmonyOS API 26、使用 ArkTS 开发的非官方原生客户端，目前仅适配手机端。

本项目与飞牛官方无隶属或合作关系。项目基于现有公开接口及公开开源项目提供的信息开发，不包含对飞牛应用安装包的逆向代码，也不提供任何服务器账号、访问凭证或私有数据。

## 已实现功能

- 支持 FN ID / FN Connect 登录、域名直连登录及自动重连
- 使用 HUKS 加密保存登录凭证
- 首页搜索、漫游、收藏、最近播放和最近添加
- 专辑、歌手、风格及支持分页加载的音乐库
- 最近添加专辑与歌曲展示，支持专辑一键播放
- 原生 AVPlayer / AVSession 音乐播放、播放队列和歌词显示
- 漫游模式随机续播，漫游状态不展示普通播放队列
- 播放列表、当前歌曲及播放进度持久化
- 悬浮播放条、全屏播放器及对应过渡动画
- 底部导航随列表滚动自适应收缩与恢复
- 深色模式、浅色模式、安全区适配及鸿蒙系统材质
- 独立全屏搜索页和移动端二级页面导航

实际可用功能取决于飞牛设备的系统版本、音乐服务版本、账号权限及当前网络环境。首次使用前，请确认自己的飞牛设备已启用音乐服务并可正常访问。

## 开发环境

- DevEco Studio 3
- HarmonyOS API 26 SDK
- ArkTS / ArkUI
- Stage 模型

本项目使用 DevEco Studio 3 自带的 API 26 工具链。命令行构建示例：

```bash
env DEVECO_SDK_HOME='/Applications/DevEco-Studio 3.app/Contents/sdk' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/node/bin/node' \
  '/Applications/DevEco-Studio 3.app/Contents/tools/hvigor/bin/hvigorw.js' \
  --mode module -p product=default assembleHap \
  --analyze=normal --parallel --incremental --daemon
```

构建产物位于：

```text
entry/build/default/outputs/default/
```

## 签名与安装

仓库不包含证书、密钥库、签名口令等私密文件。首次构建前，请在 DevEco Studio 中为项目配置本机自动签名或调试签名，然后将生成的已签名 HAP 安装到 API 26 模拟器或鸿蒙手机。

请勿提交以下内容：

- `.cer`、`.p7b`、`.p12`、`.pem` 等签名文件
- 签名口令、账号密码、访问令牌
- 真实 FN ID、服务器地址或家庭内网地址
- 包含个人音乐库、账号信息的截图和日志

## 验证说明

- Hvigor 构建成功只能证明 ArkTS 编译及 HAP 打包通过。
- 模拟器验证可覆盖主要界面、导航和基础交互。
- 后台播放、系统媒体控制、音频格式兼容性需要在真机验证。
- FN Connect、音乐库分页、流媒体拖动、收藏等功能需要连接真实飞牛设备验证。

## 开源许可

项目原创代码采用 `Apache-2.0` 许可证。第三方组件及衍生部分仍遵循各自原始许可证，具体信息请查看 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
