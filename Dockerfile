# 使用官方 Python 3.11 slim 基础镜像
FROM python:3.11-slim

# 非交互模式，避免 apt 卡住
ARG DEBIAN_FRONTEND=noninteractive

# 设置工作目录
WORKDIR /app

# 环境优化
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8

# 安装系统依赖（包含 ca-certificates 保证 HTTPS 正常），并清理 apt 列表
# 根据需要保留 build-essential/gcc/libffi-dev（若 requirements 中有需要编译的包）
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
       build-essential \
       gcc \
       libffi-dev \
       libssl-dev \
       sqlite3 \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 复制依赖文件到镜像
COPY requirements.txt /app/requirements.txt

# 升级 pip/setuptools/wheel，再安装 Python 依赖
# 如需使用国内镜像（在中国大陆可能更稳定/更快），可以启用下面被注释的 -i 行
RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install --no-cache-dir -r requirements.txt
# 若需要使用阿里云 PyPI 镜像，请把上两行替换为如下（取消注释）：
# RUN python -m pip install --upgrade pip setuptools wheel \
#  && pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -r requirements.txt

# 复制项目文件
# 排除在 .dockerignore 中列出的文件以减小上下文
COPY . /app

# （可选）创建非 root 用户并切换，提升安全性；若你的程序需要写入 /app/data，请确保改权限
# RUN groupadd -r app && useradd -r -g app app \
#  && chown -R app:app /app
# USER app

# 暴露端口（项目默认 3501）
EXPOSE 3501

# 简单健康检查（可选）
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3501/health || exit 1

# 启动命令：与你仓库的启动方式保持一致（若需通过 gunicorn 启动，可改成 gunicorn 命令）
# 该仓库入口是 app.py，使用 python app.py 启动，如果你用 flask CLI 或 gunicorn，请替换下面的 CMD。
CMD ["python", "app.py"]
