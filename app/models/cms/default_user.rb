module Cms

  # A parent class for users that need to be persisted in the CMS database.
  class DefaultUser < ActiveRecord::Base

    self.table_name = 'cms_default_users'

    validates_presence_of :login
    validates_uniqueness_of :login, case_sensitive: false

    # we accept whatever we receive
    # validates_format_of :login, :with => /\A\w[\w\.\-_@]+\z/, :message => "use only letters, numbers, and .-_@ please."

    # Determines if this user a Guest or not.
    def guest?
      false
    end

    # Determines if this user should have access to the CMS administration tools. Can be overridden by specific users (like GuestUser)
    # which may not need to check the database for that information.
    def cms_access?
      true
    end

    alias_method :full_name, :name

    def full_name_with_login
      "#{name} (#{login})"
    end

    def full_name_or_login
      if name.strip.present?
        name
      else
        login
      end
    end

    # all viewable by default
    def viewable_sections
      Cms::Section.all
    end

    # all viewable by default
    def modifiable_sections
      Cms::Section.all
    end


    # true by default
    def able_to?(*)
      true
    end

    # Determine if this user has permission to view the specific object. Permissions
    #   are always tied to a specific section. This method can take different input parameters
    #   and will attempt to determine the relevant section to check.
    # Expects object to be of type:
    #   1. Section - Will check the user's groups to see if any of those groups can view this section.
    #   2. Path - Will look up the section based on the path, then check it.  (Note that section paths are not currently unique, so this will check the first one it finds).
    #   3. Other - Assumes it has a section attribute and will call that and check the return value.
    #
    # Returns: true if the user can view this object, false otherwise.
    # Raises: ActiveRecord::RecordNotFound if a path to a not existent section is passed in.
    def able_to_view?(object)
      section = object
      if object.is_a?(String)
        section = Cms::Section.find_by_path(object)
        raise ActiveRecord::RecordNotFound.new("Could not find section with path = '#{object}'") unless section
      elsif !object.is_a?(Cms::Section)
        section = object.parent
      end
      viewable_sections.include?(section) || cms_access?
    end

    def able_to_modify?(object)
      case object
      when Cms::Section
        modifiable_sections.include?(object)
      when Cms::Page, Cms::Link
        modifiable_sections.include?(object.section)
      else
        if object.class.respond_to?(:connectable?) && object.class.connectable?
          object.connected_pages.all? { |page| able_to_modify?(page) }
        else
          true
        end
      end
    end

    # Expects node to be a Section, Page or Link
    # Returns true if the specified node, or any of its ancestor sections, is editable by any of
    # the user's 'CMS User' groups.
    def able_to_edit?(object)
      able_to?(:edit_content) && able_to_modify?(object)
    end

    def able_to_publish?(object)
      able_to?(:publish_content) && able_to_modify?(object)
    end

    def able_to_edit_or_publish_content?
      able_to?(:edit_content, :publish_content)
    end

  end
end