FROM ubuntu:22.04 AS builder

WORKDIR /home/video_cap

# Install build tools
RUN apt-get update -qq --fix-missing && \
  apt-get upgrade -y && \
  apt-get install -y \
    wget \
    unzip \
    build-essential \
    cmake \
    git \
    pkg-config \
    autoconf \
    automake \
    git-core \
    python3-dev \
    python3-pip \
    python3-numpy \
    python3-pkgconfig && \
    rm -rf /var/lib/apt/lists/*

# Install OpenCV
COPY install_opencv.sh /home/video_cap
RUN mkdir -p /home/video_cap && \
  cd /home/video_cap && \
  chmod +x install_opencv.sh && \
  ./install_opencv.sh

# Install FFMPEG
COPY install_ffmpeg.sh /home/video_cap
COPY ffmpeg_patch /home/video_cap/ffmpeg_patch/
RUN mkdir -p /home/video_cap && \
  cd /home/video_cap && \
  chmod +x install_ffmpeg.sh && \
  ./install_ffmpeg.sh

FROM ubuntu:22.04

# install Python
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-numpy \
    python3-pkgconfig && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
  apt-get -y install \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libmp3lame-dev \
    zlib1g-dev \
    libx264-dev \
    libsdl2-dev \
    libvpx-dev \
    libvdpau-dev \
    libvorbis-dev \
    libopus-dev \
    libdc1394-dev \
    liblzma-dev && \
    rm -rf /var/lib/apt/lists/*

# copy libraries
WORKDIR /usr/local/lib
COPY --from=builder /usr/local/lib .
WORKDIR /usr/local/include
COPY --from=builder /home/ffmpeg_build/include .
WORKDIR /home/ffmpeg_build/lib
COPY --from=builder /home/ffmpeg_build/lib .
WORKDIR /usr/local/include/opencv4/
COPY --from=builder /usr/local/include/opencv4/ .
WORKDIR /home/opencv/build/lib
COPY --from=builder /home/opencv/build/lib .

# Set environment variables
ENV PATH="$PATH:/home/bin"
ENV PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/home/ffmpeg_build/lib/pkgconfig"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/opencv/build/lib"

WORKDIR /home/video_cap

COPY setup.py /home/video_cap
COPY src /home/video_cap/src/

# Install Python package
COPY vid.mp4 /home/video_cap
RUN python3 setup.py install

CMD ["sh", "-c", "tail -f /dev/null"]
