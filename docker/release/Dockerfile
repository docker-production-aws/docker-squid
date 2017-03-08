FROM alpine
MAINTAINER Justin Menga <justin.menga@gmail.com>
ARG app_name
LABEL application=${app_name}
HEALTHCHECK --interval=3s --retries=20 CMD nc -z localhost 3128

# Install packages
RUN echo "http://nl.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --no-cache --update bash confd squid

# Redirect squid access logs to stdout
RUN ln -sf /dev/stdout /var/log/squid/access.log

# Copy confd configuration
COPY src/etc/confd /etc/confd

# Set entrypoint and default command arguments
COPY src/entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["squid","-f","/etc/squid/squid.conf","-NYCd","1"]
