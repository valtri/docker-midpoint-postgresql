FROM valtri/docker-midpoint:3.6.1
MAINTAINER František Dvořák <valtri@civ.zcu.cz>

ENV v 3.6.1
ENV schema config/sql/_all/postgresql-3.6-all.sql

WORKDIR /root

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpostgresql-jdbc-java \
    postgresql \
    sudo \
&& rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/share/java/postgresql.jar /var/lib/tomcat8/lib/

ENV PATH $PATH:/usr/lib/postgresql/9.4/bin
RUN useradd -r -s /bin/bash midpoint
RUN wget -nv https://raw.githubusercontent.com/Evolveum/midpoint/v${v}/${schema}
RUN pass='changeit' \
&& service postgresql start \
&& sudo -u postgres psql -U postgres postgres -c "CREATE USER midpoint password '${pass}'" \
&& sudo -u postgres createdb --owner=midpoint --encoding=UTF8 --locale=C.UTF-8 midpoint \
&& sudo -u postgres psql -U postgres postgres -c "ALTER DATABASE midpoint CONNECTION LIMIT -1" \
&& sudo -u midpoint psql midpoint < `basename ${schema}`

RUN xmlstarlet ed --inplace --update '/configuration/midpoint/repository' --value '' /var/opt/midpoint/config.xml
COPY config-repo.txt .
RUN while read key value; do xmlstarlet ed --inplace --subnode /configuration/midpoint/repository --type elem --name ${key} --value ${value} /var/opt/midpoint/config.xml; done < config-repo.txt
RUN rm config-repo.txt

RUN rm -fv /var/opt/midpoint/midpoint*.db

RUN mv /docker-entry.sh /docker-entry-base.sh
COPY docker-entry.sh /
