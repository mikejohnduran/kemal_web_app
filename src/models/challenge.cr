require "granite_orm/adapter/mysql"

class Challenge < Granite::ORM::Base
  adapter mysql
  field title : String
  field details : String
  field posted_by : String
  timestamps
end
