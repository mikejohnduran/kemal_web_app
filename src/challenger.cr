# Provides a directory for kemal files
require "./challenge/*"
require "kemal-session"
require "./auth"
require "kemal"

module Challenger
  get "/" do
    render "src/challenge/views/home.ecr", "src/challenge/views/layouts/main.ecr"
  end
  Kemal.config.port = 6969
  Kemal.run
end

Kemal::Session.config do |config|
  config.cookie_name = "sess_id"
  config.secret = "[SOME_SECRET]"
  config.gc_interval = 1.minutes
end

class UserStorableObject
  JSON.mapping({
    id_token: String,
  })
  include Kemal::Session::StorableObject

  def initialize(@id_token : String); end
end

# Routes for auth0
get "/auth/login" do |env|
  env.redirect "https://[YOUR_URL].auth0.com/login?client=[CLIENT_ID]"
end
get "/auth/callback" do |env|
  code = env.params.query["code"]
  jwt = Auth.get_auth_token(code)
  env.response.headers["Authorization"] = "Bearer #{jwt}" # Set the Auth header with JWT.
  user = UserStorableObject.new(jwt)
  env.session.object("user", user)
  env.redirect "/success"
end
get "/success" do |env|
  user = env.session.object("user").as(UserStorableObject)
  env.response.headers["Authorization"] = "Bearer #{user.id_token}"
  render "src/challenge/views/success.ecr", "src/challenge/views/layouts/main.ecr"
end
get "/auth/logout" do |env|
  env.session.destroy
  render "src/challenge/views/logout.ecr", "src/challenge/views/layouts/main.ecr"
end
get "/auth/callback" do |env|
  code = env.params.query["code"]
  jwt = Auth.get_auth_token(code)
  env.response.headers["Authorization"] = "Bearer #{jwt}"
end
before_get "/challenges" do |env|
  user = env.session.object("user").as(UserStorableObject)
  auth = User.authorised?(user.id_token)
  raise "Unauthorized" unless auth = true
end

get "/challenges" do |env|
  challenges = Challenge.all("ORDER BY id DESC")
  render "src/challenge/views/challenges/index.ecr", "src/challenge/views/layouts/main.ecr"
end
get "/challenges/:id" do |env|
  if challenge = Challenge.find env.params.url["id"]
    render("src/challenge/views/challenges/details.ecr", "src/challenge/views/layouts/main.ecr")
  else
    "Challenge with ID #{env.params.url["id"]} Not Found"
    env.redirect "/challenges"
  end
end
get "/challenges/new" do |env|
  render "src/challenge/views/challenges/new.ecr", "src/challenge/views/layouts/main.ecr"
end

error 500 do
  render "src/challenge/views/error/srv.ecr", "src/challenge/views/layouts/main.ecr"
end
error 401 do
  render "src/challenge/views/error/auth.ecr", "src/challenge/views/layouts/main.ecr"
end
