require 'thread'
require 'gtk3'

require 'todoable/ui/gtk/toolbar'

class ListsBox < Gtk::Box
  def initialize mainpanel
    super :vertical
    set_margin 10
    @mainpanel = mainpanel

    # Populate widget with internal UI elements
    @listview = nil
    add_ui_elements
  end

  def load_lists
    start_loading
    Thread.new do
      @mainpanel.todoable.lists.each do |list|
        @mainpanel.jobqueue.push { @listview.append list.id, list.name }
      end

      # Our job here's done, let's make the treeview sensitive again
      # so the user can interact with it
      @mainpanel.jobqueue.push { finish_loading }
    end
  end

  private

  def start_loading
    set_sensitive false
    @listview.clear
  end

  def finish_loading
    set_sensitive true
  end

  def add_ui_elements
    # Add the toolbar
    pack_start Toolbar.new "Lists", @mainpanel

    # Add the list view
    @listview = ListsTreeView.new
    pack_start @listview, :expand => true, :fill => true
  end
end

class ListsTreeView < Gtk::TreeView
  COLUMN_ID = 0
  COLUMN_NAME = 1

  def initialize
    @model = Gtk::ListStore.new String, String
    super @model
    setup_columns
  end

  def append id, name
    @model.append.set_values [id, name]
  end

  def clear
    @model.clear
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
