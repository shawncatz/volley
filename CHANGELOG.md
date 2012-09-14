# Changelog

## v0.1.9:
* remove dependency on awesome_print and debug statements. fail me.
* more docopt fixes
* handle docopt exit for --version
* update to use newest docopt version
* working on getting 'auto' source working

## v0.1.8:
* more docopt fixes

## v0.1.7:
* handle docopt exit for --version
* update to use newest docopt version

## v0.1.6:
* add better support for plan#stop
* fix bugs in volley plans
* remove dependencies and references to awesome_print

## v0.1.5:
* action#stop should delegate to plan#stop

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
* fix bug with argument handling, related to docopt changes
* documentation
* remove dependency on awesome_print and debug statements. fail me.
* more docopt fixes
* handle docopt exit for --version
* update to use newest docopt version
* working on getting 'auto' source working
* add better support for plan#stop
* fix bugs in volley plans
* remove dependencies and references to awesome_print
* action#stop should delegate to plan#stop
* fix problem with expand path throwing errors when HOME environment variable is not set
* fix problem with volley:meta when the meta file doesn't exist
* add -q --quiet option to CLI (bumps log level to warn)
* add volley:published plan, show all published artifacts (used by jenkins for selecting version to deploy)
* add version_data method to publisher, primarily to have access to modified time for sorting

## v0.1.10:
* fix bug with argument handling, related to docopt changes
* documentation
* remove dependency on awesome_print and debug statements. fail me.
* more docopt fixes
* handle docopt exit for --version
* update to use newest docopt version
* working on getting 'auto' source working
* add better support for plan#stop
* fix bugs in volley plans
* remove dependencies and references to awesome_print
* action#stop should delegate to plan#stop
* fix problem with expand path throwing errors when HOME environment variable is not set
* fix problem with volley:meta when the meta file doesn't exist
* add -q --quiet option to CLI (bumps log level to warn)
* add volley:published plan, show all published artifacts (used by jenkins for selecting version to deploy)
* add version_data method to publisher, primarily to have access to modified time for sorting
* add code to generate changelog
* attempting to publish a duplicate artifact shouldn't throw an error
* properly support force=true argument
* allow for stopping plan processing with plan#stop

## v0.1.1:
* add the ability to daemonize the process using Daemons gem.
* add Volley::Log#reset to forget previous log configuration in parent, before forking

