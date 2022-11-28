#!/bin/sh

{
    mysql --user=$MYSQL_USER --password=$MYSQL_PASS --database=$MYSQL_DEV_DB --host=$MYSQL_DEV_HOST --port=$MYSQL_DEV_PORT --execute="
    CREATE EVENT update_applications_messages_number
    ON SCHEDULE EVERY 59 MINUTE
    STARTS (SELECT NOW() LIMIT 1)
    DO
    UPDATE applications SET chats_number = (SELECT COUNT(*) FROM chats WHERE chats.token = applications.token LIMIT 1);" && 
    mysql --user=$MYSQL_USER --password=$MYSQL_PASS --database=$MYSQL_DEV_DB --host=$MYSQL_DEV_HOST --port=$MYSQL_DEV_PORT --execute="
    CREATE EVENT update_chats_messages_number 
    ON SCHEDULE EVERY 59 MINUTE 
    STARTS (SELECT NOW() LIMIT 1) DO UPDATE chats SET messages_number = (SELECT COUNT(*) FROM messages WHERE messages.token = chats.token && messages.chat_number = chats.number LIMIT 1);"
} || echo "Database schedulars are already set"