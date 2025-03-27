FROM ubuntu:jammy

RUN mkdir /app
COPY . /app

RUN chmod +x /app/entrypoint.sh

RUN apt-get update && \
    apt-get install -y mariadb-server nodejs openjdk-17-jdk curl && \
    apt-get clean

WORKDIR /app
RUN chmod a+x gradlew && ./gradlew shadowJar
COPY /app/build/libs/*-all.jar /app/kotatsu-syncserver.jar

RUN echo 'root:root' | chpasswd && passwd -u root

ENV DATABASE_USER=root
RUN service mariadb start && \
    mysql -e "CREATE DATABASE kotatsu_db;" && \
    echo "Done #1" && \
    mariadb -h localhost -u $DATABASE_USER kotatsu_db < /app/database.sql && \
    echo "Done #2"

RUN node -e "console.log(require('crypto').randomBytes(32).toString('hex'));" > /app/JWT_SECRET
CMD export JWT_SECRET=$(cat /app/JWT_SECRET)

# Deploy
EXPOSE 8080:8080
ENTRYPOINT ["bash", "/app/entrypoint.sh"]
