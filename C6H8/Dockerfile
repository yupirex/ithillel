FROM debian
MAINTAINER YupiRex
RUN apt update && \
    apt install -y \
        python-pip
RUN pip install shadowsocks
RUN sed -i \
        's/EVP_CIPHER_CTX_cleanup/EVP_CIPHER_CTX_reset/g' \
        /usr/local/lib/python2.7/dist-packages/shadowsocks/crypto/openssl.py
ENTRYPOINT ["/usr/local/bin/ssserver"]


# Usage
# pass=strongpasword; docker run --rm -d yupi/ssserver -k $pass
# pass=strongpasword; docker run --rm -d yupi/ssserver -s 0.0.0.0 -p 8388 -k $pass -m aes-256-cfb
# docker run --rm -v /home/shadowsocks.json:/tmp/config.json -ti yupi/ssserver -c /tmp/config.json


# echo -n "ss://"`echo -n aes-256-cfb:password@1.2.3.4:8388 | base64`


#Congif
#{
#  "server":"0.0.0.0",
#  "server_port":8388,
#  "local_address": "127.0.0.1",
#  "local_port":1080,
#  "password":"password",
#  "timeout":300,
#  "method":"aes-256-cfb",
#  "fast_open": false
#}
