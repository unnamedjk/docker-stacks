FROM apache/superset:3.0.3rc3
USER root
WORKDIR /app
ENV LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=1
RUN pip install mysqlclient \
    && pip install sqlalchemy-mongobi sqlalchemy-singlestoredb
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
CMD ["/app/entrypoint.sh"]
EXPOSE 8088