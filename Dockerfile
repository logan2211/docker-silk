FROM debian:buster as build

ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_WORKERS 8

ENV SILK_VERSION silk-3.19.0
ENV YAF_VERSION yaf-2.11.0
ENV LIBFIXBUF_VERSION libfixbuf-2.4.0

ENV SILK_BUILD_ARGS "--with-python  --enable-ipv6"
ENV YAF_BUILD_ARGS "--enable-applabel"
ENV LIBFIXBUF_BUILD_ARGS ""

RUN apt-get update && \
    apt-get install -y \
      curl build-essential libglib2.0-dev zlib1g-dev \
      libgnutls28-dev libpcap0.8-dev python3-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl --remote-name-all \
      https://tools.netsa.cert.org/releases/${SILK_VERSION}.tar.gz \
      https://tools.netsa.cert.org/releases/${YAF_VERSION}.tar.gz \
      https://tools.netsa.cert.org/releases/${LIBFIXBUF_VERSION}.tar.gz && \
    tar -xf ${SILK_VERSION}.tar.gz && \
    tar -xf ${YAF_VERSION}.tar.gz && \
    tar -xf ${LIBFIXBUF_VERSION}.tar.gz

WORKDIR /tmp/${LIBFIXBUF_VERSION}
RUN ./configure --prefix=/tmp/target ${LIBFIXBUF_BUILD_ARGS} && \
    make -j${BUILD_WORKERS} && make install

WORKDIR /tmp/${YAF_VERSION}
RUN ./configure --prefix=/tmp/target ${YAF_BUILD_ARGS} && \
    make -j${BUILD_WORKERS} && make install

WORKDIR /tmp/${SILK_VERSION}
RUN ./configure --prefix=/tmp/target ${SILK_BUILD_ARGS} && \
    make -j${BUILD_WORKERS} && make install

FROM debian:buster

LABEL maintainer="Logan V. <logan2211@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN apt-get update && \
    apt-get install -y \
      libglib2.0 zlib1g libgnutls28-dev libpcap0.8 python3-minimal && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /tmp/target /usr/local

RUN ldconfig

ENTRYPOINT ["/tini", "--"]
