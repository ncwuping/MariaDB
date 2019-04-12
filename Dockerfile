# vim:set ft=dockerfile:
FROM centos:latest

ENV MARIADB_MAJOR 10.2
RUN set -xe; \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
    groupadd -r mysql && useradd -r -g mysql mysql; \
    { \
      echo '# MariaDB 10.2 CentOS repository list - created 2019-04-10 06:31 UTC'; \
      echo '# http://downloads.mariadb.org/mariadb/repositories/'; \
      echo '[mariadb]'; \
      echo 'name=MariaDB'; \
      echo "baseurl=https://yum.mariadb.org/$MARIADB_MAJOR/centos7-amd64"; \
      echo 'enabled=1'; \
      echo 'gpgcheck=1'; \
      echo 'gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB'; \
    } > /etc/yum.repos.d/MariaDB.repo \
 && yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm \
 && yum clean all -y \
 && yum makecache fast \
 && yum install -y \
        pwgen \
        MariaDB-server \
        MariaDB-client \
        percona-xtrabackup-24 \
        socat \
        tzdata \
 && yum clean all -y \
 && rm -rf /var/cache/yum \
# comment out any "user" entires in the MySQL config ("docker-entrypoint.sh" or "--user" will handle user switching)
# && sed -ri 's/^user\s/#&/' /etc/my.cnf /etc/my.cnf.d/* \
# purge and re-create /var/lib/mysql with appropriate ownership
 && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
 && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
 && chmod 777 /var/run/mysqld
# comment out a few problematic configuration values
# && find /etc/my.cnf.d/ -name '*.cnf' -print0 | \
#    xargs -rt -0 grep -lZE '^(bind-address|log)' | \
#    xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
# don't reverse lookup hostnames, they are usually another container
# && echo -e '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/my.cnf.d/docker.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && mkdir -p /docker-entrypoint-initdb.d \
 && ln -s usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]

COPY galera.cnf /etc/

EXPOSE 3306
CMD ["mysqld"]
