FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    ca-certificates \
    sudo \
    openjdk-17-jdk \
    lib32stdc++6 \
    lib32gcc-s1 \
    lib32ncurses6 \
    lib32z1 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m runner && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER runner
WORKDIR /home/runner

RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    curl -o cmdline.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip cmdline.zip && \
    mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm cmdline.zip

RUN yes | sdkmanager --licenses && \
    sdkmanager \
      "platform-tools" \
      "platforms;android-34" \
      "build-tools;34.0.0"

RUN curl -o actions-runner.tar.gz -L \
    https://github.com/actions/runner/releases/download/v2.316.0/actions-runner-linux-x64-2.316.0.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm actions-runner.tar.gz

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
