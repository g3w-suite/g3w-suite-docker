import os
limit_request_fields = 0
error_logfile        = '-'
accesslog            = '-'
access_log_format    = '[REQUEST] %(p)s "%(s)s %(m)s %(U)s %(H)s"'
# access_log_format    = '[REQUEST] %(s)s\n\t"%(m)s %(U)s %(H)s"\n\t"FROM %(f)s"\n\t"AGENT %(a)s"\n\t%(p)s'
log_level            = 'info'
timeout              = os.getenv('G3WSUITE_GUNICORN_TIMEOUT', 120)
workers              = os.getenv('G3WSUITE_GUNICORN_NUM_WORKERS', 8)
max_requests         = os.getenv('G3WSUITE_GUNICORN_MAX_REQUESTS', 200)
bind                 = '0.0.0.0:8000'
reload               = os.path.ismount('/code')
