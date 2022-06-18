# /xkcd_app/xkcd_app/views.py
import xkcd
from django.shortcuts import render

from .models import XKCDComicViews


def get_comic_and_increase_view_count(comic_number, increase_by=1):
    # get or create this with given comic_number
    comic, _ = XKCDComicViews.objects.get_or_create(pk=comic_number)
    comic.view_count += increase_by  # increase the view_count
    comic.save()  # save it


def homepage(request):
    # get a random comic from xkcd lib.
    random_comic = xkcd.getRandomComic()
    # increase it's view count
    get_comic_and_increase_view_count(random_comic.number, increase_by=1)
    # create a context to render the html with.
    context = {
        "number": random_comic.number,
        "image_link": random_comic.getImageLink(),
        "title": random_comic.getTitle(),
        "alt_text": random_comic.getAltText(),
    }
    # return rendered html.
    return render(request, "xkcd_app/homepage.html", context)
