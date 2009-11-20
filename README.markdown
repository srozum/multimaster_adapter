multimaster_adapter - sergey DOT rozum AT gmail DOT com
====

This simple plugin acts as a common ActiveRecord adapter and allows you to
setup a multi master environment using any database you like (and is supported
by ActiveRecord).

This plugin works by handling two or more connections to databases which are all
masters. It also tries to check health of primary master and use another one if 
primary is down.

To use this adapter you just have to install the plugin:

	ruby script/plugin install git://github.com/mauricio/multimaster_adapter.git

And then configure it at your database.yml file:

	development:
	  database: sample_development
	  username: root
	  adapter: multimaster              # the adapter must be set to "multimaster"
	  host:
	   - 10.21.34.80
	   - 10.21.34.81
	  multimaster_adapter: mysql        # here's where you'll place the real database adapter name


I keep getting 'unknown adapter' exceptions when I run any of the scripts
====

If you see something like:

  /usr/lib/ruby/gems/1.8/gems/activerecord-1.15.6/lib/active_record/
  connection_adapters/abstract/connection_specification.rb:79:in
  `establish_connection': database configuration specifies nonexistent
  multimaster adapter (ActiveRecord::AdapterNotFound)

You need to require 'multimaster_adpater' *before* or *in* the +Rails::Initializer.run+
section of the config/environment.rb file of your project.
