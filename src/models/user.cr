require "granite_orm/adapter/mysql"
require "crypto/bcrypt/password"

class User < Granite::ORM::Base
  include Crypto
  adapter mysql

  belongs_to :country

  has_many :followers
  has_many :artists, through: followers

  has_many :listeners
  has_many :playlists, through: listeners

  has_many_as :created_playlists, alias_for: :playlists

  primary id : Int64
  field email : String
  field hashed_password : String
  field name : String
  field birthday : Time
  field gender : Int32
  field role : Int32
  timestamps

  validate :email, "is required", -> (user : User) do
    (email = user.email) ? !email.empty? : false
  end

  validate :email, "already in use", -> (user : User) do
    existing = User.find_by :email, user.email
    !existing
  end

  validate :password, "is too short", -> (user : User) do
    user.password_changed? ? user.valid_password_size? : true
  end

  def password=(password)
    @new_password = password
    @hashed_password = Bcrypt::Password.create(password, cost: 10).to_s
  end

  def password
    (hash = hashed_password) ? Bcrypt::Password.new(hash) : nil
  end

  def password_changed?
    new_password ? true : false
  end

  def valid_password_size?
    (pass = new_password) ? pass.size >= 8 : false
  end

  def authenticate(password : String)
    (bcrypt_pass = self.password) ? bcrypt_pass == password : false
  end

  private getter new_password : String?
end
