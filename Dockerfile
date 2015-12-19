#
#  Dockerfile for JSPWiki running in a tomcat 8 on top of OpenJDK7 on top of CentoS 7
#  Also install unzip, needed to unzip the default wikipages.
#
FROM tomcat:8.0.30
MAINTAINER Harry Metske <metskem@apache.org>
# we need the unzip command to unpack the war and zip files
USER root
RUN yum -y update
RUN yum install -y unzip
# create a directory where all jspwiki stuff will live
RUN mkdir /var/jspwiki && \
    chown tomcat.tomcat /var/jspwiki && \
#
# first remove default tomcat applications, we dont need them to run jspwiki
   cd /usr/local/tomcat/webapps && rm -rf examples host-manager manager docs ROOT && \
# create subdirectories where all jspwiki stuff will live
   cd /var/jspwiki && mkdir pages logs etc work && mkdir /usr/local/tomcat/webapps/ROOT
#
# add jspwiki war, create JSPWiki webapps dir, unzip it there.
ADD JSPWiki.war /tmp/jspwiki.war
RUN unzip -q -d /usr/local/tomcat/webapps/ROOT /tmp/jspwiki.war && rm /tmp/jspwiki.war && \
#
# download the default set of pages
   TF=/tmp/jspwikipages-download.zip && curl --silent http://apache.xl-mirror.nl/jspwiki/2.10.1/wikipages/jspwiki-wikipages-en-2.10.1.zip > $TF && unzip -q -d /tmp $TF && mv /tmp/jspwiki-wikipages-en-2.10.1/*  /var/jspwiki/pages && rm -r $TF /tmp/jspwiki-wikipages-en-2.10.1 && \
#
# move the userdatabase.xml and groupdatabase to /var/jspwiki/etc
   cd /usr/local/tomcat/webapps/ROOT/WEB-INF && mv userdatabase.xml groupdatabase.xml /var/jspwiki/etc && \
#
# arrange proper logging (jspwiki.use.external.logconfig = true needs to be set)
  echo -e \
"log4j.rootLogger=info,FileLog\n\
log4j.appender.FileLog = org.apache.log4j.RollingFileAppender\n\
log4j.appender.FileLog.MaxFileSize = 10MB\n\
log4j.appender.FileLog.MaxBackupIndex = 14\n\
log4j.appender.FileLog.File = /var/jspwiki/logs/jspwiki.log\n\
log4j.appender.FileLog.layout = org.apache.log4j.PatternLayout\n\
log4j.appender.FileLog.layout.ConversionPattern = %d [%t] %p %c %x - %m%n\n" > /usr/local/tomcat/lib/log4j.properties && \
# chown to tomcat
   chown -R tomcat.tomcat /usr/local/tomcat /var/jspwiki
#
# set default environment entries to configure jspwiki
ENV LANG en_US.UTF-8
ENV jspwiki_pageProvider VersioningFileProvider
ENV jspwiki_fileSystemProvider_pageDir /var/jspwiki/pages
ENV jspwiki_basicAttachmentProvider_storageDir /var/jspwiki/pages
ENV jspwiki_workDir /var/jspwiki/work
ENV jspwiki_xmlUserDatabaseFile /var/jspwiki/etc/userdatabase.xml
ENV jspwiki_xmlGroupDatabaseFile /var/jspwiki/etc/groupdatabase.xml
ENV jspwiki_use_external_logconfig true
# ENV jspwiki_templateDir
ENV jspwiki_baseURL http://localhost:8080/

# run with user tomcat
USER tomcat
# make port visible in metadata
EXPOSE 8080
# 
# by default we start the Tomcat container when the docker container is started.
CMD ["/usr/local/tomcat/bin/catalina.sh","run", ">/usr/local/tomcat/logs/catalina.out"]