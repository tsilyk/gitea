FROM alpine:latest
EXPOSE 22 3000
COPY ./gitea /gitea
RUN apk add git

RUN addgroup -S -g 1000 git && \
    adduser -S -H -D -h /data/git -s /bin/bash -u 1000 -G git git && \
    echo "git:*" | chpasswd -e

USER git
ENV GITEA_CUSTOM /data/gitea

VOLUME ["/data"]
CMD ["/gitea", "web"]
