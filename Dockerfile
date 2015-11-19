FROM jplock/zookeeper:latest

ENV ZOOKEEPER_VERSION latest

COPY run.sh /run.sh
RUN chmod a+x /run.sh && \
    cp -Rv /opt/zookeeper/conf /opt/zookeeper/conf-dist

ENTRYPOINT ["/bin/bash"]
CMD ["/run.sh"]

