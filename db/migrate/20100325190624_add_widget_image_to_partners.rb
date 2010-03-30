class AddWidgetImageToPartners < ActiveRecord::Migration
  def self.up
    add_column "partners", "widget_image", :string

    sql = "UPDATE partners SET widget_image = 'rtv234x60v1' WHERE widget_image IS NULL"
    how_many = ActiveRecord::Base.connection.update(sql)
    say "set default widget image for #{how_many} partners"
  end

  def self.down
    remove_column "partners", "widget_image"
  end
end
