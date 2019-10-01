# Dockerfile

FROM docker

RUN apk add -v --update bash curl python py-pip jq git file && \
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing hub

# awscli
ENV awscli 1.16.250
RUN pip install --upgrade awscli==${awscli} && \
    apk del -v --purge py-pip && \
    rm /var/cache/apk/*

VOLUME /root/.aws

ENTRYPOINT ["bash"]
