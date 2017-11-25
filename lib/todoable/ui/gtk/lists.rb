require 'gtk3'

class ListsTreeView < Gtk::TreeView
  COLUMN_ID = 0
  COLUMN_NAME = 1

  def initialize
    @model = Gtk::ListStore.new Integer, String
    super @model

    setup_columns
    append 10, "Urgent Things"
  end

  def append id, name
    @model.append.set_values [id, name]
  end

  def clean
  end

  private

  def setup_columns
    renderer0 = Gtk::CellRendererText.new
    column0 = Gtk::TreeViewColumn.new "ID", renderer0, "text" => COLUMN_ID
    column0.sort_column_id = COLUMN_ID
    column0.set_visible false
    append_column column0

    renderer1 = Gtk::CellRendererText.new
    column1 = Gtk::TreeViewColumn.new "Name", renderer1, "text" => COLUMN_NAME
    column1.sort_column_id = COLUMN_NAME
    append_column column1
  end
end
