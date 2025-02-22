FROM ubuntu:22.04 AS nginx-builder
RUN apt-get update && \
    apt-get install -y build-essential libgd-dev libpcre3-dev zlib1g-dev wget
RUN wget https://nginx.org/download/nginx-1.25.1.tar.gz && \
    tar -xzvf nginx-1.25.1.tar.gz && \
    cd nginx-1.25.1 && \
    ./configure --with-http_image_filter_module && \
    make && make install

FROM minio/minio:latest AS minio

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y supervisor libgd-dev
COPY --from=nginx-builder /usr/local/nginx /usr/local/nginx
COPY --from=minio /usr/bin/minio /usr/local/bin/minio
COPY nginx.conf /usr/local/nginx/conf/
COPY supervisord.conf /etc/supervisor/conf.d/

EXPOSE 80 9000
CMD ["supervisord", "-n"]

