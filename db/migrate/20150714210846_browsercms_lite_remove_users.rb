class BrowsercmsLiteRemoveUsers < ActiveRecord::Migration
  def up
    [
      :cms_group_permissions,
      :cms_group_type_permissions,
      :cms_group_types,
      :cms_permissions,
      :cms_group_sections,
      :cms_groups,
      :cms_user_group_memberships,
      :cms_users,
    ].each do |t|
      drop_table t if table_exists? t
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
