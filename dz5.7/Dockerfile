FROM ubuntu
RUN apt update && \
    apt install -y wget gnupg2
RUN wget https://dl.google.com/linux/linux_signing_key.pub && \
    apt-key add linux_signing_key.pub
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > \
        /etc/apt/sources.list.d/google-chrome.list
ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
RUN apt update && \
    apt install -y google-chrome-stable
CMD ["/usr/bin/google-chrome","--no-sandbox"]
