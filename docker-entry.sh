#! /bin/bash -e

service apache2 start || service apache2 start

service postgresql start
if grep -q 'jdbcPassword.*changeit' /var/opt/midpoint/config.xml; then
  echo 'Setting a new password for midPoint DB'
  pass=`dd if=/dev/random bs=12 count=1 2>/dev/null | base64`
  sudo -u postgres psql -U postgres postgres -c "ALTER USER midpoint password '${pass}'"
  xmlstarlet ed --inplace --update '/configuration/midpoint/repository/jdbcPassword' --value "${pass}" /var/opt/midpoint/config.xml
fi

service tomcat8 start || :
exec "$@"
