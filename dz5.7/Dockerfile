FROM ubuntu
RUN apt update && \
    apt install -qy wget gnupg2
RUN wget https://dl.google.com/linux/linux_signing_key.pub && \
    apt-key add linux_signing_key.pub
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > \
        /etc/apt/sources.list.d/google-chrome.list
ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
RUN apt update && \
    apt install -qy google-chrome-stable
RUN usr/sbin/useradd \
    --home /home/user \
    --create-home \
    --comment "google-chrome" \
    --shell /bin/bash \
    user
USER user
CMD ["/usr/bin/google-chrome","--no-sandbox"]
