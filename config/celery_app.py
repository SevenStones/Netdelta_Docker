from __future__ import absolute_import, unicode_literals
import os
from celery import Celery
from kombu import Exchange, Queue



# set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'netdelta.settings')

app = Celery('nd')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings')

# Load task modules from all registered Django app configs.
#app.autodiscover_tasks(lambda: settings.INSTALLED_APPS)

app.conf.task_queues = (
    Queue('SITE',  Exchange('SITE'),   routing_key='SITE'),
)
app.conf.task_default_queue = 'SITE'
app.conf.task_default_exchange_type = 'direct'
app.conf.task_default_routing_key = 'SITE'

@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))
