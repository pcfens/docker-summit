#!/bin/sh

PROPFILE="/usr/local/tomcat/conf/catalina.properties"
if [ ! -f "$PROPFILE" ]; then
  echo "Unable to find properties file $PROPFILE"
  exit 1
fi

# Set a property in the Tomcat catalina.properties file
setProperty() {
  prop=$1
  val=$2

  if [ $(grep -c "$prop" "$PROPFILE") -eq 0 ]; then
    echo "${prop}=$val" >> "$PROPFILE"
  else
    val=$(echo "$val" |sed 's#/#\\/#g')
    sed -i "s/$prop=.*/$prop=$val/" "$PROPFILE"
  fi
}

# Iterate over a file, merging the properties into the main settings file
setPropsFromFile() {
  file=$1
  for l in $(grep '=' "$file" | grep -v '^ *#'); do
    prop=$(echo "$l" |cut -d= -f1)
    val=$(cut -d= -f2- <<< "$l")
    setProperty "$prop" "$val"
  done
}

# Set tomcat property from environment variable
setPropFromEnv() {
  prop=$1
  val=$2
  # If no value was given, abort
  [ -z "$val" ] && return
  if [ $(grep -c "$prop" "$PROPFILE") -eq 0 ]; then
    echo "${prop}=$val" >> "$PROPFILE"
  else
    val=$(echo "$val" |sed 's#/#\\/#g')
    sed -i "s/$prop=.*/$prop=$val/" "$PROPFILE"
  fi
}

# If an environment variable contains the path to a file, use the contes of the
# file for the property, otherwise use the value of the variable
setPropFromEnvPointingToFile() {
  prop=$1
  val=$2
  [ -z "$val" ] && return
  # If the value is a file, use the contents of that file as the new value
  if [ -f "$val" ]; then
    val=$(cat "$val")
    setProperty "$prop" "$val"
  else
    # If it's not a file, use the value of the variable as the password
    setProperty "$prop" "$val"
  fi
}

# If we set CONFIG_FILE then use it to set more properties
# Docker and Kubernetes can both inject files at runtime (see docker config and
# k8s configmaps)
if [ -f "${CONFIG_FILE}" ]; then
  setPropsFromFile "${CONFIG_FILE}"
fi

setPropFromEnvPointingToFile db.password "$DB_PASSWORD"

if [ -z "$CONFIG_FILE" ]; then
  setPropFromEnv db.username "$DB_USERNAME"
  setPropFromEnv db.jdbc_string "$DB_JDBC_STRING"
  setPropFromEnv db.schema "$DB_SCHEMA"
fi

if [ -n "$JMX_PORT" ]; then
  export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$JMX_PORT -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
fi

exec bin/catalina.sh run
