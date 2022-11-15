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