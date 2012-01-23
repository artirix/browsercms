require "test_helper"

class ConnectableTest < ActiveSupport::TestCase

  def setup
    given_a_site_exists
    @block = Factory(:html_block)
    @connected_page = Factory(:public_page, :parent=>root_section)
    @connected_page_2 = Factory(:public_page, :parent=>root_section)
    @unconnected_page = Factory(:public_page, :parent=>root_section)

    @connected_page.create_connector(@block, "main")
    @connected_page_2.create_connector(@block, "main")
  end

  def teardown
  end

  test "#connected_pages" do
    assert_equal [@connected_page, @connected_page_2], @block.connected_pages
  end

  test "@connected_pages should return same list when called twice" do
    expected = @block.connected_pages
    assert_equal expected.object_id, @block.connected_pages.object_id
  end
end