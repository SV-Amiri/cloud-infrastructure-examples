# Django commands
django_app_name="xkcd_app"
django-admin startproject ${django_app_name}
(
cd ${django_app_name}
python manage.py migrate && python manage.py migrate ${django_app_name}
python manage.py runserver 0.0.0.0:8000
)
