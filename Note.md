# Nov 24 2024 Recreate the db and load with new data

## Drop `travelmingle` db and re-create a new one

### 1. Log in the db through terminal, and user the command below

```
DROP DATABASE travelmingle;
CREATE DATABASE travelmingle;
\l

```

Use `\l` to check if `travelmingle` is gone.

### 2. Install jwt for authentication

I did this in vscode at project root. I am not using veritual env, so it doesn't matter where I did it.

```
pip install djangorestframework-simplejwt

```

### 3. DB migration

Go to `backend/api/migrations` folder, delete all files `BUT` `_init_.py`. If you don't do this, the command won't work.

```
cd travelmingle/backend
python manage.py makemigrations
python manage.py migrate
python manage.py loaddata users_fixture.json
python manage.py loaddata posts_fixture.json
python manage.py loaddata postImages_fixture.json
python manage.py loaddata comments_fixture.json
python manage.py loaddata likes_fixture.json

```

After this you should have 5 users with psw `123`, please check user name in the json file.

### 4. Run the project

Open two terminals in vscode. Run android emulator.

terminal 1

```
cd backend
python manage.py runserver

```

terminal 2

```
cd demo
flutter clean
flutter pub get
flutter run

```  

# End of new update


# How to run the backend with Django

This part assumes you have installed vscode, python 12+, and postgrSQL. This is a check for everyone if the backend is running on your machine.

## 1. pull from main

## 2. How do I check what libraries I need to install

In `root/backend/backend` `settings,py`, you will see this block of code:

```

INSTALLED_APPS = [
'django.contrib.admin',
'django.contrib.auth',
'django.contrib.contenttypes',
'django.contrib.sessions',
'django.contrib.messages',
'django.contrib.staticfiles',
'api',
'rest_framework',
'drf_yasg',
]

```

This is where you should check for `pip install`. Please use AI here to help you to identify what libraried you need to install. For the current code above, we need to run:

```

pip install django
pip install djangorestframework
pip install drf-yasg
pip install pillow
pip install psycopg2 or pip install psycopg2-binary
(please ask AI to match this with your own python version)

```

for Python 3.13:

```

pip install django
pip install djangorestframework
pip install drf-yasg
pip install pillow
pip install psycopg
pip install --upgrade psycopg[binary]

```

## 3. How to connect with your postgres local database server

We are not using remote host for now due to financial cost issue.
We need to have identical database tables and dummy data on our local machines.

### - Create your own database named `travelmingle`

In your powershell run:

```

psql -U postgres

```

You will be prompted to type password, please type the password you set up earlier when you were instlling postgres. Once you correctly log in your local postgres:

![postgres log in](image-6.png)

After you see this screen, check what databases you have by typing `\l`, and you will see:
![databases](image-7.png)

You won't have `travelmingle` on there. Let's create one now:

```

CREATE DATABASE travelmingle;

```

Verify you have created a database called `travelmingle`:

```

\l

```

### - Connect your django backend to your local postgres database

Go to `root/backend/backend` `settings,py`, find this block of code:

```

DATABASES = {
'default': {
'ENGINE': 'django.db.backends.postgresql',
'NAME': 'travelmingle',
'USER': 'yourusername',
'PASSWORD': 'yourpassword',
'HOST': 'localhost',
'PORT': '5432',
}
}

```

Replace your postgres username, password and port number in the code. Default username is `postgres`. You should see all these three values while setting up your postgres for the first time. Also, you can find those infor by `\conninfo`

### - Automate table creations with Django

Go to `backend/api` and find `models.py`.

Django framework enables you to create a models.py file to define your table classes. For example, we have a `posts` table, then we should have a `posts` class in this file. Now that we have defined these tables, we can run a command to create the tables in the database.

```

cd backend/
python manage.py makemigrations
python manage.py migrate

```

Let's verify we have created these tables in travelmingle by running in the terminal we logged in with postgres:

```

\c travelmingle
\dt

```

You should see a long list of tables. Some of them are django default that we can ignore. But make sure you see `posts`, `users`, `post_images`, `comments` tables, which should match your `models.py`.

Many things could go wrong at this step, please take time to check if your python verison is correct, and take the advantage of AI to debug.

### - How to add dummy data to your local database

There are two josn files called `posts_fixture.json` and `users_fixture.json` in the `backend` folder. We will run these command to add these data to the local db:

```

cd backend (you should be at travelmingle/backend )
python manage.py loaddata users_fixture.json
python manage.py loaddata posts_fixture.json

```

Now let's verify the data is added to your local db:
In the db terminal we logged in previously run :

```

\c travelmingle
select _ from users;
select _ from posts;

```

You should see some data in both select queries.

## 4. Finnally let's check if the backend is working

### - where is the database logic code for get,post, put and delete

Go to `travelmingle/api` find `views.py`. This is where all the logic code is at.

### - run the backend and test

```

cd backend (you should be at travelmingle/backend)

python manage.py runserver

```

Go to the url `http://127.0.0.1:8000/swagger/` to check all the current api endpoints. You can also perform the endpoint tests there if you want to.

Or, you can use these url if you are tesing in browser or Postman:
`http://127.0.0.1:8000/api/users/`
`http://127.0.0.1:8000/api/posts/`
`http://127.0.0.1:8000/api/posts/:id`
`http://127.0.0.1:8000/api/users/:id`
...

To see the full lists of endpoint you either check in `travelmingle/backend/api` `urls.py`.
Or, you can check on the swagger page.

## How to change the database tables if needed

If we want to change the table structure, we need to make sure the `models.py` and its corresponding fixture json files are changed. Please inform everyone on the team and make sure the code runs on all of our machines.

```

```
