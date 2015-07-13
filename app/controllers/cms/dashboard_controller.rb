module Cms
  class DashboardController < Cms::BaseController

    def index
      @unpublished_pages = Page.unpublished.order("updated_at desc")
      @unpublished_pages = @unpublished_pages.select { |page| current_user.able_to_publish?(page) }
    end
  end
end