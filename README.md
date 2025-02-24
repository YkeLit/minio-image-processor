# MinIO & Nginx 镜像处理服务

将 MinIO 对象存储与 Nginx 图片处理模块集成，提供一站式图片存储与动态处理服务。

## ✨ 功能特性

- **图片存储**
  MinIO 提供高可用 S3 兼容存储服务
- **动态处理**
  Nginx 集成 `ngx_http_image_filter_module` 模块，支持：
  - 实时图片压缩 (`quality=85`)
  - 按尺寸裁剪 (`?width=200&height=200`)
  - 格式转换 (JPG/PNG/WebP)

## 🚀 快速开始

### 本地运行（开发模式）

```bash
# 克隆项目
git clone
cd minio-nginx-image-processing

# 启动容器
docker run -d \
  -p 80:80 \
  -p 9000:9000 \    # MinIO API
  -p 9001:9001 \    # MinIO 控制台
  -v /data:/data \  # 持久化存储
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=YourStrongPassword \
  registry.cn-hangzhou.aliyuncs.com/your_ns/your_repo:latest

# 访问服务
# MinIO控制台: http://localhost:9000
# Nginx服务: http://localhost:80
```

### 生产环境部署

```bash
# 拉取镜像
docker pull image-name

# 运行容器（自定义存储目录）
docker run -d \
  -p 80:80 \
  -p 9000:9000 \    # MinIO API
  -p 9001:9001 \    # MinIO 控制台
  -v /data:/data \  # 持久化存储
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=YourStrongPassword \
  registry.cn-hangzhou.aliyuncs.com/your_ns/your_repo:latest
```
## 🔧 配置说明

### 环境变量

| 变量名                  | 默认值         | 描述                          |
|-------------------------|----------------|------------------------------|
| `MINIO_ROOT_USER`       | `minioadmin`   | MinIO 管理员账号             |
| `MINIO_ROOT_PASSWORD`   | `minioadmin`   | MinIO 管理员密码             |

### Nginx 代理配置

系统使用 Nginx 作为反向代理，主要配置了以下服务：

#### API 服务 (/api/)
- 代理到: `http://localhost:9000/`
- 用途: 处理所有 API 请求
- 配置特点:
  - 保留原始请求头信息
  - 传递客户端真实 IP
  - 支持跨域请求

#### 控制台服务 (/console/)
- 代理到: `http://localhost:9001/`
- 用途: 管理控制台界面
- 配置特点:
  - 支持 WebSocket 连接
  - 保留原始请求头信息
  - 传递客户端真实 IP

#### 图片处理服务 (/processed/)
- 代理到: `http://localhost:9000/`
- 用途: 动态图片处理
- 配置特点:
  - 支持图片动态缩放
  - JPEG 质量控制 (85%)
  - 最大缓冲区 10M
  - 不支持的图片格式返回空白图片

#### 性能优化配置
- 工作进程连接数: 1024
- 使用 epoll 事件模型
- 启用 accept_mutex 优化连接分发

#### 注意事项
1. 所有代理路径都添加了末尾斜杠，确保正确的路径重写
2. 配置了标准的代理头信息（Host, X-Real-IP, X-Forwarded-For）
3. 控制台服务支持 WebSocket 升级
4. 图片处理服务包含错误处理机制

### Nginx 处理参数调整

编辑 `nginx.conf` 自定义图片处理规则：

```nginx
http {
  server {
		location /processed/ {
			image_filter rotate $arg_deg;  # 添加旋转参数
			image_filter_sharpen 0.5;      # 锐化强度
		}
  }
}
```

### Nginx 日志配置

系统配置了详细的日志记录，便于问题排查：

#### 日志格式
```
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"
```

#### 日志文件
- 全局日志
  - 访问日志: `/var/log/nginx/access.log`
  - 错误日志: `/var/log/nginx/error.log`

- API 服务日志 (/api/)
  - 访问日志: `/var/log/nginx/api_access.log`
  - 错误日志: `/var/log/nginx/api_error.log`

- 控制台日志 (/console/)
  - 访问日志: `/var/log/nginx/console_access.log`
  - 错误日志: `/var/log/nginx/console_error.log`

- 图片处理日志 (/processed/)
  - 访问日志: `/var/log/nginx/image_access.log`
  - 错误日志: `/var/log/nginx/image_error.log`

#### 日志级别
- 访问日志：记录所有请求详情
- 错误日志：warn 级别，记录警告和错误信息

### Supervisor 进程管理

系统使用 Supervisor 管理 Nginx 和 MinIO 服务进程：

#### 服务配置
- **Nginx 服务**
  - 优先级: 10
  - 自动启动: 是
  - 自动重启: 是
  - 日志位置:
    - 标准输出: `/var/log/supervisor/nginx_stdout.log`
    - 错误输出: `/var/log/supervisor/nginx_stderr.log`

- **MinIO 服务**
  - 优先级: 20
  - 自动启动: 是
  - 自动重启: 是
  - 日志位置:
    - 标准输出: `/var/log/supervisor/minio_stdout.log`
    - 错误输出: `/var/log/supervisor/minio_stderr.log`

#### 进程管理命令
```bash
# 查看所有进程状态
supervisorctl status

# 重启特定服务
supervisorctl restart nginx
supervisorctl restart minio

# 停止服务
supervisorctl stop nginx

# 启动服务
supervisorctl start nginx
```

## ⚡ 接口示例

### 上传图片到 MinIO

```bash
curl -X PUT -T photo.jpg \
  http://localhost/api/my-bucket/photo.jpg \
  -H "x-amz-date: $(date -u +%Y%m%dT%H%M%SZ)"
```

### 获取原始图片

```bash
curl http://localhost/api/my-bucket/photo.jpg -o original.jpg
```

### 动态处理图片

```bash
# 压缩并裁剪为 300x300
curl "http://localhost/processed/my-bucket/photo.jpg?width=300&height=300" -o resized.jpg

# 转换为 WebP 格式（需启用对应模块）
curl -H "Accept: image/webp" http://localhost/processed/photo.jpg -o output.webp
```

## 🛠️ 故障排查

### 常见问题

1. **图片处理返回 415 错误**
   ⇒ 确认原始图片格式为 JPG/PNG
   ⇒ 检查 `image_filter_buffer` 是否足够大

2. **MinIO 上传失败**
   ⇒ 验证容器端口 9000 是否暴露
   ⇒ 确认存储桶策略允许写入

3. **Nginx 模块未生效**
   ⇒ 运行 `docker exec <container> nginx -V` 确认编译参数
   ⇒ 检查是否安装 libgd 依赖

### 日志排查指南

1. **API 请求问题**
   ⇒ 查看 `/var/log/nginx/api_access.log` 和 `api_error.log`
   ⇒ 关注状态码和错误信息

2. **图片处理失败**
   ⇒ 检查 `/var/log/nginx/image_error.log` 中的错误信息
   ⇒ 通过 `image_access.log` 验证请求参数

3. **控制台连接问题**
   ⇒ 查看 `/var/log/nginx/console_error.log` 排查 WebSocket 连接
   ⇒ 检查 `console_access.log` 中的请求状态

4. **查看实时日志**
   ```bash
   # 实时查看错误日志
   docker exec <container> tail -f /var/log/nginx/error.log
   # 查看特定服务的访问日志
   docker exec <container> tail -f /var/log/nginx/api_access.log
   ```

### 进程管理问题

1. **服务无法启动**
   ⇒ 检查 supervisor 日志: `/var/log/supervisord.log`
   ⇒ 查看具体服务日志: `/var/log/supervisor/[service]_stderr.log`

2. **服务意外退出**
   ⇒ 查看 supervisor 状态: `supervisorctl status`
   ⇒ 检查自动重启配置
   ⇒ 分析服务日志确定退出原因

3. **查看服务日志**
   ```bash
   # 实时查看 Nginx 服务日志
   docker exec <container> tail -f /var/log/supervisor/nginx_stderr.log
   # 实时查看 MinIO 服务日志
   docker exec <container> tail -f /var/log/supervisor/minio_stderr.log
   ```


---


