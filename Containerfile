ARG IMAGE_NAME
ARG IMAGE_REGISTRY

FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files

FROM ghcr.io/secureblue/silverblue-main-hardened:latest

ARG IMAGE_NAME
ARG IMAGE_REGISTRY
ENV IMAGE_NAME=${IMAGE_NAME}
ENV IMAGE_REGISTRY=${IMAGE_REGISTRY}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build.sh && \
    ostree container commit

RUN bootc container lint