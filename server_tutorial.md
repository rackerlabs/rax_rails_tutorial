#Deploying A Ruby On Rails Application on the RackSpace Cloud

##Introduction
Deploying a Rails application can be an intimidating prospect for new developers. And, truth be told, there are a fair number of steps involved. But as with many difficult things, they don't seem so hard once you gain an understanding of the process. That is the aim of this tutorial - to demystify Rails deployment.

This tutorial will be beneficial to developers with a basic knowledge of Unix and Rails. If you can use `cd`, `ls`, and a few other basic commands and understand the basic layout of a Unix system, you are ready for this tutorial. We will assume you have enough Rails experience to make your own app in a development environment and are familiar with the standard tools - bundler and Git.

Our software stack will be as follows, although the principles learned will help you with other setups like Unicorn or Thin.

- [Ubuntu](http://www.ubuntu.com/)
- [Passenger](https://www.phusionpassenger.com/) with [Nginx](http://nginx.com/)
- [Ruby](http://www.ruby-lang.org/)
- [Rails](http://rubyonrails.org/)
- [MySQL](http://www.mysql.com/)

This setup is pretty straightforward. We will be going through the steps manually - actually typing the commands into the terminal. Once you have an understanding of how it all works, we recommend that you look into a configuration management tool such as [Chef](http://www.opscode.com/chef) or [Puppet](https://puppetlabs.com) to automate the process. It will come in handy, saving you time and preventing errors.

##Getting Started

###Our App
Before we get to setting up a server and deployment, we'll need an app. For this purpose, we're going to use an empty Rails application. It doesn't get any more basic.

First, on your development machine, create a Rails app (we'll use MySQL):

```
rails new demoapp -d mysql
```

Then we'll update our `.gitignore` file to include

```
/config/database.yml
```

since we don't want to check any passwords into Git, and we will be generating this file for production with Capistrano later.

Next, we'll check our code into Git:

```
git init
git add .
git commit -am "initial commit"
```

For this tutorial, we will be deploying our app from a local Git repository - the one on your laptop. Anther common configuration is to deploy from a GitHub repository. The process is very similar - check out the documentation on Github for information on how to get started if that is your need.

Finally, lets create the development database:

```
bundle exec rake db:create
```

And start it up!

```
bundle exec rails server
```

You should see the familiar empty Rails app at <http://localhost:3000>

![Rails Index](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Rails-Index.png)

This is all we are going to do before we get to deployment. We recommend deploying your app to a production (or staging) server as early in your development schedule as possible. Much of the time, that means right away.

##Creating and Securing Your Server

###Creating a Server
The first step is to create a new server in your Rackspace Cloud account. For this tutorial we will be creating a 512MB Ubuntu Linux version 12.04 LTS server. 512MB should be plenty to handle a Rails app with light traffic. Ubuntu is a common choice, although others will do as well. We recommend going with an LTS (Long Term Service) version unless you have a reason not to - having the support continued for a longer time period is a nice thing a year or two down the road.

Creating a server could not be much easier. Just log into your Rackspace account (note that the control panel works best in Firefox), click the Servers button at the top of the screen, and then click the Create Server button.

![Rails Index](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Rackspace-CP.png)

On the next screen type in a name (we'll use "DemoApp") and select an image to base the server on. We're using Ubuntu 12.04 LTS (Precise Pangolin). Finally, select a size (512MB) and click Create Server. You'll be presented a password. Write it down - you will need it in a moment. In a few minutes your server will be alive and well.

###Securing the Server
From here on out, we will show a prompt to differentiate which terminal you are using. For your development laptop, we'll use a `local>` prompt. For the production server, we will use the `server>` prompt.

###Generating Your SSH Keys
Except for our initial login to set things up, we won't be using passwords to connect to our sever. It is more secure and convenient to use SSH keys. But it requires a little setup. On your local machine:

```
local>cd
local>ssh-keygen -t rsa -C "you@example.com"

#Generating public/private rsa key pair.
#Enter file in which to save the key (/Users/you/.ssh/id_rsa):

local>[hit enter]

#Enter passphrase (empty for no passphrase):

local>[enter a passphrase]

#Enter same passphrase again:

local>[enter passphrase again]
```

At this point some files should be saved at `~/.ssh`, including the file `id_rsa.pub`, which is your public key.
 
###Logging into the Server
When your server is ready, log into it as root. On your laptop enter the command:

```
local>ssh root@xxx.xxx.xxx.xxx
```

where `xxx.xxx.xxx.xxx` is the ipV4 address listed for your server in the Rackspace control panel in the Networks section of your server's detail page. Use the IP address listed as PublicNet.

You may get a warning stating that "The authenticity of the host...can't be established". Type 'yes' and continue - you'll be prompted for a password. This is the one you wrote down earlier.

###Upgrading Packages
Now that you're logged into the server, we'll get on with some basic setup.

First, we'll update Ubuntu's packages. First run:

```
server>apt-get update
```

This command will update the server's information on the available packages to reflect the latest offerings. It takes a moment, and will spit out quite a bit of output. Next run

```
server>apt-get upgrade
```

which will upgrade the packages already on your server. This may take a few minutes, so sit back and wait for it to finish.

###Fail2Ban
Fail2Ban is a program that logs and attempts to block suspicious logins. It's trivial to install:

```
server>apt-get install fail2ban
```

For more information on Fail2Ban see the [documentation](https://help.ubuntu.com/community/Fail2ban).

###Creating a User and Setting Up SSH Keys
Now we'll create the user we use to deploy - we'll call it "deploy".

```
server>adduser deploy
```

You will be asked for some information. You can leave it blank (except for the password). This command will also create a home directory at `/home/deploy`.

Now we will create the `.ssh` directory for the deploy user:

```
server>mkdir /home/deploy/.ssh
server>chmod 700 /home/deploy/.ssh
```

Next we'll install your ssh keys so we don't have to fiddle about with passwords. Create a file at `/home/deploy/.ssh/authorized_keys`. You can use vim, emacs, or whatever you're comfortable with. We'll use nano, since it's beginner-friendly.

```
server>nano /home/deploy/.ssh/authorized_keys
```

Now cut and paste the contents of `~/.ssh/id_rsa.pub` from your local machine into the `authorized_keys` file that you just created. Be careful to copy the all of the text, and only the text - no spaces, new lines, or anything like that. Hit `Control-O` to save the file, and `Control-X` to quit. Next we'll set the permissions and ownerships for the user's keys and home directory.

```
server>chmod 400 /home/deploy/.ssh/authorized_keys
server>chown deploy:deploy /home/deploy -R
```

Next, we'll grant sudo privileges to the deploy user. Edit the file `/etc/sudoers` and look for the line:

```
root    ALL=(ALL) ALL
```

now add the following line below it:

```
deploy  ALL=(ALL) ALL
```

and save and quit nano (`Control-O`, `Control-X` for nano).

Now is a good time to make sure you can log in as deploy. First, restart ssh:

```
server>service ssh restart
```

In a new shell (leave the old one open) on your laptop, log in (again, with your server's IP address in place of `xxx.xxx.xxx.xxx`:

```
local>ssh deploy@xxx.xxx.xxx.xxx
```

You should be able to log in as deploy without entering a password. If you can't, double check your ssh keys and try again. It's easy to make a mistake there.

Finally, we want to prevent password logins and root logins. Back in the shell where we are logged in as root, open up the file at `/etc/ssh/sshd_config`.

```
server>nano /etc/ssh/sshd_config
```

Find the line that says `PermitRootLogin yes` and change it to 'no':

```
PermitRootLogin no
```

and directly below that line add another that prevents password authentication:

```
PasswordAuthentication no
```

Then save, quit and restart ssh:

```bash
server>service ssh restart
```

Now back on your laptop, try to log in as root. It should not let you. You should be able to login as deploy without a password.

###Additional Steps
We are at a point where the security basics have been covered. But there are a few more bells and whistles we can use. A firewall like ufw is a good idea. You can set it up to accept only traffic from ports 80 (http) and 443 (https), while only allowing traffic from your IP address on port 22 (ssh). For more information on ufw, see the Ubuntu [documentation](https://help.ubuntu.com/community/UFW). 

You can also install Logwatch, which is a program that will email you logs which can aid in figuring out what happened in the case where there is an unauthorized login attempt. See the Ubuntu [community docs](https://help.ubuntu.com/community/Logwatch) for more information.

So there we have it. While these steps will not guarantee the ultimate in server security, they are a good, solid base from which to start.

##Installing The Web Stack
Now that our sever is secured and our user accounts are set up, we can begin installing the software that we need to run our Ruby on Rails application. We will install Ruby and some required gems, Rails, Passenger with Nginx, and MySQL. That is all we need to get up and running.

Once all this is done, we will get back to our development machine and set up our Capistrano deployment recipe.

###Installing the Tools
Before we can install the good stuff, we need some Ubuntu packages. Quite a few, actually. Go ahead and install them. Log in as deploy and run this command:

```
server>sudo apt-get install curl git-core build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev libyaml-dev libcurl4-openssl-dev
```

This will take a minute or two.

###Installing Ruby and Rails
Rubyists can be a bit picky about the exact version of Ruby installed on their servers, and new versions can offer significant advantages. For that reason, we are going to forgo Ubuntu's packaged version of Ruby and install it from source. We'll be using Ruby 1.9.3-p385. Some developers prefer to run a ruby version manager like [rvm](https://rvm.io/) in production, but it is my preference that such tools are best for matching the development ruby version to whatever is on the server, not as an insallation convenience. It's just simpler to install ruby directly.

Create a directory called source in the deploy home directory. This is where we'll download our source code for things like Ruby. I'm sure there is a preferred place for doing this, but for our purposes it really doesn't matter and this is as good a place as any.

```
server>cd
server>mkdir source
server>cd source
```

Now, we'll download and install Ruby:

```
server>wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p385.tar.gz
server>tar -zxf ruby-1.9.3-p385.tar.gz
server>cd ruby-1.9.3-p385
server>./configure
server>make
server>sudo make install
```

Installing Ruby can take a while. Just let it do its thing. 

Next we'll install Rubygems. Again, we'll do this from source, as the Ubuntu package has proved unreliable in the past.

```
server>cd ~/source
server>wget http://production.cf.rubygems.org/rubygems/rubygems-2.0.3.tgz
server>tar -zxf rubygems-2.0.3.tgz
server>cd rubygems-2.0.3
server>sudo ruby setup.rb 
```

Since we won't need documentation on our server, we'll turn it off by default when installing gems. Create a file at `~/.gemrc` and add the following lines to it:

```
install: --no-ri --no-rdoc
update:  --no-ri --no-rdoc
```

Then, create `~/.bashrc` and add the following line:

```
export PATH=$PATH:/usr/local/lib/ruby/gems/1.9.1
```

We should now be able to install some gems we'll need:

```
server>sudo gem install bundler
server>sudo gem install rake
```

###Installing Passenger and Nginx
Passenger and Nginx are installed together, providing the web server for our Rails app. Fortunately, the team at Phusion has put a lot of effort into the installation process, and it's about as friendly as it can get.

First we'll install the passenger gem:

```
server>sudo gem install passenger
```

and then install Passenger/Nginx:

```
server>sudo passenger-install-nginx-module
```

Follow the on screen instructions, and choose option 1 ("Yes, download, compile, and install Nginx for me (recommended).") when prompted. For all other prompts, just choose the default. 

One thing that does not get installed is the init script for Nginx. This is the script that allows us to start and stop the Nginx server. Thankfully, Nginx provides one we can use. Create a file at `/etc/init.d/nginx` and copy the contents of the script found at <http://wiki.nginx.org/Nginx-init-ubuntu>. Then we'll update the permissions:

```
server>sudo chmod u=rwx /etc/init.d/nginx
server>sudo chmod go=rx /etc/init.d/nginx
```

There are a couple of edits we need to make to the init script. Look for the line near the top of the file that says:

```
DAEMON=/usr/local/sbin/nginx
```

We need to change that, because our Nginx configuration file was installed at `/opt/nginx`, not `/usr/local`. Go ahead and change that line as follows. You will need to use sudo to edit it:

```
DAEMON=/opt/nginx/sbin/nginx
```

Similarly, change

```
NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"
```

to:

```
NGINX_CONF_FILE="/opt/nginx/conf/nginx.conf"
```

and also change

```
PIDSPATH=/var/run
```

to:

```
PIDSPATH=/opt/nginx/logs
```

Now we can start and stop, and restart Nginx with the following commands:

```
server>sudo /etc/init.d/nginx start
server>sudo /etc/init.d/nginx stop
server>sudo /etc/init.d/nginx restart
```

We would also like Nginx to start automatically when you reboot the server. There is a handy utility that allows us to set this up easily. Install sysv-rc-conf:

```
server>sudo apt-get install sysv-rc-conf
```

and run it:

```
server>sudo sysv-rc-conf
```

In the GUI (if it can be called such), find the nginx line and check the boxes for columns 2, 3, 4, and 5. You can even use your mouse if so inclined. This will direct Nginx to start itself up when the server comes on line. 

For more information on what is going on here, do some research on Linux runlevels. It's a fairly complex topic that we won't get into here, but we recommend looking into it as it will come in handy at some point in the future.

In any case, we can now quit out of sysv-rc-conf by typing `q`.

###Installing MySQL
We will use the Ubuntu package for MySQL, since it works just fine. Install it:

```
server>sudo apt-get install mysql-server
```

You will be prompted to enter a password for the root MySQL user. Go ahead and do so. We will also need the following package to use the mysql2 gem, so let's install it now.

```
server>sudo apt-get install libmysqlclient15-dev
```

Now we will create a deploy user for MySQL and set its password. Log into MySQL as root:

```
server>mysql -u root -p
```

and enter your password when prompted. At the `mysql>` prompt, run the following command:

```mysql
GRANT ALL PRIVILEGES ON *.* TO 'deploy'@'localhost' IDENTIFIED BY 'secret' WITH GRANT OPTION;
```

This will create a MySQL user named deploy with the password 'secret'. Quit mysql by typing `quit` at the `mysql>` prompt.

We're now finished with our basic server configuration. Everything remaining will be specific to our application deployment.

##Capistrano - Making Deployment Easy
Deploying a Rails app is conceptually simple, you just copy the files in your app on to the server and tell the web server where to find them. In practice, things get a little more complicated than that and can quickly get out of hand if you do things manually. Thankfully, we have Capistrano to manage the process.

[Capistrano](https://github.com/capistrano/capistrano) is a Ruby gem similar to Rake. You use Capistrano to run tasks on a remote machine via ssh. To use it, you install it on your local machine and write ruby scripts called "recipes" that run a series of tasks - some built into Capistrano and some custom built for your application. Capistrano is very flexible. We're going to use it in as simple a way as possible - to copy the latest commit from our local git repository onto our server and restart the web server.

Let's get started.

###Capistrano is Local
Capistrano runs on your development laptop. You don't need it on the server. Because passwords are involved, we are going to keep our deploy script out of version control. It is possible to extract the passwords into their own file and check the rest of the script into source control. But it's a more advanced topic that we'll skip for now.

The first thing we need to do is install the Capistrano gem. Since we'll only need it in development, we'll put it in the development group of our Rails app's `Gemfile`.

```ruby
group :development do
  gem 'capistrano', "~> 2.14.2"
end
```

Don't forget to run `bundle install`.

Now that Capistrano is installed, we'll need to "Capify" our app. In the root directory of your app run:

```
local>bundle exec capify .
```

This command will add two files to your app. The first is `Capfile`, located in the app root directory. Capify is the main configuration for Capistrano. The other file, `config/deploy.rb` is your deploy script.

Although most of our work will be in the deploy script, there is one edit we need to make to the Capfile to make it play well with the Rails asset pipeline. Open up the Capfile and uncomment the following line.

```ruby
load 'deploy/assets'
```

Before we continue, add our the following line to `.gitignore` to keep our deploy script out of source control:

```
/config/deploy.rb
```

The default deploy script has some very helpful comments. Start by editing it to look like this:

```ruby
set :application, "demoapp"
set :repository, "path/to/demoapp/on/your/development/machine"
set :deploy_to, "/var/www/#{application}" #path to your app on the production server 

set :scm, :git

set :domain, 'example.com'
role :web, domain
role :app, domain
role :db,  domain, :primary => true

after "deploy:restart", "deploy:cleanup"

#Passenger
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
```

Before we continue, lets take a look at what we have. The first line sets the `application` variable to the string `'demoapp'`. (Use the `set` method to do this in Capistrano).

Similarly, we set the `repository` variable to the absolute path to your app on your development machine. We also set the `deploy_to` variable to the app's path on the production server. We'll put it in the `/var/www` directory. It doesn't exist yet, so lets log into the server as deploy and create it. We also have to make sure it is owned by the deploy user.

```
server>sudo mkdir /var/www
server>sudo chown deploy:deploy /var/www
```

Back in our deploy script, we set the `scm` variable to `'git'`, since that's what we are using.

The `domain` variable will be your domain (make sure there is an A record set up). Our web server, app server and db server are all the same, so we set those variables to `domain`.

The next line is a Capistrano callback. What it says is "after the `restart` task (in the `deploy` namespace) run the `cleanup` task (also in the `deploy` namespace). The `deploy:cleanup` task is built into Capistrano and it deletes old versions of your app on the server so they don't pile up. This will make more sense later when we get into how Capistrano works.

The final block defines three tasks and the `deploy` namespace - these are the tasks that start, stop and restart Passenger. Restarting Passenger (and therefore Nginx) is as simple as `touch`-ing a file in the `/tmp` directory called `restart.txt`.

###Capistrano's File Structure
Now that we have the beginning of a deploy script set up, lets take a break and talk about how Capistrano actually works under the hood. Capistrano doesn't just copy the app's files into the `deploy_to` directory. It's smarter than that.

Instead, a Capistrano deployment will have a file structure like this:

```
{deploy_to}/releases
{deploy_to}/releases/20130318013421
...several more like the one above...
{deploy_to}/shared
{deploy_to}/shared/log
{deploy_to}/shared/pids
{deploy_to}/shared/system
```

Capistrano copies the files to a directory (named with a timestamp) in the `releases` directory. Each new release adds a new timestamped version in a separate directory. Once the files are in place, Capistrano symlinks the newest release to `{deploy_to}/current`.

```
{deploy_to}/current => {deploy_to}/releases/20130318013421
```

So you'll find your rails app's `app` directory (for example) at `{deploy_to}/current/app`. 

Keeping old timestamped versions like this is a good idea if you ever need to roll back to an older version. Capistrano provides a built in task just for this - `deploy:rollback`.

But after a while, you can accumulate quite a few old releases, which we don't need. Remember that call to `deploy:cleanup` we had in our deploy script? It deletes old versions on the server, leaving only the most recent five, which should be plenty.

So what's up with the `shared` directory? Those are for files that are shared between releases - the log file is an example. You wouldn't want to overwrite it every time you deployed new code. Those files get symlinked into `/current` as well.

###Filling Out the Deployment Script
Back in `config/deploy.rb`, we'll need some more code before we can deploy. We'll need to specify the user on the production server that we will be using - we'll use the deploy user we created earlier. We also need to include that user's password for sudo access. However, we won't use sudo by default, so we set `use_sudo` to `false`. We will also need our MySQL user and password.

Add the following lines to config/deploy.rb:

```ruby
require 'bundler/capistrano'
set :application, "demoapp" 
set :repository,  "Users/damoncali/rackspace/#{application}"
set :deploy_to, "/var/www/#{application}" #path to your app on the production server 

set :scm, :git

set :user, "deploy" #this is the ubuntu user we created
set :password, "secret" #deploy's password
set :use_sudo, false

set :mysql_user, "deploy" #this is the mysql user we created
set :mysql_password, "secret"
...
```

We also need to require the `'bundler/capistrano'` library to the top of the file. This is necessary to make bundler play well with Capistrano.

We will be deploying from a Git branch, so it's useful to define a default for this - we like to use the master branch. Since we are deploying from a repository on our local development machine, we will specify `deploy_via` as `copy`. Finally, we don't to deploy our entire repository history, so we'll set `shallow_clone` to `1` (so that it pulls only the most recent version). Go ahead and make those changes to `config/deploy.rb`:

```ruby
...
set :application, "demoapp"
set :repository,  "Users/damoncali/rackspace/#{application}"
set :deploy_to, "/var/#{application}" #path to your app on the production server 

set :scm, :git
set :branch, "master"
set :deploy_via, :copy
set :shallow_clone, 1

set :user, "deploy"
set :password, "secret" #deploy's password
...
```

An alternative to this setup would be to deploy from a remote repository such as GitHub. If that is what you want to do, here are some [helpful tips](https://help.github.com/articles/deploying-with-capistrano).


Finally, at the top of the deploy script, add this line - it's required to make the password work:

```ruby
default_run_options[:pty] = true
```

###Adding Config Files
Remember how we opted to leave `database.yml` out of our git repository? Well, now it's time to make sure it gets deployed as well. We'll set up a task to create the file in the shared directory that Capistrano creates and symlink it into the releases directory.

At the bottom of `config/deploy.rb`, add the following:

```ruby
after "deploy:setup", "db_yml:create"
after "deploy:update_code", "db_yml:symlink"

namespace :db_yml do
  desc "Create database.yml in shared path" 
  task :create do
    config = {
              "production" => 
              {
                "adapter" => "mysql2",
                "socket" => "/var/run/mysqld/mysqld.sock",
                "username" => mysql_user,
                "password" => mysql_password,
                "database" => "#{application}_production"
              }
            }
    put config.to_yaml, "#{shared_path}/database.yml"
  end

  desc "Make symlink for database.yml" 
  task :symlink do
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml" 
  end
end
```

What we've done here is to create a `db_yaml` namespace that contains two tasks - `create` and `symlink`. The `create` task is run with a callback right after the `deploy:setup` task. We run `deploy:setup` to create the basic Capistrano directory structure for a new project. We only do this once. With tth callback, when we run `deploy:setup`, we are telling Capistrano to automatically run `db_yaml:create` afterwards. The `create` task creates a file by converting a hash to yaml, and placing it in the `shared` directory with the `put` method that Capistrano provides.

As for the symlink task, that needs to run every time we deploy code so that the newest release is aware of the shared `database.yml` file. So we use the `after` callback for `deploy:update_code` - which is another built in Capistrano task that updates the code, creating a new release directory.

Finally we are ready to deploy!

###Setting up for the First Deployment
Now that our deployment script is ready, we'll use one of the built in tasks to set up the basic Capistrano directory structure on the server. In your app's root directory, run

```
local>cap deploy:setup
```

and you should see output showing that the Capistrano directory structures were created. 

You will also see that `db_yml:create` was called, which created a `database.yml` file at `/var/demoapp/shared/database.yml`.

Now deploy the code.

```
local>cap deploy
```

Pay attention to the voluminous Capistrano output - it gives you a good feel for what it is doing behind the scenes and where to look if you have trouble.

Now log into the server as deploy again and create a database. It is possible to do this within Capistrano, but we only need to do it once, so it's easier to just log in to the server and use Rake.

```
server>cd /var/www/demoapp/current
server>RAILS_ENV=production bundle exec rake db:create db:migrate
```

###Final Nginx Config
Our code is now ready to run. We just need to configure Nginx to find it. Create a directory at `/opt/nginx/sites`. This is where we'll store our app specific Nginx configuration files.

```
server>sudo mkdir /opt/nginx/sites
```

Now create a file (you'll need sudo) in that directory called `demoapp` with the following content, substituting your domain (make sure your DNS is configured properly to use the 'www' subdomain:

```nginx
server {
  listen 80;
  server_name www.example.com;
  root /var/www/demoapp/current/public; # note that /current/public is required here.
  passenger_enabled on;
}
```

This tells Nginx to listen on port 80 for traffic coming to www.example.com and to use the app at `/var/www/demoapp` with Passenger. Note that you must use the `/public` directory as root, not the app's root directory. Also note that the `/current` directory created by Capistrano must also be specified. Now we need to include this file in the main Nginx config file. You'll find it at `/opt/nginx/conf/nginx.conf`. Open it (with sudo) and at the very bottom, right before the final closing curly brace add this line:

```nginx
include /opt/nginx/sites/*;
```

This just tells Nginx to include the contents of every file in `/opt/nginx/sites`. Each time you add a new app, you just add a new config file to `/opt/nginx/sites`.

Before we're finished editing that file, add one more line near the top. We need to tell Passenger how many application processes to use. The default is 6, which is a bit high for our small server. We'll use 2 instead. This is important. If you run too many processes, your server will slow to a crawl when you run out of memory.

```nginx
...
events {
    worker_connections  1024;
}


http {
    passenger_root /usr/local/lib/ruby/gems/1.9.1/gems/passenger-3.0.19;
    passenger_ruby /usr/local/bin/ruby;

    passenger_max_pool_size 2;

    include       mime.types;
    default_type  application/octet-stream;
...
```

When you're done, restart Nginx:

```
server>sudo /etc/init.d/nginx restart
```

##You're Done

From now on, new deployments are a snap. After you update your application code and check it into Git, just run

```
local>cap deploy
```

and Capistrano will automatically deploy your code, symlink the required files, clean up the old releases and restart Nginx.

##Wrap Up
So there we have it. We've created an empty Rails app, setup a production box on the Rackspace Cloud, secured the server, installed the Rails stack, set up Capistrano and deployed our app. That was a lot of work wasn't it?

Yes. But it's good work. Knowing the nuts and bolts of how your app is deployed will help you write better, more flexible apps that work exactly the way you want them to. But we've just scratched the surface here. 

Much of this work can be automated with Chef or Puppet, and we recommend that you do so.

Similarly, Capistrano is very powerful, and there are more sophisticated ways to set it up. You can extract your passwords into a config file so that you can check your deploy script into Git, for example. There is no reason not to keep your Nginx config file under source control and deploy it like we did the database.yml file, either. You can even use Capistrano to run commands on the server quickly and easily (suppose you are running background jobs and you need to restart a worker - you could write a `workers:restart` task). Use your imagination, and you can set up a very slick system. The more complex your app gets, the more helpful Capistrano can be.

We hope you have enjoyed this introduction to Rails hosting.
