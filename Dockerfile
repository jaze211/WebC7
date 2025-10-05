# ---- Stage 1: Build ----
FROM openjdk:8-jdk AS build

WORKDIR /app

# Copy source code + libs
COPY . /app

# Download servlet-api JAR để compile
RUN mkdir -p libs && \
    curl -L -o libs/servlet-api.jar https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/4.0.1/javax.servlet-api-4.0.1.jar

# Hàm tiện ích compile project -> WAR
# compile: javac src/java/*.java -> build/classes
# package: copy web/* -> build/classes, jar -> dist/xxx.war
RUN set -e; \
    for proj in ch07_ex1_download ch07_ex2_download ch07_ex3_cart; do \
      mkdir -p $proj/build/classes $proj/dist && \
      find $proj/src/java -name "*.java" > $proj/sources.txt && \
      javac -d $proj/build/classes -cp "libs/*" @$proj/sources.txt && \
      cp -r $proj/web/* $proj/build/classes/ && \
      cd $proj/build/classes && \
      jar cvf ../../dist/${proj}.war * && \
      cd /app; \
    done

# ---- Stage 2: Run ----
FROM tomcat:9-jdk11-openjdk

# Cấu hình Tomcat lắng nghe Render $PORT
RUN sed -i 's/port="8080"/port="${connector.port}"/' /usr/local/tomcat/conf/server.xml
RUN echo '#!/bin/sh' > /usr/local/tomcat/bin/setenv.sh && \
    echo 'if [ -z "$PORT" ]; then PORT=8080; fi' >> /usr/local/tomcat/bin/setenv.sh && \
    echo 'CATALINA_OPTS="$CATALINA_OPTS -Dconnector.port=$PORT"' >> /usr/local/tomcat/bin/setenv.sh && \
    chmod +x /usr/local/tomcat/bin/setenv.sh

# Copy WARs sang Tomcat
COPY --from=build /app/ch07_ex1_download/dist/ch07_ex1_download.war /usr/local/tomcat/webapps/ch07_ex1_download.war
COPY --from=build /app/ch07_ex2_download/dist/ch07_ex2_download.war /usr/local/tomcat/webapps/ch07_ex2_download.war
COPY --from=build /app/ch07_ex3_cart/dist/ch07_ex3_cart.war /usr/local/tomcat/webapps/ch07_ex3_cart.war

# Copy thêm libs (jstl, mysql, mail, poi) vào Tomcat
COPY --from=build /app/libs/*.jar /usr/local/tomcat/lib/

EXPOSE 8080
CMD ["catalina.sh", "run"]
