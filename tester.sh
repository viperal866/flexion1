#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 <route53_nameserver>"
    exit 1
fi

APP_IP=$(nslookup coolapp.com $1 | grep "Address: " | head -n 1 | awk -F: '{print $2}')

test_update() {
    echo "+ curl -s http://$1:3000/?app_name=$2 | grep \"Welcome to $2\" >> /dev/null"
    curl -s http://$1:3000/?app_name=$2 | grep "Welcome to $2" >> /dev/null
    if [ $? -eq 0 ]; then
        echo "Updated!"
    else
        echo "Failed to update $2 at $1!"
        exit 1
    fi
}

test_read() {
    echo "+ curl -s http://$1:3000 | grep \"Welcome to $2\" >> /dev/null"
    curl -s http://$1:3000 | grep "Welcome to $2" >> /dev/null
    if [ $? -eq 0 ]; then
        echo "Read!"
    else
        echo "Failed to read $2 at $1!"
        exit 1
    fi
}

while true; do
    for i in foo bar baz bop baloo baloon bip bundle hello world; do
        test_update $APP_IP $i
        test_read $APP_IP $i
    done
done
