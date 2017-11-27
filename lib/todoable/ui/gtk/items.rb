require 'thread'
require 'gtk3'

require 'todoable/ui/gtk/toolbar'
require 'todoable/ui/gtk/newitem'

class ItemsBox < Gtk::Box
  def initialize mainpanel
    super :vertical
    set_margin 10
    @mainpanel = mainpanel

    # Populate widget with internal UI elements
    @listview = @toolbar = @spinner = nil
    add_ui_elements
  end

  def load_items
    start_loading
    @toolbar.set_title @mainpanel.selected.name
    Thread.new do
      items = @mainpanel.selected.items
      @mainpanel.jobqueue.push {
        @listview.clear
        items.each { |item| @listview.append item }
        finish_loading
      }
    end
  end

  def start_loading
    @spinner.start
    set_sensitive false
  end

  def finish_loading
    @spinner.stop
    set_sensitive true
  end

  private

  def add_ui_elements
    # Add the toolbar
    @toolbar = Toolbar.new "Items", @mainpanel
    pack_start @toolbar

    # Add the list view
    @listview = ItemsTreeView.new self, @mainpanel
    pack_start @listview, :expand => true, :fill => true

    # Box that holds buttons & spinner
    box = Gtk::Box.new :horizontal, 10
    pack_end box, :padding => 10

    # Button for adding new TODO items
    add_button = Gtk::Button.new :label => "New TODO Item"
    add_button.signal_connect("clicked") { run_new_item_dialog }
    box.pack_start add_button

    # Spinner for showing loading status
    @spinner = Gtk::Spinner.new
    box.pack_end @spinner, :padding => 10
  end

  def run_new_item_dialog
    dialog = NewItemDialog.new @mainpanel.parent, "New TODO Item"
    response = dialog.run_and_get_input
    dialog.destroy

    # Let's request creating a new list if the response contains
    # anything usable as a name of a list
    if response != nil
      start_loading
      Thread.new do
        @mainpanel.selected.new_item response
        load_items
      end
    end
  end
end

class ItemsTreeView < Gtk::TreeView
  COLUMN_INSTANCE = 0
  COLUMN_ID = 1
  COLUMN_NAME = 2
  COLUMN_FINISHED = 3
  COLUMN_FINISHED_BUTTON = 4
  COLUMN_DELETE = 5

  def initialize listsbox, mainpanel
    @model = Gtk::ListStore.new Object, String, String, String, String, String
    super @model
    @listsbox = listsbox
    @mainpanel = mainpanel
    setup_columns
  end

  def append item
    @model.append.set_values [
      item,
      item.id,
      "<big>#{item.name}</big>",
      item.finished_at,
      "emblem-ok-symbolic",
      "edit-delete-symbolic"
    ]
  end

  def clear
    @model.clear
  end

  private

  def setup_columns
    # The column that will store the Todoable::Item instance
    column_item = Gtk::TreeViewColumn.new "Instance", nil, "text" => COLUMN_INSTANCE
    column_item.set_visible false
    append_column column_item

    # The invisible column that holds the ID of the item
    column_id = Gtk::TreeViewColumn.new "ID", nil, "text" => COLUMN_ID
    column_id.set_visible false
    append_column column_id

    # The column to display the name of the item
    renderer_name = Gtk::CellRendererText.new
    renderer_name.set_padding 5, 5
    column_name = Gtk::TreeViewColumn.new "Name", renderer_name, "markup" => COLUMN_NAME
    column_name.set_expand true
    append_column column_name

    # The column to display the name of the finished date
    renderer_finished = Gtk::CellRendererText.new
    renderer_finished.set_padding 5, 5
    column_finished = Gtk::TreeViewColumn.new "Finished", renderer_finished, "text" => COLUMN_FINISHED
    column_finished.set_expand false
    append_column column_finished

    # The column to display the icon for finishing the item
    renderer_finish = Gtk::CellRendererPixbuf.new
    renderer_finish.set_padding 5, 5
    column_finish = Gtk::TreeViewColumn.new(
      "", renderer_finish,
      "icon_name" => COLUMN_FINISHED_BUTTON)
    column_finish.set_expand false
    append_column column_finish

    # The column to display the delete icon
    renderer_delete = Gtk::CellRendererPixbuf.new
    renderer_delete.set_padding 5, 5
    column_delete = Gtk::TreeViewColumn.new(
      "", renderer_delete,
      "icon_name" => COLUMN_DELETE)
    column_delete.set_expand false
    append_column column_delete

    # Let's not show the headers
    set_headers_visible false

    # This will allow the delete icon to be activated with a single
    # click
    set_activate_on_single_click true
    signal_connect("row-activated") { |w, path, column|
      delete_item(path) if column == column_delete
    }
  end

  def delete_item path
    iter = @model.get_iter path
    item = @model.get_value iter, COLUMN_INSTANCE

    @listsbox.start_loading
    Thread.new do
      item.delete
      @mainpanel.jobqueue.push {
        @model.remove iter
        @listsbox.finish_loading
      }
    end
  end
end
