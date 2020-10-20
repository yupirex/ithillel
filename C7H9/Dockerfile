FROM openjdk:11-jre-slim
MAINTAINER Yupi
RUN apt-get update && apt-get install -qy wget

# Create the installation directory
RUN useradd \
        --home /opt/jira \
        --create-home \
        --comment "Account for running Jira Software" \
        --shell /bin/bash jira && \
    chmod -R u=rwx,go-rwx /opt/jira

# Download Jira
RUN wget -O- \
        https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.13.0.tar.gz |\
        tar zx -C /opt/jira && \
    mv /opt/jira/atlassian-jira-software-8.13.0-standalone/* /opt/jira

# Tell Jira where to find your <home-directory> There are two ways to do this:
ENV JIRA_HOME=/home/jira/
#RUN sed -i \
#        "s%jira.home.*$%jira.home = /home/jira%" \
#        /opt/jira/atlassian-jira/WEB-INF/classes/jira-application.properties

USER jira
ENTRYPOINT /opt/jira/bin/start-jira.sh -fg 

# Create the home directory after container start "-v /home/${USER}/jira:/home/jira"
# docker run --rm --name jira -v /home/${USER}/jira:/home/jira jira
# Create network for use static ip
# docker network create --subnet 172.18.0.0/29 --gateway 172.18.0.6 jiranet
# docker run --rm --name jira -v /home/${USER}/jira:/home/jira --net jiranet --ip 172.18.0.2 jira
# http://172.18.0.2:8080
#-----=====-----=====-----=====-----=====-----=====-----=====-----=====-----=====

