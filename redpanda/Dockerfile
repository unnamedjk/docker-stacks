FROM docker.redpanda.com/redpandadata/redpanda:v23.2.19
USER 0:0
RUN whoami
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]