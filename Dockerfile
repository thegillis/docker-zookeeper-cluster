FROM jplock/zookeeper:3.4.6

ENV ZOOKEEPER_VERSION 3.4.6

COPY run.sh /run.sh
RUN chmod a+x /run.sh && \
    cp -Rv /opt/zookeeper/conf /opt/zookeeper/conf-dist

ENTRYPOINT ["/bin/bash"]
CMD ["/run.sh"]

