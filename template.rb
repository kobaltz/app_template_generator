class AppBuilder < Rails::AppBuilder
	include Thor::Actions
	include Thor::Shell

	def gemfile
		super
		@generator.gem "twitter-bootstrap-rails", group: [:assets]
		@generator.gem "sorcery"
		@generator.gem "bcrypt-ruby", :require => "bcrypt"
		@generator.gem 'therubyracer', :platforms => :ruby
		@generator.gem 'less-rails'
		@generator.gem "cancan", :git => "git://github.com/ryanb/cancan.git", :branch => "2.0"
		@generator.gem 'simple_form'
		run_bundle

    end

	def leftovers

		database_path = "config/database.yml"
		remove_file(database_path) 

		name = ask("What was the name of your app again?").underscore
		development_password = ask("What is the development password").underscore
		production_password = ask("What is the production password").underscore
		production_server = ask("What is the production server").underscore

		create_file database_path,  <<-RUBY
development:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: #{name}_development
  pool: 5
  username: root
  password: #{development_password}
  socket: /var/run/mysqld/mysqld.sock

production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: #{name}_production
  pool: 100
  username: root
  password: #{production_password}
  socket: /var/run/mysqld/mysqld.sock
  host: #{production_server}
		RUBY

		rake "db:create:all"
		rake "db:migrate"

		generate 'cancan:ability'
		generate('sorcery:install','remember_me reset_password')
		generate 'bootstrap:install'
		generate "simple_form:install --bootstrap"

		generate('controller','welcome index')
		route "root to: 'welcome#index'"

		generate("mailer","UserMailer reset_password_email")

		@generator.remove_file "public/index.html"

		generate("controller","PasswordResets create edit update")

		create_file "app/controllers/password_resets_controller.rb",  <<-RUBY
class PasswordResetsController < ApplicationController
  skip_before_filter :require_login
    
  # request password reset.
  # you get here when the user entered his email in the reset password form and submitted it.
  def create 
    @user = User.find_by_email(params[:email])
        
    # This line sends an email to the user with instructions on how to reset their password (a url with a random token)
    @user.deliver_reset_password_instructions! if @user
        
    # Tell the user instructions have been sent whether or not email was found.
    # This is to not leak information to attackers about which emails exist in the system.
    redirect_to(root_path, :notice => 'Instructions have been sent to your email.')
  end
    
  # This is the reset password form.
  def edit
    @user = User.load_from_reset_password_token(params[:id])
    @token = params[:id]
    not_authenticated unless @user
  end
      
  # This action fires when the user has sent the reset password form.
  def update
    @token = params[:token]
    @user = User.load_from_reset_password_token(params[:token])
    not_authenticated unless @user
    # the next line makes the password confirmation validation work
    @user.password_confirmation = params[:user][:password_confirmation]
    # the next line clears the temporary token and updates the password
    if @user.change_password!(params[:user][:password])
      redirect_to(root_path, :notice => 'Password was successfully updated.')
    else
      render :action => "edit"
    end
  end
end
		RUBY

		create_file "app/views/user_mailer/reset_password_email.text.erb",  <<-RUBY
Hello, <%= @user.email %>
===============================================
 
You have requested to reset your password.
To choose a new password, just follow this link: <%= @url %>.
 
Have a great day!
		RUBY

		create_file "app/mailers/user_mailer.rb",  <<-RUBY
class UserMailer < ActionMailer::Base
  default from: "noreply@example.com"
  #
  # FIX YOUR USER.RESET_PASSWORD_TOKEN URL TO LOOK LIKE 
  # {user.reset_password_token} and no spaces in the URL
  #
  def reset_password_email(user)
    @user = user
    @url  = "http://0.0.0.0/password_resets/ # { user . reset_password _ token }/edit"
    mail(:to => user.email,
         :subject => "Your password has been reset")
  end
end
		RUBY


		create_file "app/views/password_resets/edit.html.erb",  <<-RUBY
<h1>Choose a new password</h1>
<%= form_for @user, :url => password_reset_path(@user), :html => {:method => :put} do |f| %>
  <% if @user.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(@user.errors.count, "error") %> prohibited this user from being saved:</h2>
    
      <ul>
      <% @user.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
      </ul>
    </div>
  <% end %>
    
  <div class="field">
    <%= f.label :email %><br />
    <%= @user.email %>
  </div>
  <div class="field">
    <%= f.label :password %><br />
    <%= f.password_field :password %>
  </div>
  <div class="field">
    <%= f.label :password_confirmation %><br />
    <%= f.password_field :password_confirmation %>
    <%= hidden_field_tag :token, @token %>
  </div>
  <div class="actions">
    <%= f.submit %>
  </div>
<% end %>
		RUBY

		create_file "app/views/password_resets/new.html.erb",  <<-RUBY
<%= form_tag password_resets_path, :method => :post do %>
  <div class="field">
    <%= label_tag :email %><br />
    <%= text_field_tag :email %> <%= submit_tag "Reset my password!" %>
  </div>
<% end %>
		RUBY

		create_file "app/views/layouts/application.html.erb",  <<-RUBY
<!DOCTYPE html>
<html>
<head>
  <title>BOOTSTRAP APPLICATION</title>
  <!--[if lt IE 9]>
    <script src="https://html5shim.googlecode.com/svn/trunk/html5.js" type="text/javascript"></script>
  <![endif]-->
  <%= stylesheet_link_tag    "application", :media => "all" %>
  <%= javascript_include_tag "application" %>
  <%= csrf_meta_tags %>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <div class="navbar navbar-fixed-top">
    <div class="navbar-inner">
      <div class="container">
        <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </a>
        <a class="brand" href="/">BOOTSTRAP APPLICATION</a>
        <div class="nav-collapse">
          <ul class="nav">
            <li><%= link_to "Link_1" %></li>
            <li><%= link_to "Link_2" %></li>
            <li><%= link_to "Link_3" %></li>
			<% if current_user %>
			  <li><%= link_to "Log out", logout_path %></li>
			<% else %>
			  <li><%= link_to "Sign up", signup_path %></li>
			  <li><%= link_to "log in", login_path %></li>
			<% end %>
          </ul>
        </div>
      </div>
    </div>
  </div>

  <div class="container">
    <% flash.each do |name, msg| %>
      <div class="alert alert-<%= name == :notice ? "success" : "error" %>">
        <a class="close" data-dismiss="alert">×</a>
        <%= msg %>
      </div>
    <% end %>
    
    <div class="row">
      <div class="span12"><%= yield %></div>
    </div>
  </div>
</body>
</html>
		RUBY

		create_file "app/assets/stylesheets/bootstrap_and_overrides.css.less",  <<-RUBY
@import "twitter/bootstrap/bootstrap";
body { padding-top: 60px; }
@import "twitter/bootstrap/responsive";

// Set the correct sprite paths
@iconSpritePath: asset-path("twitter/bootstrap/glyphicons-halflings");
@iconWhiteSpritePath: asset-path("twitter/bootstrap/glyphicons-halflings-white");

// Set the Font Awesome (Font Awesome is default. You can disable by commenting below lines)
// Note: If you use asset_path() here, your compiled bootstrap_and_overrides.css will not
//       have the proper paths. So for now we use the absolute path.
@fontAwesomeEotPath: asset-path("fontawesome-webfont.eot");
@fontAwesomeEotPath_iefix: asset-path("fontawesome-webfont.eot#iefix");
@fontAwesomeWoffPath: asset-path("fontawesome-webfont.woff");
@fontAwesomeTtfPath: asset-path("fontawesome-webfont.ttf");
@fontAwesomeSvgPath: asset-path("fontawesome-webfont.svg");

// Font Awesome
@import "fontawesome";

// Glyphicons
//@import "twitter/bootstrap/sprites.less";

// Your custom LESS stylesheets goes here
//
// Since bootstrap was imported above you have access to its mixins which
// you may use and inherit here
//
// If you'd like to override bootstrap's own variables, you can do so here as well
// See http://twitter.github.com/bootstrap/customize.html#variables for their names and documentation
//
// Example:
// @linkColor: #ff0000;

.pagination {
  background: white;
  cursor: default;
  height: 22px;
  a, span, em {
    padding: 0.2em 0.5em;
    display: block;
    float: left;
    margin-right: 1px;
  }
  .disabled {
    display: none;
  }
  .current {
    font-style: normal;
    font-weight: bold;
    background: #2e6ab1;
    color: white;
    border: 1px solid #2e6ab1;
  }
  a {
    text-decoration: none;
    color: #105cb6;
    border: 1px solid #9aafe5;
    &:hover, &:focus {
      color: #000033;
      border-color: #000033;
    }
  }
  .page_info {
    background: #2e6ab1;
    color: white;
    padding: 0.4em 0.6em;
    width: 22em;
    margin-bottom: 0.3em;
    text-align: center;
    b {
      color: #000033;
      background: #2e6ab1 + 60;
      padding: 0.1em 0.25em;
    }
  }
}
		RUBY

		create_file "config/initializers/sorcery.rb",  <<-RUBY
Rails.application.config.sorcery.submodules = [:remember_me, :reset_password]
Rails.application.config.sorcery.configure do |config|
  config.user_config do |user|
    user.username_attribute_names = :username
    user.reset_password_mailer = UserMailer
  end
  config.user_class = "User"
end
		RUBY
		create_file "app/models/user.rb",  <<-RUBY
class User < ActiveRecord::Base
  authenticates_with_sorcery!
  
  attr_accessible :email, :username, :password, :password_confirmation

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :username
  validates_presence_of :email
  validates_uniqueness_of :username
  validates_uniqueness_of :email
end
		RUBY

		create_file "app/controllers/users_controller.rb",  <<-RUBY
class UsersController < ApplicationController
	load_and_authorize_resource
	enable_authorization
	def new
	  @user = User.new
	end

	def create
	  @user = User.new(params[:user])
	  if @user.save
	    redirect_to root_url, :notice => "Signed up!"
	  else
	    render :new
	  end
	end
end
		RUBY

		create_file "app/views/users/new.html.erb",  <<-RUBY
<%= form_for @user do |f| %>
  <% if @user.errors.any? %>
    <div class="error_messages">
      <h2>Form is invalid</h2>
      <ul>
        <% for message in @user.errors.full_messages %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>
  <div class="field">
    <%= f.label :username %>
    <%= f.text_field :username %>
  </div>
  <div class="field">
    <%= f.label :email %>
    <%= f.text_field :email %>
  </div>
  <div class="field">
    <%= f.label :password %>
    <%= f.password_field :password %>
  </div>
  <div class="field">
    <%= f.label :password_confirmation %>
    <%= f.password_field :password_confirmation %>
  </div>
  <div class="actions"><%= f.submit %></div>
<% end %>
		RUBY

		create_file "app/controllers/sessions_controller.rb",  <<-RUBY
class SessionsController < ApplicationController
	def create
	  user = login(params[:email], params[:password], params[:remember_me])
	  if user
	    redirect_back_or_to root_url, :notice => "Logged in!"
	  else
	    flash.now.alert = "Email or password was invalid"
	    render :new
	  end
	end

	def destroy
	  logout
	  redirect_to root_url, :notice => "Logged out!"
	end
end

		RUBY

		create_file "app/views/sessions/new.html.erb",  <<-RUBY
<%= form_tag sessions_path do %>
  <div class="field">
    <%= label_tag :email %>
    <%= text_field_tag :email, params[:email] %>
  </div>
  <div class="field">
    <%= label_tag :password %>
    <%= password_field_tag :password %>
  </div>
  <div class="field">
    <%= check_box_tag :remember_me, 1, params[:remember_me] %>
    <%= label_tag :remember_me %>
  </div>
  <div class="actions"><%= submit_tag "Log in" %></div>
<% end %>
		RUBY

		create_file "app/controllers/application_controller.rb",  <<-RUBY
class ApplicationController < ActionController::Base
	protect_from_forgery
	
	def not_authenticated
	  redirect_to login_url, :alert => "First login to access this page."
	end
	
	rescue_from CanCan::Unauthorized do |exception|
	  flash[:error] = "Access denied."
	  if current_user
	  	redirect_to current_user
	  else
	  	redirect_to root_url
	  end
	end	
end
		RUBY

		create_file "app/models/ability.rb",  <<-RUBY
class Ability
  include CanCan::Ability

  def initialize(user)
  	can :new, :users
  end
end
		RUBY

		route 'get "logout" => "sessions#destroy", :as => "logout"'
		route 'get "login" => "sessions#new", :as => "login"'
		route 'get "signup" => "users#new", :as => "signup"'
		route 'resources :users'
		route 'resources :sessions'
		route "resources :password_resets"

		rake "db:migrate"
	end
end
