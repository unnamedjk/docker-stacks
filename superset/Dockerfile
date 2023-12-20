FROM apache/superset:2.0.1
USER root
WORKDIR /app
ENV LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=1
RUN pip install mysqlclient \
    && pip install sqlalchemy-mongobi
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
CMD ["/app/entrypoint.sh"]
EXPOSE 8088