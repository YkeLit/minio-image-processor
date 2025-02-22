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
  -p 9000:9000 \
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
  -p 9000:9000 \
  -v /data/minio:/data \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=YourStrongPassword \
  minio-image-processor:latest
```

## 🔧 配置说明

### 环境变量

| 变量名                  | 默认值         | 描述                          |
|-------------------------|----------------|------------------------------|
| `MINIO_ROOT_USER`       | `minioadmin`   | MinIO 管理员账号             |
| `MINIO_ROOT_PASSWORD`   | `minioadmin`   | MinIO 管理员密码             |

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

## ⚡ 接口示例

### 上传图片到 MinIO

```bash
curl -X PUT -T photo.jpg \
  http://localhost:9000/my-bucket/photo.jpg \
  -H "x-amz-date: $(date -u +%Y%m%dT%H%M%SZ)"
```

### 获取原始图片

```bash
curl http://localhost/minio/my-bucket/photo.jpg -o original.jpg
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


---

