### Pull from main

### Install required library

```cmd
pip install django-environ
```

### Set DB info locally

Create file named `.env` in `root/backend` and add this block of code:

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
'''cmd
cd backend
python manage.py dbshell
'''
If the connection is successful, Django will apply the migrations or indicate that everything is up-to-date. If there’s an issue with the credentials, you’ll see an error message.