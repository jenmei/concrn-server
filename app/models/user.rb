class User < ApplicationRecord
  belongs_to :affiliate, optional: true
  has_one :reporter
  has_one :responder

  has_secure_token :token
  has_secure_token :refresh_token
  has_secure_password validations: false

  before_save :ensure_role_persists_records

  def ensure_role_persists_records
    if role == "affiliate_responder"
      self.responder = Responder.new(
        user: self
      )
    end
  end

  def name
    super || "SMS User"
  end

  def invalidate_token
    self.update_attributes(token: nil, token_issued_at: nil)
  end

  def affiliate?
    role =~ /affiliate/
  end

  def self.valid_email_login?(email, password)
    user = find_by(email: email)
    user if user&.authenticate(password)
  end

  def self.valid_phone_login?(phone, password)
    user = find_by(phone: phone)
    user if user&.authenticate(password)
  end

  def regenerate_token_with_expiration
    regenerate_token
    update_attributes(token_issued_at: Time.now)
  end
end
