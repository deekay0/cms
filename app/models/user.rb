class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :stripe_token, :coupon, :provider, :uid, :avatar
  attr_accessor :stripe_token, :coupon

  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"

  before_save :update_stripe
  before_destroy :cancel_subscription

  #a user can found many companies
  has_one :found_company
  has_one :company, through: :found_company

  #a user can bid on many companies
  has_many :bids
  has_many :bid_companies, through: :bids, source: :company

  #a user can follow many companies
  has_many :follow_companies, dependent: :destroy
  has_many :followed_companies, through: :follow_companies, source: :company

  def update_plan(role)
    self.role_ids = []
    self.add_role(role.name)
    unless customer_id.nil?
      customer = Stripe::Customer.retrieve(customer_id)
      customer.update_subscription(:plan => role.name)
    end
    true
  rescue Stripe::StripeError => e
    logger.error "Stripe Error: " + e.message
    errors.add :base, "Unable to update your subscription. #{e.message}."
    false
  end
  
  def update_stripe
    return if email.include?(ENV['ADMIN_EMAIL'])
    return if email.include?('@example.com') and not Rails.env.production?
    if customer_id.nil?
      if !stripe_token.present?
        raise "Stripe token not present. Can't create account."
      end
      if coupon.blank?
        customer = Stripe::Customer.create(
          :email => email,
          :description => name,
          :card => stripe_token,
          :plan => roles.first.name
        )
      else
        customer = Stripe::Customer.create(
          :email => email,
          :description => name,
          :card => stripe_token,
          :plan => roles.first.name,
          :coupon => coupon
        )
      end
    else
      customer = Stripe::Customer.retrieve(customer_id)
      if stripe_token.present?
        customer.card = stripe_token
      end
      customer.email = email
      customer.description = name
      customer.save
    end
    self.last_4_digits = customer.active_card.last4
    self.customer_id = customer.id
    self.stripe_token = nil
  rescue Stripe::StripeError => e
    logger.error "Stripe Error: " + e.message
    errors.add :base, "#{e.message}."
    self.stripe_token = nil
    false
  end
  
  def cancel_subscription
    unless customer_id.nil?
      customer = Stripe::Customer.retrieve(customer_id)
      unless customer.nil? or customer.respond_to?('deleted')
        if customer.subscription.status == 'active'
          customer.cancel_subscription
        end
      end
    end
  rescue Stripe::StripeError => e
    logger.error "Stripe Error: " + e.message
    errors.add :base, "Unable to cancel your subscription. #{e.message}."
    false
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
  
  def expire
    UserMailer.expire_email(self).deliver
    destroy
  end

  def following?(company)
    follow_companies.find_by_company_id(company.id)
  end

  def follow!(company)
    follow_companies.create! company_id:company.id
  end

  def unfollow!(company)
    comp = follow_companies.find_by_company_id(company.id)
    puts "company.id: #{company.id}"
    puts "company: #{company}"
    comp.destroy
  end
end
