ARG TAG=latest
FROM scottyhardy/docker-remote-desktop:$TAG

COPY ./add /

# Install prerequisites
RUN chown root:root /zh && \
    chmod 1777 /zh && \
    apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        cabextract \
        gosu \
        gpg-agent \
        p7zip \
        pulseaudio-utils \
        software-properties-common \
        tzdata \
        unzip \
        wget \
        winbind \
        xvfb \
        zenity \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install wine
RUN wget -O- -nv https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --install-recommends winehq-stable \
    && rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget -nv https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/bin/winetricks \
    && chmod +x /usr/bin/winetricks

# Config Wine
RUN chsh -s /bin/bash wineuser && \
    RUN chsh -s /bin/bash wineuser && \
    su wineuser -c 'WINEARCH=win32 /usr/bin/wine wineboot' && \
    su wineuser -c '/usr/bin/wine regedit.exe /s /zh/wine.reg' && \
    su wineuser -c 'wineboot' && \
    echo 'quiet=on' > /etc/wgetrc && \
    su wineuser -c '/usr/local/bin/winetricks -q win7' && \
    su wineuser -c '/usr/local/bin/winetricks -q /zh/winhttp_2ksp4.verb' && \
    su wineuser -c '/usr/local/bin/winetricks -q msscript' && \
    su wineuser -c '/usr/local/bin/winetricks -q fontsmooth=rgb' && \
    wget https://dlsec.cqp.me/docker-simsun -O /zh/simsun.zip && \
    mkdir -p /home/wineuser/.wine/drive_c/windows/Fonts && \
    unzip /zh/simsun.zip -d /home/wineuser/.wine/drive_c/windows/Fonts && \
    mkdir -p /home/wineuser/.fonts/ && \
    ln -s /home/wineuser/.wine/drive_c/windows/Fonts/simsun.ttc /home/wineuser/.fonts/ && \
    chown -R wineuser:wineuser /home/wineuser && \
    su wineuser -c 'fc-cache -v' && \
    rm -rf /home/wineuser/.cache/winetricks /tmp/* /etc/wgetrc

# Download gecko and mono installers
COPY download_gecko_and_mono.sh /root/download_gecko_and_mono.sh
RUN /root/download_gecko_and_mono.sh

ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai 

COPY pulse-client.conf /root/pulse/client.conf
COPY entrypoint.sh /usr/bin/entrypoint
ENTRYPOINT ["/usr/bin/entrypoint"]
