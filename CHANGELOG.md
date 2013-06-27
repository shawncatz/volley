# Changelog

## v0.1.25:
* add support override version number from within action. update fog dependency to resolve issue with possible API change

## v0.1.24:
* add support for changing user with Volley::Dsl::VolleyFile#user method.
* add custom Yell adapter for Volley to set group permissions on log files, to finally get rid of perm errors with multiple users running volley on same system

## v0.1.23:
* fixes issues with project, branch and version deletion and cleans up some of the reserved plans

## v0.1.22:
* add support for deleting branches and versions
* ruby version file

## v0.1.21:
* use common regex for descriptor checks and processing

## v0.1.20:
* better support for publisher#release and volley:released plan. should now be able to see which version a release is from

## v0.1.19:
* gemspec had hardcoded tag
* add release functionality to publishers
* remove puts call

## v0.1.18:
* 'volley:exists' plan to check for artifact in publisher

## v0.1.17:
* fix problem with passing arguments through volley action
* unable to get version is not a fatal error in most cases
* tweak logic to make it easier to understand (and match earlier logic)
* fix typo
* fix for determining latest version: if source isn't configured, will fall back to trying publisher.
* Revert "only use source to determine version when publishing"

## v0.1.16:
* only use source to determine version when publishing

## v0.1.15:
* missed in previous descriptor change. Tests now check valid? and parsing

## v0.1.14:
* update descriptor to support project@branch:5005-1

## v0.1.13:
* exit with errors for unknown exceptions

## v0.1.12:
* awesome_print dependency, since I keep using it and leaving it in

## v0.1.11:
* remove debug message
* fix depcrated config for Yell
* merge problem
* more docopt fixes
* handle docopt exit for --version
* update to use newest docopt version

## v0.1.10:
* fix bug with argument handling, related to docopt changes
* documentation

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
* add code to generate changelog
* attempting to publish a duplicate artifact shouldn't throw an error
* properly support force=true argument
* allow for stopping plan processing with plan#stop

## v0.1.1:
* add the ability to daemonize the process using Daemons gem.
* add Volley::Log#reset to forget previous log configuration in parent, before forking

