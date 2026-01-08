FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools
ENV HAS_SIGNING_CONFIG=false

# Системные зависимости
RUN apt-get update && apt-get install -y \
    curl unzip git jq ca-certificates sudo openjdk-17-jdk \
    lib32stdc++6 lib32gcc-s1 lib32ncurses6 lib32z1 \
    && rm -rf /var/lib/apt/lists/*

# Пользователь runner
RUN useradd -m runner && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Директории SDK / runner
RUN mkdir -p /opt/android-sdk /opt/runner /home/runner/.gradle \
    && chown -R runner:runner /opt/android-sdk /opt/runner /home/runner

# ⬇⬇⬇ ВСЁ ДАЛЬШЕ — ТОЛЬКО ПОД runner ⬇⬇⬇
USER runner
WORKDIR /home/runner

# Android SDK
RUN curl -L -o cmdline.zip \
        https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip cmdline.zip \
    && mkdir -p $ANDROID_HOME/cmdline-tools/latest \
    && mv cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest \
    && rm -rf cmdline.zip cmdline-tools

# Лицензии и компоненты SDK — ПОД runner
RUN yes | sdkmanager --licenses

RUN sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"

# GitHub Actions Runner
WORKDIR /opt/runner

RUN curl -L -o actions-runner.tar.gz \
        https://github.com/actions/runner/releases/download/v2.316.0/actions-runner-linux-x64-2.316.0.tar.gz \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz

COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/bin/bash", "./entrypoint.sh"]
