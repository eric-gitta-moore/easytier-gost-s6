# easytier-gost-s6

一个基于 Alpine + s6-overlay 的轻量容器，内置 EasyTier 与 GOST，提供可组合的 Socks5 代理链路与示例配置。通过 Docker Compose 一键构建与运行，适用于内网/跨网访问、出口代理、链路转发等场景。

## 功能特性
- 使用 `s6-overlay` 管理进程与初始化，稳定可靠。
- 集成 EasyTier（P2P/Overlay 网络）与 GOST（多协议代理）两大组件。
- 开箱即用的示例配置：本地 Socks5 → EasyTier → 远端 Socks5 的双跳链路。
- 可通过 `docker-compose.yaml` 自定义版本与配置文件，支持热更新。

## 架构与数据流（示例）
- 宿主机入口：`socks5://127.0.0.1:47897`（映射到容器内 `gost-out :17897`）。
- `gost-out` 使用 `chain-0`：
  - 第一跳 `hop-0`：`socks5://127.0.0.1:12333`（容器/本机提供的 EasyTier Socks5）。
  - 第二跳 `hop-1`：`socks5://10.126.126.1:17897`（示例远端节点上的 GOST 服务）。
- 容器内另有 `gost-tun2socks :1080`（示例本地出口用），未默认映射到宿主机端口。

> 提示：上述地址与端口均为示例值，实际部署请按您的网络与安全策略调整。

## 目录结构
- `Dockerfile`：构建镜像，安装 `s6-overlay`、EasyTier 与 GOST。
- `docker-compose.yaml`：编排与端口映射、版本参数、卷挂载。
- `rootfs/config/config.toml`：EasyTier 配置（网络标识、代理设置、Flags）。
- `rootfs/config/gost.yaml`：GOST 配置（服务、监听、代理链路）。
- `rootfs/etc/s6-overlay/`：s6-overlay 相关目录（服务初始化与管理）。

## 快速开始
1) 准备环境
- 需要 Docker 与 Docker Compose。默认镜像平台为 `linux/amd64`。

2) 启动服务（推荐）
- 在项目根目录执行：

```bash
# 构建并前台运行（调试）
docker compose up --build

# 后台运行
docker compose up -d
```

- 启动成功后，可在宿主机使用示例入口代理：
  - `socks5://127.0.0.1:47897`

3) 停止/重启/查看日志
```bash
docker compose stop

docker compose restart

docker compose logs -f easytier-s6
```

## 自行构建镜像
如需单独构建镜像：
```bash
docker build -t easytier-s6:latest . \
  --build-arg S6_OVERLAY_VERSION=v3.2.1.0 \
  --build-arg EASYTIER_VERSION=v2.4.5 \
  --build-arg GOST_VERSION=3.2.6
```

镜像使用 `ENTRYPOINT ["/init"]`，由 `s6-overlay` 接管启动流程。

## 配置说明
### EasyTier（`/config/config.toml`）
关键字段说明：
- `instance_name`：实例名。
- `dhcp`：是否使用 DHCP。
- `socks5_proxy`：EasyTier 暴露的本地 Socks5 入口，例如 `socks5://0.0.0.0:12333`。
- `listeners`：自定义监听（示例为空数组）。
- `rpc_portal`：RPC 端口，示例为随机端口 `0.0.0.0:0`。
- `[network_identity]`：网络标识。
  - `network_name`：要加入的网络名（示例 `steamtv`）。
  - `network_secret`：私网密钥。私有网络务必设置为非空。
- `[[peer]]`：引导/对端列表（示例使用公共引导地址）。
- `[flags]`：运行标志。
  - `no_tun = true`：不创建 TUN 设备（示例通过 socks5/隧道）。
  - `enable_exit_node = true`：启用出口节点功能（请谨慎评估安全与带宽）。
  - `enable_kcp_proxy = true` / `enable_quic_proxy = true`：启用 KCP/QUIC 代理。
  - `use_smoltcp = true`：使用 smoltcp 实现。

### GOST（`/config/gost.yaml`）
- `services`：定义服务（监听地址与处理器类型）。
  - `gost-out :17897`：类型 `socks5`，使用 `chain-0`，对外暴露供宿主机访问。
  - `gost-tun2socks :1080`：类型 `socks5`，默认仅容器内使用。
- `chains`：代理链定义。
  - `chain-0`：
    - `hop-0` → `127.0.0.1:12333`：连接容器/本机的 EasyTier Socks5。
    - `hop-1` → `10.126.126.1:17897`：连接远端节点的 GOST Socks5。

> 修改链路时，请同步调整 `config.toml` 的 `socks5_proxy` 与 `gost.yaml` 的 `hops` 地址，以确保端到端连通。

## 端口与服务
- 宿主机 `127.0.0.1:47897` → 容器 `:17897`（gost-out，对外入口）。
- 容器内 `:12333`（EasyTier Socks5，示例提供本地第一跳）。
- 容器内 `:1080`（gost-tun2socks，本地出口示例，不对宿主机暴露）。

## 常见用法示例
- 将系统/浏览器代理指向 `socks5://127.0.0.1:47897`，通过双跳链路访问远端网络。
- 在私有网络中，设置 `network_secret` 与自定义 `peer`，实现内网穿透与安全通信。
- 将 `hop-1` 指向您控制的远端 GOST 服务，实现可控的出口策略与带宽管理。

## 版本定制
`docker-compose.yaml` 中可通过构建参数覆盖版本：
- `S6_OVERLAY_VERSION`（默认 `v3.2.1.0`）
- `EASYTIER_VERSION`（默认 `v2.4.5`）
- `GOST_VERSION`（默认 `3.2.6`）

也可在构建命令中使用 `--build-arg` 指定。

## 运维与排障
- 查看日志：`docker compose logs -f easytier-s6`。
- 端口占用：确认宿主机 `47897` 未被占用，容器内 `17897/12333/1080` 无冲突。
- 连通性：
  - `peer` 是否可达、DNS 解析是否正常。
  - `hop-1` 的远端地址是否正确、是否开放防火墙端口。
- 权限与网络：若需创建 TUN，请取消 `no_tun = true` 并确保容器具备相应权限（当前示例关闭 TUN）。

## 兼容性与平台
- 目标平台 `linux/amd64`。其他架构需调整 `Dockerfile` 中 s6-overlay 与二进制下载地址。
- 时区默认 `Asia/Shanghai`，可通过环境变量 `TZ` 调整。

## 致谢
- [s6-overlay](https://github.com/just-containers/s6-overlay)
- [EasyTier](https://github.com/EasyTier/EasyTier)
- [GOST](https://github.com/go-gost/gost)
