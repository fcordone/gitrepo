python3 create_mongo_user.py -h

python3 create_mongo_user.py wdev files/bank-service-dev.yml mongo-wdev.yml

mongo-xxxx-yml files are not commited to the repo due the sensitive data on it.
format is :
```
---
- hosts: 127.0.0.1
  connection: local
  gather_facts: no

  tasks:
    - mongodb_user:
       login_database: admin
       login_host: <host>
       login_password: <passwd>
       login_port: 27017
       login_user: <adminuser>
       state: present
       update_password: on_create
       database: "{{ database }}"
       name: "{{ username }}"
       password: "{{ password }}"
       roles: "{{ dbroles }}"
```


prerequisites:
pyhton, pip, ansible, pymongo
```
pip install pymongo
```
