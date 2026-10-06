FROM ghcr.io/home-assistant/base-debian:bookworm

ARG GENMON_REPO="https://github.com/jgyates/genmon.git"
ARG GENMON_REF="master"

# cmake must be present or genloader tries to apt-get it on every start
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-dev \
        build-essential \
        cmake \
        swig \
        libssl-dev \
        libffi-dev \
        git \
        procps \
        nginx \
    && rm -f /usr/lib/python3*/EXTERNALLY-MANAGED \
    && rm -rf /var/lib/apt/lists/*

# No .git: the web UI "Update" then fails harmlessly instead of changing a copy lost on restart
RUN git clone --depth 1 --branch "${GENMON_REF}" "${GENMON_REPO}" /genmon \
    && rm -rf /genmon/.git

# Installed one by one so a Pi-only package that fails to build on amd64 doesn't break the image
RUN grep -vE '^[[:space:]]*(#|$)' /genmon/requirements.txt | while read -r req; do \
        pip3 install --no-cache-dir --prefer-binary "${req}" \
            || echo "WARNING: could not install ${req}"; \
    done

COPY rootfs /
COPY run.sh /run.sh
RUN sed -i 's/\r$//' /run.sh /usr/local/sbin/* /usr/local/bin/genmon-* /etc/nginx/nginx.conf \
    && chmod a+x /run.sh /usr/local/sbin/* /usr/local/bin/genmon-*

CMD ["/run.sh"]
