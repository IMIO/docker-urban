FROM imiobe/plone-base:4.3.20-ubuntu as builder

COPY --chown=imio scripts /plone/scripts/
COPY --chown=imio *.cfg requirements.txt /plone/
COPY --chown=imio templates /plone/templates/

WORKDIR /plone

RUN buildDeps="libpq-dev wget git gcc libc6-dev libpcre3-dev libssl-dev libxml2-dev libxslt1-dev libbz2-dev libffi-dev libjpeg62-dev libopenjp2-7-dev zlib1g-dev python2-dev gosu poppler-utils wv rsync lynx netcat libxml2 libxslt1.1 libjpeg62 libtiff5 libopenjp2-7 python2" \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
  && python2 get-pip.py \
  && pip2 install -r requirements.txt 
RUN buildout -c urban-prod.cfg

FROM imiobe/plone-base:4.3.20-ubuntu

ENV PLONE_MAJOR=4.3 \
  PLONE_VERSION=4.3.2 \
  TZ=Europe/Brussel \
  ZEO_HOST=db \
  ZEO_PORT=8100 \
  HOSTNAME_HOST=local \
  PROJECT_ID=imio \
  SMTP_QUEUE_DIRECTORY=/data/queue

LABEL plone=$PLONE_VERSION \
  os="ubuntu" \
  name="Plone $PLONE_VERSION" \
  description="Plone image for urban" \
  maintainer="Imio"

COPY --chown=imio --from=builder /plone /plone
COPY --chown=imio docker-initialize.py docker-entrypoint.sh /

USER imio
VOLUME /data/blobstorage
VOLUME /data/filestorage
WORKDIR /plone
EXPOSE 8081
HEALTHCHECK --interval=1m --timeout=5s --start-period=45s \
  CMD nc -z -w5 127.0.0.1 8081 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
