# Volley

`Volley` is a Publish/Subscribe deployment mechanism, with some additional functionality allowing
for scripting of builds. It depends on MCollective as the Publish/Subscribe mechanism.

## Installation

Volley requires Fog, which requires Nokogiri. Nokogiri requires ruby 1.9.3 and libxml2
(and possibly libxslt1). To get libxml2 set up, use the following command:

### MacOSX

    brew install libxml2

### Ubuntu

    sudo apt-get install libxml2-dev libxslt1-dev

now back to your regularly scheduled gem install.

### Gem installation

Add this line to your application's Gemfile:

    gem 'volley'

And then execute:

    bundle

Or install it yourself as:

    gem install volley

By default, volley stores it's data in /opt/volley, you'll need to create this directory and make sure it's world writable.

    sudo mkdir -p /opt/volley
    sudo chmod 777 /opt/volley

## Configuration

Generally, you will provide configuration in either a `/etc/Volleyfile` or `~/.Volleyfile`. It should be either/or, because
certain configurations (publisher) can only be specified once.

### Publisher

For testing, you can use a `Local` publisher:

    publisher :local,
      :directory => "/tmp/volley/remote"

This will allow you to use all of `Volley`'s functionality without requiring a cloud account.

Eventually, you will need to configure a cloud-based publisher, for S3, it would look like this:

    publisher :amazons3,
      :aws_access_key_id => "ACCESS_KEY",
      :aws_secret_access_key => "SECRET_KEY",
      :bucket => "my-bucket-name"

## Usage

Usage of `Volley` comes in primarily two parts: Publish and Deploy. Publishing generally involves creating an artifact
and pushing it to a remote location like S3. Deploying involves pulling the artifact from the remote location and running
code contained inside of it.

### Volleyfile

All of the intelligence required to build, publish and deploy a project should be contained in the project's `Volleyfile`
If you've used `Capistrano` or other similar gem's, this is similar.

A project's `Volleyfile` contains at least a single project with publish and deploy plans.

    project :myproject do
      plan :publish do
        action :build do
          # run a build command
        end
        push do
          # push is a special action.
          # the push action will automatically create a single artifact for you
          # the last statement of the push action should be a list of files that
          # you want included in the artifact.
        end
      end

      plan :deploy do
        pull do |dir|
          # pull is a special action
          # this action will be called once the artifact is downloaded and unpacked
          # on the remote server.
          # 'dir' is set to the directory containing the unpacked contents of the
          # artifact.
        end
      end
    end

The `Volleyfile` is organized such that:

* `Volleyfile`s contain projects
* Projects contain plans
* Plans contain actions (which are run in the order that they are specified)

### Project

A project is simply a container for a given projects related work. The `project` method requires a name argument,
either a symbol or string. Projects support a few configurations:

* `scm` - specify the source code management being used. currently supports `:git` and `:subversion`

### Plan

As in the above `Volleyfile`, plans are simply a block of code. The `plan` method of the project requires a name argument,
as a symbol or a string.

### Action

Actions contain simple blocks of work necessary to build your artifact. The simplest form of an action looks like:

    action :name do
        # work goes here
    end

As with projects and plans, names can be specified as strings or symbols.

There are a few specialized actions which have shortcut methods:

* `default` - generally used for simple plans, that contain only one action
* `push` - The push action is specialized in that it's return value is the list of
  files which will be packaged into the remote artifact. This action is the only
  way to push files to publisher.
* `pull` - The pull action is the only how `Volley` pulls artifacts from the publisher.
  The code block for the pull action should contain the work required to deploy the artifact on the remote server.
* `volley` - the volley action allows for dependencies between projects, one project can call another.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
