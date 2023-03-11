FROM alpine:3.17
LABEL maintainer="yuriy.tsilyk@gmail.com"

EXPOSE 2222 3000

RUN apk --no-cache add bash ca-certificates dumb-init gettext git curl gnupg

RUN addgroup -S -g 1000 git && \
    adduser -S -H -D -h /var/lib/gitea/git -s /bin/bash -u 1000 -G git git

COPY ./containers/root /
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    mkdir -p /var/lib/gitea /etc/gitea && \
    chown git:git -R /var/lib/gitea /etc/gitea

#git:git
USER 1000:1000
ENV GITEA_WORK_DIR /var/lib/gitea
ENV GITEA_CUSTOM /var/lib/gitea/custom
ENV GITEA_TEMP /tmp/gitea
ENV TMPDIR /tmp/gitea
ENV GITEA_APP_INI /etc/gitea/app.ini
ENV HOME "/var/lib/gitea/git"
VOLUME ["/var/lib/gitea", "/etc/gitea"]
WORKDIR /var/lib/gitea

#ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/bin/docker-entrypoint.sh"]
ENTRYPOINT ["/bin/sh", "-c", "tail"]
CMD []

