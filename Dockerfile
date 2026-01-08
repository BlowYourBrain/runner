# =========================
# Базовый образ
# =========================
FROM ubuntu:22.04

# =========================
# Переменные окружения
# =========================
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools
ENV HAS_SIGNING_CONFIG=false

# 🔒 ВАЖНО: запрещаем Gradle автоматически трогать SDK
ENV ANDROID_SDK_MANAGER_DISABLE=true

# =========================
# Системные зависимости
# =========================
RUN apt-get update && apt-get install -y \
    curl unzip git jq ca-certificates sudo openjdk-17-jdk \
    lib32stdc++6 lib32gcc-s1 lib32ncurses6 lib32z1 \
    && rm -rf /var/lib/apt/lists/*

# =========================
# Пользователь runner
# =========================
RUN useradd -m runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# =========================
# Подготовка директорий (root)
# =========================
RUN mkdir -p \
        /opt/runner \
        /opt/android-sdk/cmdline-tools \
        /home/runner/.gradle

# =========================
# Установка Android SDK (root)
# =========================
USER root

RUN curl -L -o /tmp/cmdline.zip \
        https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
    && unzip /tmp/cmdline.zip -d /opt/android-sdk \
    && mv /opt/android-sdk/cmdline-tools /opt/android-sdk/cmdline-tools-temp \
    && mkdir -p /opt/android-sdk/cmdline-tools/latest \
    && mv /opt/android-sdk/cmdline-tools-temp/* /opt/android-sdk/cmdline-tools/latest \
    && rm -rf /opt/android-sdk/cmdline-tools-temp /tmp/cmdline.zip

# =========================
# Лицензии + SDK (ТОЛЬКО В IMAGE BUILD)
# =========================
RUN sdkmanager --update

RUN yes | sdkmanager --licenses

RUN sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"

# 🔴 КРИТИЧНО: после этого SDK больше НЕ меняется
RUN chown -R runner:runner /opt/android-sdk /home/runner \
    && chmod -R u+rwX /opt/android-sdk

# =========================
# Установка GitHub Actions Runner
# =========================
RUN curl -L -o /tmp/actions-runner.tar.gz \
        https://github.com/actions/runner/releases/download/v2.316.0/actions-runner-linux-x64-2.316.0.tar.gz \
    && tar xzf /tmp/actions-runner.tar.gz -C /opt/runner \
    && rm /tmp/actions-runner.tar.gz \
    && chown -R runner:runner /opt/runner

# =========================
# Финальная конфигурация
# =========================
USER runner
WORKDIR /opt/runner

COPY entrypoint.sh .

USER root
RUN chmod +x /opt/runner/entrypoint.sh
USER runner

ENTRYPOINT ["/bin/bash", "./entrypoint.sh"]