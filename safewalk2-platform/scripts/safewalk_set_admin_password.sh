#!/bin/bash

ADMIN_PASSWORD=$1

source /home/safewalk/safewalk-server-venv/bin/activate
pushd /home/safewalk/safewalk_server
django-admin.py shell --settings=gaia_server.settings<<EOF
from accounts.models import AppUser
u = AppUser.objects.get(username='admin')
u.set_password('''$ADMIN_PASSWORD''')
u.save()
EOF
popd
deactivate

