==============
Without Docker
==============

| From the installation directory you created when you installed for the first time RootDB, run the same ``install.sh`` script :
| The script will :

* fetch the latest version of RootDB's ;
* will download it ;
* extract it ;
* make a backup of your  database ;
* run the SQL migration.

| You will have to restart yourself PHP-FPM process and Supervisor yourself..

.. tip::

    If you want to update to  a specific version of RootDB, you can use the script option ``-v <x.y.z>``
