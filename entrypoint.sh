#!/bin/sh
export JWT_SECRET=$(cat /app/JWT_SECRET)
export DATABASE_PASSWORD=root
export DATABASE_USER=root
exec java -jar /app/kotatsu-syncserver.jar
