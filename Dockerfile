FROM debian:bookworm-slim

ARG BUILD_UID=499
ARG BUILD_GID=499

ENV DEBIAN_FRONTEND=noninteractive

# mock effectiverange devc build settings
RUN groupadd -g $BUILD_GID crossbuilder && \
    useradd -d /home/crossbuilder -m -g $BUILD_GID -u $BUILD_UID -s /bin/bash crossbuilder 
COPY --chown=crossbuilder:crossbuilder ./devc-effectiverange/build_tools /home/crossbuilder/build_tools
COPY --chown=crossbuilder:crossbuilder ./devc-effectiverange/scripts /home/crossbuilder/scripts
COPY --chown=crossbuilder:crossbuilder ./devc-effectiverange/TARGET/ARMHF-BOOKWORM /home/crossbuilder/target
RUN touch /home/crossbuilder/target.ARMHF-BOOKWORM
    
COPY build.sh /tmp/build.sh
RUN /bin/bash /tmp/build.sh
    
ENV PATH=$PATH:/opt/microchip/xc8/bin

USER crossbuilder
WORKDIR /home/crossbuilder
RUN /bin/bash
