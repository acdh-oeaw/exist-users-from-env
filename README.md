eXist users from env
====================

This is an eXist-db helper package that reads user names, group names and passwords from the environment variables and creates them
when autodeployed

When do I need this
-------------------

The typical scenario for using this package is using an eXist-db on kubernetes without any other means of user authentication.
Typically in such a setup the usernames, groups and passwords will be stored as a "Secret" and these can be set as environment
variables in a container easyly.

How do I use this package
-------------------------

Build the container for your eXist-db app and add it's .xar and the `existufe-*.xar` to the autodeploy directory `/exist/autodeploy`.
You probably want this package to be installed and executed before your app. The packages are largely installed in alphabetical order.
So maybe you need to rename this package like `01_existufe-*.xar`.

Environment variables
---------------------
|                name                |                      value                      |                    note                     |
| :--------------------------------: | :---------------------------------------------: | :-----------------------------------------: |
|     EXIST_admin_password_file      |                   a filename                    |  references a file containing the password  |
|        EXIST_admin_password        |                   a password                    | the password to set for the admin user [^1] |
| EXIST_user_$username_password_file |                   a filename                    |  references a file containing the password  |
|   EXIST_user_$username_password    |                   a password                    | the password to set for the admin user [^1] |
|       EXIST_group_$groupname       | a comma separated list of members of that group |                                             |

[^1]: Every program with access to the environment can read this secret. I a standard eXist-db container this is just eXist-db and there is no shell so it is reasonable secure