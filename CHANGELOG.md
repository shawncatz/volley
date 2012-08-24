# Changelog

## v0.1.4:
* fix problem with expand path throwing errors when HOME environment variable is not set
* fix problem with volley:meta when the meta file doesn't exist
* add -q --quiet option to CLI (bumps log level to warn)
* add volley:published plan, show all published artifacts (used by jenkins for selecting version to deploy)
* add version_data method to publisher, primarily to have access to modified time for sorting
* bug fixes, meta and published plan work

## v0.1.3:
* bug fixes, meta and published plan work

## v0.1.2:
* add code to generate changelog
* attempting to publish a duplicate artifact shouldn't throw an error
* properly support force=true argument
* allow for stopping plan processing with plan#stop

## v0.1.1:
* add the ability to daemonize the process using Daemons gem.
* add Volley::Log#reset to forget previous log configuration in parent, before forking

