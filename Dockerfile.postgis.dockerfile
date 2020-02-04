FROM kartoza/postgis:11.0-2.5
LABEL maintainer="Gis3W" Description="Fix DB restart"
ADD setup-database.sh /