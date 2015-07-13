class Cms::UsersService

  GUEST_LOGIN = 'guest'
  GUEST_NAME  = 'Anonymous'

  # dirty trick needed for compatibility issues
  # https://amitrmohanty.wordpress.com/2014/01/20/how-to-get-current_user-in-model-and-observer-rails/
  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  class << self
    delegate :use_user, :use_guest_user, :guest_user, :ability_for, to: :service
  end

  def self.service
    @service || reload_service
  end

  def self.reload_service
    @service = new
  end

  def use_user(login)
    self.class.current = user(login)
  end

  def use_guest_user
    self.class.current = guest_user
  end

  def guest_user
    guest_user.tap { |u| extend_user u }
  end

  private
  def user(login)
    load_user(login).tap do |user|
      extend_user(user)
    end
  end

  def ability_for(user)
    Cms::Ability.new(user)
  end

  def extend_user(user)
    user.send :extend, CmsUserCompatibilityModule unless user.try :cms_user_compatible?
  end

  def load_user(login)
    Cms.user_class.where(Cms.user_key => login).first!
  end

  def load_guest_user
    params = {
      Cms.user_key        => GUEST_LOGIN,
      Cms.user_name_field => GUEST_NAME
    }

    Cms.user_class.new(params).tap do |guest_user|
      guest_user.send :extend, GuestUserModule
    end
  end

  class GuestUserModule
    def guest?
      true
    end

    def readonly?
      true
    end

    def cms_access?
      false
    end
  end

  module CmsUserCompatibilityModule

    def cms_user_compatible?
      true
    end

    # add expected columns
    def self.extended(base)
      unless base.respond_to? :login
        base.send :alias_method, :login, Cms.user_key.to_sym
      end

      unless base.respond_to? :full_name
        base.send :alias_method, :full_name, Cms.user_name_field.to_sym
      end
    end

    def guest?
      false
    end

    # COLUMN based

    def full_name_with_login
      "#{full_name} (#{login})"
    end

    def full_name_or_login
      if full_name.strip.present?
        full_name
      else
        login
      end
    end

    # permissions => TODO: Use Ability
    def cms_access?
      true
    end

    def able_to?(*)
      true
    end

    def able_to_view?(_object)
      true
    end

    def able_to_modify?(_object)
      true
    end

    def able_to_edit?(object)
      able_to?(:edit_content) && able_to_modify?(object)
    end

    def able_to_publish?(object)
      able_to?(:publish_content) && able_to_modify?(object)
    end

    def able_to_edit_or_publish_content?
      able_to?(:edit_content, :publish_content)
    end

    def viewable_sections
      Cms::Section.all
    end

    def modifiable_sections
      Cms::Section.all
    end


    # TODO: use ability
    def current_ability
      @current_ability ||= UsersService.ability_for(self)
    end

  end
end