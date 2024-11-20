### Pull from main
### Install required library
```cmd
pip install django-environ
```
### Set DB info locally
In `root/backend/backend` `.env`, you will see this block of code:
```.env
# Database configuration
DB_NAME=travelmingle
DB_USER=someUser
DB_PASSWORD=somePassword
DB_HOST=localhost
DB_PORT=5432
```

Replace your postgres username, password and port number in the code. you can find those info with

```psql
psql -U postgres
\conninfo
```
### Test
drop database, then use automate table creations in [Note.md](Note.md#automate-table-creations-with-django)

```psql
DROP DATABASE travelmingle;
```