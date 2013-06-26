#Building a Simple Server Management Application with Ruby On Rails

##Introduction

The Rackspace Cloud has a control panel that allows you to create new cloud servers, save cloud server images, and many other features related to managing your Rackspace cloud account. But did you know that you can build your own control panel with Rails? 

In this tutorial, we will walk you through the creation of a simple Rails application that will allow you to manage your servers. Our goal is to get you thinking about how you can help streamline your operations by building a custom dashboard.

This tutorial will show you how to write the Rails application. There is also a Depolyment Tutorial that will walk you through the steps required to deploy an application on a Rackspace Cloud server.

###Who is This Tutorial for?

This tutorial requires a basic understanding of Rails development. While this is an intermediate level app, if you’ve done an introductory tutorial or read one of the many introductory books on Rails, you should be able to follow along just fine. If you want to brush up on some of the required skills, here are some good resources:

**Ruby** - Why's Poignant Guide to Ruby - [http://mislav.uniqpath.com/poignant-guide/book/](http://mislav.uniqpath.com/poignant-guide/book/) 

**Ruby On Rails** - Official Ruby On Rails Guides - [http://guides.rubyonrails.org/](http://guides.rubyonrails.org/)

**Git** - GitHub's Code School - [http://try.github.com/](http://try.github.com/)

To keep this tutorial accessible by a wide range of developers, from beginners to experts, we have simplified our demonstration app down to its most basic form. You can think of this tutorial as the first batch of work in an agile development process.

###Requirements

Our application, which we will call Servely (*-ly* names are all the rage these days), will do only a few things:

- Retrieve a list of server images from your Rackspace Cloud account.
- Retrieve a list of cloud servers from your Rackspace Cloud account.
- Allow you to create a new cloud server from an image.
- Allow you to create a new image from an existing server.
- Allow you to delete a server.
- Allow you to delete an image.

(Yes, we can do this quite easily in the Rackspace Cloud control panel, but humor us - this is just the beginning of what is possible).

###Outline

- [Getting Started](https://github.com/rackerlabs/rax_rails_tutorial#getting-started-creating-the-base-rails-app)
- [The First Feature: Servers](https://github.com/rackerlabs/rax_rails_tutorial#the-first-feature-servers)
- [Where's The Database?](https://github.com/rackerlabs/rax_rails_tutorial#wheres-the-database)
- [The Server Model](https://github.com/rackerlabs/rax_rails_tutorial#the-server-model)
- [Finishing The Server UI: Creating and Deleting](https://github.com/rackerlabs/rax_rails_tutorial#finishing-the-server-ui-creating-and-deleting)
- [Images](https://github.com/rackerlabs/rax_rails_tutorial#images)
- [Wrap Up](https://github.com/rackerlabs/rax_rails_tutorial#wrap-up)

##Getting Started: Creating the Base Rails App

We are going to be using Ruby version 1.9.3-p385 and Rails version 3.2.13, both the latest versions as of the date of this writing. (Ruby 2.0 has just been released, and will probably work just fine for this tutorial, but we'll stick with 1.9.3 because 2.0 is *so* new.) You can download the latest version of Ruby at <http://rubylang.org>.

For a database, we will be using MySQL, which you should install on your development machine (we will be using it for both development and production).

Most Ruby developers I know use a ruby version management system. This allows us to match the version of Ruby that we are using in development to the version of Ruby that is currently deployed in production. When you have more than one project going, it’s a lifesaver to be able to change versions on a project by project basis.

There are two major options out there for this - either will work. rvm [https://rvm.io](https://rvm.io)/ was the first one to gain popularity, and also includes a gem management feature. I prefer rbenv (combined with the ruby-build plugin) [https://github.com/sstephenson/rbenv/](https://github.com/sstephenson/rbenv/). It’s a little simpler and stays out of the way. Which you choose is up to you, but do use one.

From here on out, I will assume you have a properly configured development environment in which to work. 

Experienced developers should feel to skim through this part of the tutorial - it covers the basics of setting up a basic Rails app.

###Creating the App

Now that we’re ready, step one is to create the empty Rails application for Serverly. We do that with the command:

```
rails new serverly -d mysql
```

We use the `-d` option to set up the new application to use MySQL instead of the default Sqlite. As we'll see in a moment, we don't actually use a database in our application. However, it will almost certainly be used in a real application, and it's easier just to go along with the defaults than it is to turn off this functionality in Rails.

Now that we have a base application created, we'll do a little more configuration before checking the source code into Git.

Since we're using rbenv, it's a good time to create a config file that tells rbenv which version of ruby to use by default so we don't have to. Simply create a file in the severly directory called `.rbev-version` and edit it to contain the following:

```
1.9.3-p385
```

Next we'll want to update our `.gitignore` file (which was created by Rails automatically). Open it up and add the following two lines to the bottom of the file:

```
/config/database.yml
.rbenv-version
```

The first line tells Git not to track the `databse.yml` config file in source control. While this is not strictly necessary since we won't be using this file for deployment, it's a good habit by default - never check passwords into source control. The second tells us git not to track the rbenv config file we just created since that is only relevant to our local development environment.

If you're using a Mac, you may also want to add `.DS_Store` files to your global `.gitignore_global` file. If you don't have one, run

```
git config --global core.excludesfile ~/.gitignore_global
```

Once you have a global ignore file, you can add

```
.DS_Store
```

to the file at `~/.gitignore_global`, which contains all of the files you want git to ignore in all of your projects.

Finally, it's time to check the project into git.

```
git init  
git add .
git commit -m "initial commit"
```

From here on out, I will not be including commits to git in order to keep from distracting from the main tutorial. However, it is recommended that you make commits often and that each of your commits has an easily described purpose which is detailed in a short message with the `-m` option.

Now that we've got our base application generated and checked into source control, lets run it to verify that everything is working.

First, we'll need to generate the development database. In the serverly directory, run

```
bundle exec rake db:create
```

That will create a MySQL database called `serverly_development`. Again, we will not be using this database during this tutorial - but we'll include it now because it's the easy thing to do, and it will be needed eventually if you continue to build this app out.

And finally, start the app with

```
bundle exec rails server
```

and open up <http://localhost:3000> in your browser of choice. You should be greeted with the default Rails index page.

![Rails Index](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Rails-Index.png)

Before we get started on the models and controllers, there are a couple more basic steps to take. First, let's create a helper for the error messages generated by validations. Create a file at `app/helpers/error_messages_helper.rb` with the following content:

```ruby
module ErrorMessagesHelper
    # Render error messages for the given objects. The :message and :header_message options are allowed.
  def error_messages_for(*objects)
    options = objects.extract_options! 
    options[:header_message] ||= "Invalid Fields"
    options[:message] ||= "Correct the following errors and try again."
    messages = objects.compact.map { |o| o.errors.full_messages}.flatten
    unless messages.empty?
      content_tag(:div, :class => "error_messages") do
        list_items = messages.map { |msg| content_tag(:li, msg) }
        content_tag(:h2, options[:header_message]) + content_tag(:p, options[:message]) + content_tag(:ul, list_items.join.html_safe)
      end
    end
  end

  module FormBuilderAdditions
    def error_messages(options = {})
      @template.error_messages_for(@object, options)
    end
  end
end

ActionView::Helpers::FormBuilder.send(:include, ErrorMessagesHelper::FormBuilderAdditions)
```

That way, we can call `<%= error_messages_for @some_model %>` in our views. Hat tip to Ryan Bates at [Railscasts](http://railscasts.com) for this code - it's a little cleaner than the helper that used to be included in Rails (before Rails 3).

The last bit of prep we're going to do is to add some CSS. To save some work, just create a file at `app/assets/stylesheets/serverly.scss` with the following content (note that we're using Sass in the Gemfile):

```scss
html, body {
  background-color: #ccc;
  font-family: Arial, sans-serif;
  font-size: 15px;
}

a {
  color: #0000FF;
  img { border: none;}
}

h2 {
  font-size:18px;
  margin:0;
}

p.detail {color: #666;}
.right {float:right;}

#container {
  width: 80%;
  margin: 0 auto;
  background-color: #FFF;
  padding: 20px 40px;
  border: solid 1px #999;
  margin-top: 20px;
  -moz-border-radius: 2px; -webkit-border-radius: 2px; border-radius: 2px;
  -webkit-box-shadow: 0 1px 1px rgba(0,0,0,0.2); 
  -moz-box-shadow: 0 1px 1px rgba(0,0,0,0.2); 
  box-shadow: 0 1px 1px rgba(0,0,0,0.2);
}

#navigation {
  text-align:right;
}

ul.servers, ul.images {
  list-style:none;
  margin:0;
  padding:0;
}

ul.servers li, ul.images li {
  display:block;
  padding:10px;
  margin:3px 0;
  border: 1px solid #ccc;
  -moz-border-radius: 4px;
  -webkit-border-radius: 4px;
  border-radius: 4px;
}

a.button {
  padding:8px 12px 6px 12px;
  height:12px;
  line-height:10px;
  font-size:16px;
  display:inline-block;
  text-decoration:none;
  text-align:center;
  -moz-border-radius: 4px;
  -webkit-border-radius: 4px;
  border-radius: 4px;
}

a.button.button-gray {
  color: #222;
  text-shadow: #ddd 0px 1px 1px;
  border:1px solid #aaa;
  background: -webkit-linear-gradient(top, #dfdfdf, #b9b9b9);
  background: -moz-linear-gradient(top, #dfdfdf, #b9b9b9);
  background-color: #b9b9b9;
}

a.button.button-gray:hover {
  background: -webkit-linear-gradient(top, #b9b9b9, #dfdfdf);
  background: -moz-linear-gradient(top, #b9b9b9, #dfdfdf);
  background-color: #dfdfdf;
}

a.button.button-red {
  color:#fff;
  text-shadow: #A80E1D 0px 1px 1px;
  border:1px solid #A80E1D;
  background: -webkit-linear-gradient(top, #fc7c6d, #e3111b);
  background: -moz-linear-gradient(top, #fc7c6d, \#e3111b);
  background-color: #e3111b;
}

a.button.button-red:hover {
  background: -webkit-linear-gradient(top, #e3111b, #fc7c6d);
  background: -moz-linear-gradient(top, #e3111b, #fc7c6d);
  background-color: #fc7c6d;
}

.flash-notice {
  color: #00B205;
}

.error_messages, #error_explanation {
  width: 400px;
  border: 2px solid #CF0000;
  padding: 8px;
  padding-bottom: 12px;
  margin-bottom: 20px;
  background-color: #f0f0f0;
  font-size: 12px;
  -moz-border-radius: 4px; -webkit-border-radius: 4px; border-radius: 4px;

  h2 {
    text-align: left;
    font-weight: bold;
    padding: 5px 10px;
    font-size: 13px;
    margin: 0;
    background-color: #c00;
    color: #fff;
  }
  p { margin: 8px 10px; }
  ul { margin-bottom: 0; }
}

.field_with_errors {
  display: inline;
}

form .field, form .actions {
  margin: 12px 0;
}

ul.errors li {
  color: #DD0000;
  margin-bottom: 8px;
}
```

##The First Feature: Servers

The first feature we want to create is to be able to list all of the servers contained in your Rackspace Cloud account. You will of course first need a Rackspace cccount. It's free to [sign up](https://cart.rackspace.com/cloud/).

In order for our app to access your account, we'll need to get the API credentials. You can find them in the Rackspace Cloud Control Panel.

We're going to store your credentials in a config file. Create a file at `config/app_config.yml` and add the following to it, substituting your credentials.

```yaml
development:
  rackspace_api_key: "longrandomstring"
  rackspace_username: "your_username"
```

**BEFORE** committing to Git, add the following line to the bottom of the `.gitignore` file:

```
config/app_config.yml
```

We don't want to check any sensitive credentials into source control.

We'll have to tell Rails about the `app_config.yml` file so that it knows where to find it and load it. In `config/application.rb`, add the following code just after the `if_defined?` block like this:

```ruby
if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

require 'yaml'

APP_CONFIG = YAML.load_file(File.expand_path "../app_config.yml", __FILE__)[Rails.env].symbolize_keys!

module Serverly
...
```

What we've done is to add a hash called `APP_CONFIG` that contains the contents of the `app_config.yml` file based on the current environment. If we need to access the api key, for example, we can get it with `APP_CONFIG[:rackspace_api_key]` anywhere in our application.

Now restart the server with `bundle exec rails server` and our we're ready to start work on the `Sever` model and controller.

##Where's the Database?

Since all the data about our servers is kept on Rackspace's servers, we don't need to store it in the database. Instead of `ActiveRecord` models, we'll be using database-less `ActiveModel` models. These models will behave similarly the regular rails models you're used to, but will retrieve their data from Rackspace via the API, which we will access with the [fog gem](http://fog.io).

First, add the fog gem to your `Gemfile`:

```
gem "fog", "~> 1.9.0"
```

then run `bundle install` and restart the server.

All of the models in our app will use some similar code, so we will opt to have them inherit from a base class. In the `app/models` directory, create a file called `cloud_model_base.rb`:

```ruby
class CloudModelBase
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # declare attributes in subclass with attr_accessor
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def self.compute
    @compute ||= Fog::Compute.new(
      :provider => 'Rackspace',
      :rackspace_api_key => APP_CONFIG[:rackspace_api_key],
      :version => :v2,
      :rackspace_username => APP_CONFIG[:rackspace_username])
  end
end
```

Lets take a look at this base class. First, notice that we are not inheriting from `ActiveRecord`. This is just a plain Ruby class. The first three lines of the class put some of the `ActiveModel` functionality that we're used to having into the class. We can validate this model, and use it elsewhere within rails without problem. Check out the `ActiveModel` documentation for more detail.

Since we don't have a database, we have to declare our attributes as Ruby attributes with `attr_accessor`, which we will do in the model subclass. This will create getters and setters for the attributes. In the initialize method, we assign the values to those instance variables. Nothing special here.

The `persisted?` method tells `ActiveModel` that we will not be using a database.

And finally, the `compute` class method is where we set up our connection with Rackspace using fog. The `@compute` object is the object we will use in the subclasses to access our Rackspace account. The version parameter specifies that we will be using Rackspace's next generation cloud servers (v1 is deprecated). Now lets create a `Server` subclass.

##The Server Model

Create a file in `app/models` called `server.rb`:

```ruby
class Server < CloudModelBase
  attr_accessor :name, :flavor_id, :image_id

  validates :name, :presence => true
  validates :flavor_id, :presence => true
  validates :image_id, :presence => true

  def self.all
    compute.servers
  end

  def self.find_by_id(id)
    compute.servers.get(id)
  end

  def self.create(params)
    compute.servers.create(:name => params[:name],
                           :flavor_id => params[:flavor_id],
                           :image_id => params[:image_id])
  end

  def self.delete(id)
    compute.servers.get(id).destroy
  end
end
```

Notice that this model class is inheriting from the base class we just created. We'll need three attributes for the `Server` model, all of which will be required to be present. We can call validates because we included the `ActiveModel::Validations` module in the base class.

The class methods are pretty simple, we are just using the `@compute` object to call the Rackspace API via the fog gem. For our app, we'll need to be able to pull a list of servers with the `all` method, a single server with the `find_by_id` method, and to create and destroy servers. Notice that we're calling methods on the `compute` object to do this and fog handles the details. Easy!

###Listing the Servers

Our first feature will be to retrieve and show a list of the available servers on our account. We'll need a controller and a view.

Create a file at `app/controllers/servers_controller.rb` with the contents:

```ruby
class ServersController < ApplicationController
  def index
    @servers = Server.all
  end
end
```

This is a straightforward Rails controller with a single action - `index`. Instead of calling `find` on and `ActiveRecord` model, we're calling `all` on our custom model. It's worth noting that the object returned is going to be a `Fog::Compute::Rackspace::Servers` object (note the plural `Servers`), which is a collection of `Fog::Compute::Rackspace::Server` objects - one for each server. For our purposes, you can treat this as an `Array` of `ActiveModel` objects - they have attributes that we can access in our views in the same way.

To access this action, we'll need to update `conifg/routes.rb`. Edit the file to look like this:

```ruby
Serverly::Application.routes.draw do
  resources :servers
end
```

Nothing magic here, just a standard Rails resourceful route. 

Lets try it. Create a veiw at `app/views/servers/index.html.erb` that contains this code:

```html+ruby
<h1>Server List</h1>

<%= link_to "Create Server", new_server_path, :class => "button button-gray" %>

<ul class="servers">
  <%= render :partial => 'server', :collection => @servers %>
</ul>
```

along with a partial at `app/views/servers/_server.html.erb`:

```html+ruby
<li>
  <%= link_to "delete", server_path(server.id), :method => :delete, :confirm => "Are you sure you want to delete this server?", :class => "button button-red right"%>
  <h2><%= server.name %></h2>
  <p class="detail">
    Flavor: <%= Flavor.find_by_id(server.flavor_id).name %> | State: <%= server.state %>
  </p>
</li>
```

There is nothing fancy here either - we're just iterating through the `Server` objects and displaying their attributes. Sharp-eyed readers will wonder about the `Flavor` class. Don't worry - we'll get to that soon.

Now is a good time to update our `app/views/layouts/application.html.erb` view. Edit it to look like this:

```html+ruby
<!DOCTYPE html>

<html>

<head>
  <title>Serverly</title>
  <%= stylesheet_link_tag    "application", :media => "all" %>
  <%= javascript_include_tag "application" %>
  <%= csrf_meta_tags %>
</head>

<body>

  <div id="container">
    <div id="navigation">
      <%= link_to "Server List", servers_path, :class => "button button-gray" %>
  </div>
  <% flash.each do |key,value| %>
    <p class="flash-<%= key %>"> <%= value %></p>
  <% end %>
  <%= yield %>
  </div>

</body>

</html>
```

In the container `div` we've added a navigation menu (with only one link so far) and an area to display flash messages.

Navigate your browser to <http://localhost:3000/servers> and you should see something like this:

![Server Index](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Server-Index.png)

The Create Server link wont work because we haven't created the `create` action yet, but we'll take care of that soon. Likewise, our reference to the  yet-to-be-created Flavor model is not getting called because we don't have any servers yet.

##Finishing The Server UI: Creating and Deleting

Now that we have the ability to list our servers, lets add some functionality that will let us create and destroy them. First, we'll deal with the `create` action.

To create a server, we need to select a "flavor" for that server. A flavor is basically the size and configuration of the server, and is identified by a name and ID. For example, there is a flavor called "512 server" that corresponds to a 512MB server offering on Rackspace.

We also need a image from which to create the server. Images are saved snapshots of working servers on disk. Rackspace has several images available by default (for example, an Ubuntu 10.04 LTS image, from which you can create your own server. You can also save your own custom images. We'll get to that when we're through with the servers.

###Adding the Controller Actions

To create a server, we need the customary RESTful actions, `new` and `create`. Go ahead and add them to `app/controllers/servers_controller.rb`:

```ruby
  def new
    @server = Server.new
  end

  def create
    @server = Server.new(params[:server])
    if @server.valid?
      server = Server.create(params[:server])
      flash[:notice] = "Server created"
      redirect_to servers_path
    else
      render :action => :new
    end
  end
```

These look just like regular Rails controller actions with a couple minor differences. First, notice that in the `create` action, we do not check to see if the record has been saved because we are not using a database. Instead we check to see if the object is valid with the line `if @server.valid?`.

Also note that the `Server.create` method calls the `create` method in our custom `Server` model, not the `ActiveRecord` method you're familiar with. 

Otherwise, this should be familiar stuff.

Next, we'll need a view for the server form. Create it at `app/views/servers/new.html.erb`:

```html+ruby
<%= error_messages_for @server %>

<%= form_for @server do |f| %>
  <div>
    <%= f.label :name %><br>
    <%= f.text_field :name %>
  </div>

  <div>
    <%= f.label :flavor_id, "Flavor" %><br>
    <%= f.select :flavor_id, object_options_for_select(:flavor) %>
  </div>

  <div>
    <%= f.label :image_id, "Image" %><br>
    <%= f.select :image_id, object_options_for_select(:image) %>
  </div>
  <div>
    <%= f.submit "Create Server" %>
  </div>

<% end %>
```

Again, this looks like standard stuff, and it is thanks to the `ActiveModel` modules we included in our Server model. But what is that `object_options_for_select()` helper?

As we said, we'll need to select a valid image and flavor to create our server. Where do we get those? From the Rackspace API via fog, of course. We present these options in a form to the user in a select box. But getting those options into the select options is a little verbose, so we put it in a helper.

Add the following method to `app/helpers/application_helper.rb`:

```ruby
def object_options_for_select(object)
  objects = object.to_s.capitalize.constantize.all
  objects_array = objects.map { |object| [object.name, object.id] }
  options_for_select(objects_array)
end
```

This method might be a little obtuse, so lets take a closer look. It expects a parameter,`object`, to be passed in the form of a symbol. That symbol will be the name of a class. For example, if we want to get the flavor options, we'll pass in `:flavor`. Never mind that there is no `Flavor` class - we'll make it in a moment.

The first line takes that symbol - `:flavor`, turns it into a string - `'flavor'`, capitalizes it - `'Flavor'`, and finally turns it into a constant - `Flavor` on which we can call the `all` method.

The next line creates an array of the returned objects' attributes in the form that is needed by the standard Rails method `options_for_select`.

Back in our view, we called this method for both the image select box, and the flavor select box, so we'll need models for each that have the class method `all`. Lets create them. They will look very familiar since they follow the same pattern as our `Server` model.

Create `app/models/flavor.rb` and add this code:

```ruby
class Flavor < CloudModelBase

  def self.find_by_id(id)
    compute.flavors.get(id)
  end

  def self.all
    compute.flavors
  end

end
```

There is no need for a `create` or `delete` method for flavors, since only Rackspace needs to do that.

Similarly, create a file at `app/models/image.rb` containing:

```ruby
class Image < CloudModelBase

  attr_accessor :name,
                :server_id

  validates :name, :presence => true
  validates :server_id, :presence => true


  def self.find_by_id(id)
    compute.images.get(id)
  end

  def self.all
    compute.images
  end

  def self.snapshots
    images = Image.all.partition {|img| img.metadata["image_type"] == "snapshot" }.first
    images.each {|img| img.reload }
  end

  def self.create(params)
    server = Server.find_by_id(params[:server_id])
    image = server.create_image params[:name]
  end

  def self.delete(id)
    compute.images.get(id).destroy
  end

end
```

The `Image` class closely parallels our `Server` model. There is one method that requies a little explanation, however. The `snapshots` method returns only the images that you have created. It leaves out the ones created by Rackspace. Each image has a hash called `metadata` that includes an `'image_type'` key that will be either `'base'` (Rackspace images) or `'snapshot'` (user-created images). The `'all'` class method will return all the images. So we just `partition` out the snapshots.

We also have to `reload` the images. This is a quirk of fog and the OpenStack system. When you first request an image, you get a version with only some of the attributes. When you reload the image, all of the attributes will be present. This may change in the future, but that's the state of things now.

Unfortunately, because each `image_type` check will be a separate API call, this method will be a little slow as written. 

Now that we have a way to access the images and flavors in our Rackspace account, we should be able to create a new server. Try it. Go to <http://localhost:3000/servers>, click the "Create Server" button and add a new server.

![Server New](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Server-New.png)

When you click the "Create Server" button on the new server form, you will actually create a new server on your Rackspace Account, and be redirected to your server list.

![Server Created](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Server-Created.png)

Destroying servers is much easier. We've already added the links to do that. We just need to add a `destroy` action to the Servers controller:

```ruby
  def destroy
    @server = Server.find_by_id(params[:id])
    Server.delete(@server.id)
    flash[:notice] = "Server destroyed"
    redirect_to servers_path
  end
```

Try it. Your server should be deleted from your Rackspace account.

Now we're finished with servers. One last task is to clean up the home page. We'll use our `servers#index` page as the homepage instead of the default rails page. Go ahead and delete `public/index.html` and `app/assets/images/rails.png`. Then add a route to `config/routes.rb`:

```ruby
Serverly::Application.routes.draw do
  resources :servers
  root :to => 'servers#index'
end
```

Now navigating to <http://localhost:3000> will show our server list page.

##Images
Severly now has the ability to list our servers, create them from available flavors and images, and delete them. Flavors are fixed by Rackspace, but we can create images ourselves. Lets build an interface for Images that is similar to the one we have for Servers.

We will be able to list our Images, create them from servers, and delete them. The process of adding this feature will be familiar, as it follows the same pattern as the servers. And since we've already created the models, it will be a snap to create the UI.

###Listing the Images
If we're going to have views dealing with the Image model, we'll need an Images controller. Go ahead and create one at `app/controllers/images_controller.rb`:

```ruby
class ImagesController < ApplicationController

  def index
    @images = Image.snapshots
  end

  def new
    @image = Image.new
  end

  def create
    @image = Image.new(params[:image])
    if @image.valid?
      image = Image.create(params[:image])
      flash[:notice] = "Image created"
      redirect_to images_path
    else
      render :action => :new
    end
  end

  def destroy
    @image = Image.find_by_id(params[:id])
    Image.delete(@image.id)
    flash[:notice] = "Image destroyed"
    redirect_to images_path
  end

end
```

See some parallels with the Servers controller? You should, because it follows the same pattern. 

The index page is also similar in structure to the Servers index page. Create a new view at app/views/images/index.html.erb:

```html+ruby
<h1>Image List</h1>
<%= link_to "Create Image", new_image_path, :class => "button button-gray" %>
<ul class="images">
  <%= render :partial => 'image', :collection => @images %>
</ul>
```

You'll also need to create a partial at app/views/images/_image.html.erb:

```html+ruby
<li>
<%= link_to "destroy", image_path(image.id), :method => :delete, :confirm => "Are you sure you want to destroy this image?", :class => 'button button-red right' if image.metadata["image_type"] == "snapshot" %>
<h2><%= image.name %></h2>
<p class="detail">
  Created at: <%= image.created %> | 
  State: <%= image.state %>
</p>
</li>
```
In this partial, we deviate from the server pattern slightly. We included a check on the "Destroy" button to see if the image is a snapshot or a base image, since you cannot destroy base images. This check is slow (again, it's one API call per image), and you can leave it out if you're using `Image.snapshots` in the controller like we are. However, if you want to see all of the images (by using `Image.all in the controller), the check is necessary. Unfortunately, one way or another, we need to check every image's `metadata[image_type'] one at a time. This may change in future versions of fog (which is always accepting contributions, hint, hint!)

Our Image index is ready, but before we check it out, lets update the navigation in our layout. Add a link to the image list in the navigation `div` in  `app/views/layouts/applciation.html.erb`:

```html+ruby
...
<div id="container">
  <div id="navigation">
    <%= link_to "Server List", servers_path, :class => "button button-gray" %>
    <%= link_to "Image List", images_path, :class => "button button-gray" %>
  </div>
  <% flash.each do |key,value| %>
...
```

Finally, update the `config/routes.rb` file:

```ruby
Serverly::Application.routes.draw do
  resources :servers
  resources :images
  root :to => 'servers#index'
end
```

Now fire up the browser and point it at http://localhost:3000/images and you should see something like this:

![Image Index](https://github.com/rackerlabs/rax_rails_tutorial/raw/master/doc/Image-Index.png)

There are no images to display yet - let's fix that.

###Creating Images
Create a view for the new image form at `apps/views/images/new.html.erb`:

```html+ruby
<%= error_messages_for @image %>

<%= form_for @image do |f| %>
  <div>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  </div>

  <div>
  <%= f.label :server_id, "Server" %><br>
  <%= f.select :server_id, object_options_for_select(:server) %>
  </div>

  <div>
    <%= f.submit "Create Image" %>
  </div>
<% end %>
```

The required inputs to create an image are the name you want to give it and the id of the source server. Again, we use the `object_options_for_select()` helper to retrieve a list of available servers directly from Rackspace.

And that's it. We now have a simple app that can create and manage servers and images on your Rackspace account. You should be able to create servers from any available image (Rackspace's or yours), and you should be able to create an image from any of your servers.

##Wrap Up

Obviously, our simple Serverly app does nothing that you can't do better in the actual Rackspace control panel. But that's not why we wrote this up. What we wanted to accomplish is to show you how easy it is to interact with the Rackspace API via the fog gem, and get you thinking about creative ways to manage your own cloud resources in your own custom control panel. 

We intentionally left out authorization and authentication, which you will obviously want in a real application. And we left out some error handling to keep our code simple. For example, try to delete an image you've just created that is not yet in an `ACTIVE` state. You'll get an exception. Thankfully, the responses generally give some clear error messages. We'll leave it as an exercise to the reader to implement the handling of those errors in the manner you see fit.

For some information on the fog errors, see the code on Github: [https://github.com/fog/fog/blob/master/lib/fog/rackspace.rb](https://github.com/fog/fog/blob/master/lib/fog/rackspace.rb) 

The Rackspace team works closely with the fog community - take advantage of that support and the high quality of the fog gem. 

###Expansion Ideas
This tutorial is pretty crude. We tried to keep it interesting by introducing some intermediate concepts, but we also needed to keep it digetable. Hopefully we've accomplished that.

We've explored a very simple way of accesing Rackspace via a databaseless model and seen some of the drawbacks of that approach - it can be slow. On the other hand, we did not have to worry about synching data between our own database and Rackspace. Adding a database to track things like the image_type of the images would greatly speed things up, and allow you to track data outside of that provided by the Rackspace system.

Our CloudModelBase architecture is also not very 'Railsy'. Why not mimic the ActiveRecord syntax? We considered doing so for this tutorial, and would in a production app, but it does add a little more code and complexity. Give it a try.

Create a custom status page for your servers. Or create a custom control panel that has more functionality than the official one. Your imagination is the limit. Make something cool.

##Don't Forget!

If you're working through this tutorial on your own, don't forget to delete your test servers so you don't get charged. Better yet, investigate the mocks built into fog so you can test your code without actually creating and destroying servers - get started here: <https://github.com/fog/fog/blob/master/lib/fog/rackspace/docs/getting_started.md>