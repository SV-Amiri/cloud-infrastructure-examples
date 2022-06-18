# xkcd_app/xkcd_app/models.py
from django.db import models


class XKCDComicViews(models.Model):
    comic_number = models.IntegerField(primary_key=True, unique=True)
    view_count = models.IntegerField(default=0)
