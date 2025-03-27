FROM gradle:8-jdk11-alpine AS build

COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle shadowJar --no-daemon

FROM openjdk:11
RUN mkdir /app
COPY --from=build /home/gradle/src/build/libs/*-all.jar /app/kotatsu-syncserver.jar
COPY --from=build /home/gradle/src/database.sql /app/database.sql
COPY --from=build /home/gradle/src/entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

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

# Deploy
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
