==============
Without Docker
==============

| You can use the same bash script you used for installation : :download:`install.sh <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/bash/install.sh>`.
| Run it this way : ``./install.sh -e env``
| The script will :

* fetch the latest version of RootDB's ;
* will download it ;
* extract it ;
* make a backup of your  database ;
* run the SQL migration.

| You will have to restart yourself PHP-FPM process and Supervisor yourself..

.. tip::

    If you want to update to  a specific version of RootDB, you can use the script option ``-v <x.y.z>``
