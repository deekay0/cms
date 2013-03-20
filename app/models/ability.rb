class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.has_role? :admin
      can :manage, :all
    elsif user.has_role? :investor
      can :view, :investor
      can :read, :company
    elsif user.has_role? :founder
      can :manage, :company
      can :view, :founder
    end

  end
end