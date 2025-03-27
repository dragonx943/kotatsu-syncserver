FROM openjdk:11
RUN mkdir /app
COPY ./database.sql /app/database.sql
COPY ./entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

RUN apt-get update && \
    apt-get install -y mariadb-server nodejs && \
    apt-get clean && curl -o /app/kotatsu-syncserver.jar https://github.com/dragonx943/kotatsu-syncserver/releases/download/0.0.1/kotatsu.jar

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
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
