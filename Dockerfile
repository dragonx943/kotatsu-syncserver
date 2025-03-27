FROM gradle:8-jdk17 AS cache

RUN mkdir -p /home/gradle/cache_home
ENV GRADLE_USER_HOME=/home/gradle/cache_home
COPY build.gradle.* gradle.properties /home/gradle/app/
COPY gradle /home/gradle/app/gradle
COPY database.sql /home/gradle/
COPY entrypoint.sh /home/gradle/
WORKDIR /home/gradle/app
RUN gradle clean build -i --stacktrace

FROM gradle:8-jdk17 AS build
COPY --from=cache /home/gradle/cache_home /home/gradle/.gradle
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle shadowJar --no-daemon

FROM eclipse-temurin:17-jre
RUN mkdir /app
COPY --from=build /home/gradle/src/build/libs/*-all.jar /app/kotatsu-syncserver.jar
COPY --from=cache /home/gradle/database.sql /app/database.sql
RUN apt-get update && \
    apt-get install -y mysql-server nodejs && \
    apt-get clean
RUN echo 'root:root' | chpasswd && passwd -u root
ENV DATABASE_PASSWORD=root
ENV DATABASE_USER=root
RUN service mysql start && \
    mysql -e "CREATE DATABASE kotatsu_db;" && \
    mysql -h localhost -u $DATABASE_USER -p $DATABASE_PASSWORD kotatsu_db < /app/database.sql
RUN node -e "console.log(require('crypto').randomBytes(32).toString('hex'));" > /app/JWT_SECRET
CMD export JWT_SECRET=$(cat /app/JWT_SECRET)

EXPOSE 8080

COPY --from=cache /home/gradle/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
