require 'thread'
require 'gtk3'

require 'todoable/ui/gtk/toolbar'

class ListsBox < Gtk::Box
  def initialize mainpanel
    super :vertical
    set_margin 10
    @mainpanel = mainpanel

    # Populate widget with internal UI elements
    @listview = @spinner = nil
    add_ui_elements
  end

  def load_lists
    start_loading
    Thread.new do
      lists = @mainpanel.todoable.lists
      @mainpanel.jobqueue.push {
        @listview.clear
        lists.each { |list| @listview.append list }
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
    pack_start Toolbar.new "Lists", @mainpanel

    # Add the list view
    @listview = ListsTreeView.new self, @mainpanel
    pack_start @listview, :expand => true, :fill => true

    # Add the box that holds the button to create new lists and the
    # spinner
    box = Gtk::Box.new :horizontal, 10
    pack_end box, :padding => 10
    add_button = Gtk::Button.new :label => "New List"
    add_button.signal_connect("clicked") { run_new_list_dialog }
    box.pack_start add_button
    @spinner = Gtk::Spinner.new
    box.pack_end @spinner, :padding => 10
  end

  def run_new_list_dialog
    dialog = NewListDialog.new @mainpanel.parent
    response = dialog.run_and_get_input
    dialog.destroy

    # Let's request creating a new list if the response contains
    # anything usable as a name of a list
    if response != nil
      start_loading
      Thread.new do
        @mainpanel.todoable.new_list response
        load_lists
      end
    end
  end
end

class NewListDialog < Gtk::Dialog
  def initialize parent
    super :parent => parent,
          :title => "New List",
          :flags => [:modal, :destroy_with_parent],
          :buttons => [
            [Gtk::Stock::OK, Gtk::ResponseType::OK],
            [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]]

    # Set UI and UX properties
    set_default_response Gtk::ResponseType::OK
    child.margin = 10

    # Populate widget with internal UI elements
    @name_input = nil
    add_ui_elements
  end

  def run_and_get_input
    @name_input.text if run == :ok
  end

  private

  def add_ui_elements
    # Entry that will receive the name of the new list from the user
    @name_input = Gtk::Entry.new
    @name_input.set_activates_default true
    @name_input.signal_connect("changed") { |w|
      set_response_sensitive Gtk::ResponseType::OK, w.text != ""
    }
    # Will disable response button right away since default text is
    # empty
    @name_input.signal_emit "changed"

    # A form with a nice label and the above input
    form_box = Gtk::Box.new :vertical, 10
    form_box.pack_start Gtk::Label.new("Name").set_alignment(0, 0.5)
    form_box.pack_start @name_input, :expand => false
    form_box.show_all
    content_area.pack_start form_box, :padding => 10
  end
end

class ListsTreeView < Gtk::TreeView
  COLUMN_LIST = 0
  COLUMN_ID = 1
  COLUMN_NAME = 2

  def initialize listsbox, mainpanel
    @model = Gtk::ListStore.new Object, String, String
    super @model
    @listsbox = listsbox
    @mainpanel = mainpanel
    setup_columns
  end

  def append list
    @model.append.set_values [list, list.id, list.name]
  end

  def clear
    @model.clear
  end

  private

  def setup_columns
    # The column that will store the Todoable::List instance
    column0 = Gtk::TreeViewColumn.new "Instance", nil, "text" => COLUMN_LIST
    column0.set_visible false
    append_column column0

    # The invisible column that holds the ID of the list
    column1 = Gtk::TreeViewColumn.new "ID", nil, "text" => COLUMN_ID
    column1.set_visible false
    append_column column1

    # The column to display the name of the list
    renderer2 = Gtk::CellRendererText.new
    renderer2.set_editable true
    renderer2.signal_connect("edited") { |_, path, new_name|
      patch_list(path, new_name)
    }
    column2 = Gtk::TreeViewColumn.new "Name", renderer2, "text" => COLUMN_NAME
    column2.sort_column_id = COLUMN_NAME
    append_column column2
  end

  def patch_list path, new_name
    iter = @model.get_iter path
    list = @model.get_value iter, COLUMN_LIST
    if list.name != new_name
      @listsbox.start_loading
      Thread.new do
        list.update new_name
        @mainpanel.jobqueue.push {
          iter[COLUMN_NAME] = new_name
          @listsbox.finish_loading
        }
      end
    end
  end
end
