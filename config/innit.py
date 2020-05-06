from __future__ import absolute_import, unicode_literals
default_app_config = 'nd.apps.Job_scheduleConfig'

# This will make sure the app is always imported when
# Django starts so that shared_task will use this app.
from .celery_app import app as celery_thang

__all__ = ('celery_thang',)
