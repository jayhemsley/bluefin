# Universal Blue Images: https://github.com/orgs/ublue-os/packages
ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG TAG_VERSION="latest"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY / /

# Base Image
FROM ${BASE_IMAGE}:${TAG_VERSION} 

ARG REMOTE_FONTS_URL=""
ENV REMOTE_FONTS_URL=${REMOTE_FONTS_URL}

### MODIFICATIONS
## Make modifications in build.sh. The following RUN directive does the rest.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build.sh && \
    ostree container commit
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint