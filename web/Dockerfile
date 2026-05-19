# Base image
FROM ubuntu:22.04

ARG GECKOVERSION=0.33.0
ARG GOVERSION=1.21.5

RUN ARCH=$(dpkg --print-architecture) \
    && if [ "${ARCH}" != "arm64" ] && [ "${ARCH}" != "amd64" ]; then \
      echo "reNgine not supported, encountered unknown architecture: ${ARCH}" \
      && exit 1; \
    fi

# Labels and Credits
LABEL \
    name="reNgine" \
    author="Yogesh Ojha <yogesh.ojha11@gmail.com>" \
    description="reNgine is a automated pipeline of recon process, useful for information gathering during web application penetration testing."

# Environment Variables
ENV DEBIAN_FRONTEND="noninteractive" \
    DATABASE="postgres"
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV GOROOT="/usr/local/go"
ENV GOPATH=$HOME/go
ENV PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"

# Install Python
RUN apt update -y && \
    apt install -y \
    python3.10 \
    python3-dev \
    python3-pip 

# Install essential packages
RUN apt install -y --no-install-recommends \
    build-essential \
    cmake \
    geoip-bin \
    geoip-database \
    gcc \
    git \
    libpq-dev \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libpcap-dev \
    netcat \
    nmap \
    ruby \
    ruby-dev \
    libyaml-dev \
    x11-utils \
    xvfb \
    wget \
    curl \
    python3-netaddr \
    software-properties-common

RUN add-apt-repository ppa:mozillateam/ppa

RUN echo '\
Package: *\n\
Pin: release o=LP-PPA-mozillateam\n\
Pin-Priority: 1001\n\
\n\
Package: firefox\n\
Pin: version 1:1snap1-0ubuntu2\n\
Pin-Priority: -1\n\
' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && \
    apt install -y --no-install-recommends firefox

RUN ARCH=$(dpkg --print-architecture) \ 
    && curl -L https://go.dev/dl/go${GOVERSION}.linux-${ARCH}.tar.gz | tar -xzC /usr/local

RUN ARCH=$(dpkg --print-architecture) \ 
    && if [ "${ARCH}" = "arm64" ]; then \
      GECKOPATH="geckodriver-v${GECKOVERSION}-linux-aarch64.tar.gz"; \
    elif [ "${ARCH}" = "amd64" ]; then \
      GECKOPATH="geckodriver-v${GECKOVERSION}-linux64.tar.gz"; \
    fi \
    && wget https://github.com/mozilla/geckodriver/releases/download/v${GECKOVERSION}/${GECKOPATH} \
    && tar -xvf ${GECKOPATH} \
    && rm ${GECKOPATH} \
    && mv geckodriver /usr/bin

# Make directory for app
WORKDIR /usr/src/app

# Install Go tools (core only)
ENV GO111MODULE=on
RUN printf "\
    github.com/projectdiscovery/httpx/cmd/httpx@latest\n\
    github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest\n\
    github.com/projectdiscovery/naabu/v2/cmd/naabu@latest\n\
    github.com/ffuf/ffuf@latest\n\
    github.com/projectdiscovery/katana/cmd/katana@latest\n\
    github.com/lc/gau/v2/cmd/gau@latest\n\
    github.com/tomnomnom/unfurl@latest\n" | \
    xargs -L1 go install -ldflags="-s -w" -v && \
    rm -rf /go/pkg/* && rm -rf /root/.cache/go-build

# Update Nuclei and Nuclei-Templates
RUN nuclei -update-templates

# Copy requirements
COPY ./requirements.txt /tmp/requirements.txt
RUN pip3 install --upgrade setuptools==72.1.0
RUN pip3 install -r /tmp/requirements.txt --no-cache-dir

# install eyewitness
RUN pip3 install --no-cache-dir fuzzywuzzy \
    selenium==4.9.1 \
    python-Levenshtein \
    pyvirtualdisplay \
    netaddr

# Clone subdomain tools
RUN git clone https://github.com/aboul3la/Sublist3r /usr/src/github/Sublist3r && \
    pip install -q -r /usr/src/github/Sublist3r/requirements.txt
RUN git clone https://github.com/shmilylty/OneForAll /usr/src/github/OneForAll && \
    pip install -q -r /usr/src/github/OneForAll/requirements.txt

# Clone and install WhatWeb
RUN git clone https://github.com/urbanadventurer/WhatWeb /usr/src/github/WhatWeb && \
    cd /usr/src/github/WhatWeb && gem install bundler && bundle install

# Clone CMSeeK
RUN git clone https://github.com/Tuhinshubhra/CMSeeK /usr/src/github/CMSeeK && \
    pip install -q -r /usr/src/github/CMSeeK/requirements.txt

# Clone EyeWitness
RUN git clone https://github.com/FortyNorthSecurity/EyeWitness /usr/src/github/EyeWitness

# Copy source code
COPY . /usr/src/app/
