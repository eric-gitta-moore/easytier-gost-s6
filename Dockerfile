ARG S6_OVERLAY_VERSION=v3.2.1.0
ARG EASYTIER_VERSION=v2.4.5
ARG GOST_VERSION=3.2.6

FROM alpine:3.20

ARG S6_OVERLAY_VERSION
ARG EASYTIER_VERSION
ARG GOST_VERSION

RUN apk add --no-cache curl ca-certificates tzdata xz tar gzip jq unzip

ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-x86_64.tar.xz
RUN tar -C / -Jxvf /tmp/s6-overlay-noarch.tar.xz && tar -C / -Jxvf /tmp/s6-overlay-x86_64.tar.xz && rm -f /tmp/s6-overlay-*.tar.xz

ENV TZ=Asia/Shanghai

RUN curl https://zyedidia.github.io/eget.sh | sh && mv eget /usr/local/bin/
ARG EASYTIER_URL="https://github.com/EasyTier/EasyTier/releases/download/${EASYTIER_VERSION}/easytier-linux-x86_64-${EASYTIER_VERSION}.zip"
RUN eget "${EASYTIER_URL}" --all --to /usr/local/bin
ARG GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_amd64.tar.gz"
RUN eget "${GOST_URL}" --all --to /usr/local/bin

COPY rootfs/ /

ENTRYPOINT ["/init"]
