# 使用具体版本的 python:3.11 作为基础镜像
FROM python:3.10

# 设置环境变量以防止交互安装
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装必要的依赖
RUN apt-get update && apt-get install -y \
    locales \
    g++ \
    gfortran \
    git \
    wget \
    liblapack-dev \
    pkg-config \
    ca-certificates \
    tzdata \
    libopenblas-dev \
    libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置时区（例如，Asia/Shanghai）
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 设置和生成locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL=en_US.UTF-8

# 下载并安装Coinbrew工具
RUN wget https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew && \
    chmod u+x coinbrew

# 设置Git的缓冲区大小和增加重试机制
RUN git config --global http.sslVerify false && git config --global http.postBuffer 524288000

# 使用Coinbrew安装Ipopt及其依赖项，添加重试机制
RUN ./coinbrew fetch Ipopt --no-prompt || (sleep 10 && ./coinbrew fetch Ipopt --no-prompt) || (sleep 30 && ./coinbrew fetch Ipopt --no-prompt) && \
    ./coinbrew build Ipopt --prefix=/usr/local --test --no-prompt || (sleep 10 && ./coinbrew build Ipopt --prefix=/usr/local --test --no-prompt) || (sleep 30 && ./coinbrew build Ipopt --prefix=/usr/local --test --no-prompt)

# 设置环境变量以包含Ipopt库路径
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# 安装Ipopt Python接口
RUN pip install cyipopt

# 将项目文件复制到容器中
WORKDIR /app
COPY . /app

# 安装Python依赖
RUN pip install -r requirements.txt

# 暴露必要的端口（假设服务运行在5000端口）
EXPOSE 5000

# 设置容器启动时的默认命令
CMD ["python", "main.py"]