# Базовый образ
FROM ubuntu:22.04

# Переменные Android
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools
ENV HAS_SIGNING_CONFIG=false

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    curl unzip git jq ca-certificates sudo openjdk-17-jdk \
    lib32stdc++6 lib32gcc-s1 lib32ncurses6 lib32z1 \
    && rm -rf /var/lib/apt/lists/*

# Создаем пользователя runner
RUN useradd -m runner && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Сразу создаём нужные директории для SDK и Gradle
RUN mkdir -p /opt/runner /opt/android-sdk/cmdline-tools /home/runner/.gradle \
    && chown -R runner:runner /opt/runner /opt/android-sdk /home/runner

# Переходим к пользователю runner
USER runner
WORKDIR /home/runner

# Установка Android SDK (от root)
USER root
RUN curl -L -o cmdline.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip cmdline.zip \
    && mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm cmdline.zip \
    && chown -R runner:runner $ANDROID_HOME

# Согласие с лицензиями и установка платформы
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"

# Установка GitHub Actions Runner (от root для корректных прав)
USER root
RUN curl -o /tmp/actions-runner.tar.gz -L \
    https://github.com/actions/runner/releases/download/v2.316.0/actions-runner-linux-x64-2.316.0.tar.gz \
    && tar xzf /tmp/actions-runner.tar.gz -C /opt/runner \
    && rm /tmp/actions-runner.tar.gz \
    && chown -R runner:runner /opt/runner

# Возвращаемся к пользователю runner и рабочей директории
USER runner
WORKDIR /opt/runner

# Копируем скрипт запуска runner
COPY entrypoint.sh .

# Делаем entrypoint исполняемым
USER root
RUN chmod +x /opt/runner/entrypoint.sh
USER runner

# ENTRYPOINT через bash для гарантии запуска
ENTRYPOINT ["/bin/bash", "./entrypoint.sh"]
