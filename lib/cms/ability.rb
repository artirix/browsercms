class Cms::Ability
  include CanCan::Ability

  def initialize(user)
    super(user)
    if user && !user.try(:guest?)
      cms(user)
    else
      guest(user)
    end
  end

  def guest(_user)

  end

  def cms(user)
    can :manage, :all

    cannot :manage, Order
    cannot :manage, Lead
    cannot :manage, Feed
    cannot :manage, ContentTools::PageSnippet
    cannot :read, :admin_dashboard

    # Cannot create anyone except 'customer admin'
    cannot :create, Role, title: %w(admin business private translator)

    # Cannot modify admins
    cannot [:edit, :update, :destroy, :reset_password], User do |u|
      roles = u.roles.map do |role|
        case role
        when Role   then role.title
        when String then role
        end
      end

      roles.include? 'admin'
    end
  end

end