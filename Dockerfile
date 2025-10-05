# ---- Stage 1: Build ----
FROM openjdk:8-jdk AS build

WORKDIR /app

# Install Ant and wget (for downloading dependencies)
RUN apt-get update && apt-get install -y ant wget && rm -rf /var/lib/apt/lists/*

# Download javax.servlet-api for compilation
RUN wget https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/4.0.1/javax.servlet-api-4.0.1.jar -O /app/javax.servlet-api-4.0.1.jar

# Copy source code and build files (including the new JAR in libs)
COPY . /app

# Create dist directories for WAR output
RUN mkdir -p /app/ch07_ex1_download/dist \
    /app/ch07_ex2_download/dist \
    /app/ch07_ex3_cart/dist

# Build ch07_ex1_download using Ant
RUN cd ch07_ex1_download && \
    ant -f build.xml dist -Dlibs.dir=/app/libs -Dservlet-api.jar=/app/javax.servlet-api-4.0.1.jar -Dlibs.CopyLibs.classpath=/app/libs/org-netbeans-modules-java-j2seproject-copylibstask.jar

# Build ch07_ex2_download using Ant
RUN cd ch07_ex2_download && \
    ant -f build.xml dist -Dlibs.dir=/app/libs -Dservlet-api.jar=/app/javax.servlet-api-4.0.1.jar -Dlibs.CopyLibs.classpath=/app/libs/org-netbeans-modules-java-j2seproject-copylibstask.jar

# Build ch07_ex3_cart using Ant
RUN cd ch07_ex3_cart && \
    ant -f build.xml dist -Dlibs.dir=/app/libs -Dservlet-api.jar=/app/javax.servlet-api-4.0.1.jar -Dlibs.CopyLibs.classpath=/app/libs/org-netbeans-modules-java-j2seproject-copylibstask.jar

# ---- Stage 2: Run ----
FROM tomcat:9-jdk11-openjdk

# Configure Tomcat to use Render's $PORT (fallback to 8080)
RUN sed -i 's/port="8080"/port="${connector.port}"/' /usr/local/tomcat/conf/server.xml
RUN echo '#!/bin/sh' > /usr/local/tomcat/bin/setenv.sh && \
    echo 'if [ -z "$PORT" ]; then' >> /usr/local/tomcat/bin/setenv.sh && \
    echo '  PORT=8080' >> /usr/local/tomcat/bin/setenv.sh && \
    echo 'fi' >> /usr/local/tomcat/bin/setenv.sh && \
    echo 'CATALINA_OPTS="$CATALINA_OPTS -Dconnector.port=$PORT"' >> /usr/local/tomcat/bin/setenv.sh && \
    chmod +x /usr/local/tomcat/bin/setenv.sh

# Copy WAR files to Tomcat webapps
COPY --from=build /app/ch07_ex1_download/dist/ch07_ex1_download.war /usr/local/tomcat/webapps/ch07_ex1_download.war
COPY --from=build /app/ch07_ex2_download/dist/ch07_ex2_download.war /usr/local/tomcat/webapps/ch07_ex2_download.war
COPY --from=build /app/ch07_ex3_cart/dist/ch07_ex3_cart.war /usr/local/tomcat/webapps/ch07_ex3_cart.war

EXPOSE 8080
CMD ["catalina.sh", "run"]