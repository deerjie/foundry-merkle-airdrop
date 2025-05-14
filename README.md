## 安装zksync
[foundryup-zksync](https://foundry-book.zksync.io/getting-started/installation)
# zksync使用
## 1. 安装foundryup-zksync
```shell
curl -L https://raw.githubusercontent.com/matter-labs/foundry-zksync/main/install-foundry-zksync | bash
```
运行`oundryup-zksync`会自动安装预编译二进制文件的最新夜间版本，包括forge和cast。此外，它从anvil-zksync版本中获取预编译的二进制anvil-zksync的最新版本。
## 2.编译
```shell
forge build --zksync
```
## 3.测试
```shell
forge test --zksync -vvvv
```
