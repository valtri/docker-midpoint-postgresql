FROM valtri/docker-midpoint:latest
MAINTAINER František Dvořák <valtri@civ.zcu.cz>

ENV v 3.4
#ENV schema config/sql/midpoint/3.4/postgresql/postgresql-3.4.sql
ENV schema config/sql/_all/postgresql-3.4-all.sql

WORKDIR /root

RUN apt-get update && apt-get install -y \
    libpostgresql-jdbc-java \
    postgresql \
    sudo \
&& rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/share/java/postgresql.jar /var/lib/tomcat8/lib/
# for repo-ninja
RUN ln -s /usr/share/java/postgresql.jar /root/midpoint-${v}/lib/

ENV PATH $PATH:/usr/lib/postgresql/9.4/bin
RUN pass='changeit' \
&& service postgresql start \
&& sudo -u postgres psql -U postgres postgres -c "CREATE USER midpoint password '${pass}'" \
&& sudo -u postgres createdb --owner=midpoint midpoint \
&& sudo -u postgres psql midpoint < midpoint-${v}/${schema}

RUN xmlstarlet ed --inplace --update '/configuration/midpoint/repository' --value '' /var/opt/midpoint/config.xml
COPY config-repo.txt .
RUN while read key value; do xmlstarlet ed --inplace --subnode /configuration/midpoint/repository --type elem --name ${key} --value ${value} /var/opt/midpoint/config.xml; done < config-repo.txt
RUN rm config-repo.txt

RUN rm -fv /var/opt/midpoint/midpoint*.db

COPY docker-entry.sh /
