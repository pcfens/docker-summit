FROM amazoncorretto:8

EXPOSE 8080
HEALTHCHECK CMD curl -f http://localhost:8080/ || exit 1

ENV UMASK=022

RUN rm /etc/localtime \
    # Set the timezone
    && ln -s /usr/share/zoneinfo/America/New_York /etc/localtime \
    # # Install some packages we need for {user,group}add below
    && yum install util-linux procps -y \
    && yum clean all \
    && rm -Rf /var/cache/yum

# Copy the tomcat component of the download into the container
COPY vendor_download/tomcat /usr/local/tomcat

# Copy our custom start script and configuration files into the image
COPY run.sh /usr/local/tomcat/bin/
COPY *.xml /usr/local/tomcat/conf/

# Create a Tomcat user/group
RUN groupadd -r tomcat -g 91 \
    && useradd -u 91 -r -g tomcat -d /usr/local/tomcat -s /sbin/nologin tomcat \
    && chown -R tomcat:tomcat /usr/local/tomcat

# Do everything from here down as the tomcat user instead of root
USER tomcat

# Set the working directory
WORKDIR /usr/local/tomcat

# Run our wrapper script at startup
CMD ["bin/run.sh"]
