# Snazzy App

To use snazzy app, first set up the DB:

```
CREATE TABLE app (data TYPE VARCHAR(50));
INSERT INTO app ( data ) VALUES ( 'appname' );
```

Then you can see it by going to the URL:

```
localhost:3000
```

You need to set some environment variables.

Then you can change the app name by going to the URL:

```
localhost:3000?app_name=new_app_name
```
