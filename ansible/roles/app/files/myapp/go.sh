env APPL_CIDR="10.147.0.0/16" \
    PGUSER=dbuser \
    PGHOST=127.0.0.1 \
    PGPASSWORD=DBPASSWORD \
    PGDATABASE=appdatabase \
    DEBUG=myapp:* npm start
