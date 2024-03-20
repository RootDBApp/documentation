===========
With Docker
===========

| Here you can simply restart the ``rootdb`` service : ``docker container restart rootdb``
| At startup if in the ``.env`` file, used by ``docker-compose``, there is ``VERSION=latest`` then the container entry-point script will automatically fetch if there is a new version of RootDB available.
| If there's a new version available, the integrated update script will :

* will download it
* extract it
* make a backup of your  database
* run the SQL migration
