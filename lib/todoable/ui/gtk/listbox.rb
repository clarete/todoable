require 'gtk3'

class ListsBox < Gtk::Box
  def initialize
    super :vertical
    pack_start Toolbar.new
    pack_start ListsTreeView.new, :expand => true, :fill => true
  end
end

class Toolbar < Gtk::Toolbar
  def initialize
    super
    style_context.add_class("primary-toolbar")

    # Buttons of our toolbar
    @bt_disconnect = @bt_new = @bt_quit = nil
    setup_buttons
  end

  private

  def setup_buttons
    @bt_new = Gtk::ToolButton.new(
      :label => "New List",
      :stock_id => Gtk::Stock::NEW)
    @bt_new.is_important = true
    @bt_new.set_tooltip_text @bt_new.label

    @bt_disconnect = Gtk::ToolButton.new(
      :label => "Disconnect",
      :stock_id => Gtk::Stock::DISCONNECT)
    @bt_disconnect.set_tooltip_text @bt_disconnect.label

    @bt_quit = Gtk::ToolButton.new(
      :label => "Quit",
      :stock_id => Gtk::Stock::QUIT)
    @bt_quit.set_tooltip_text @bt_quit.label

    insert @bt_new, 0
    insert Gtk::SeparatorToolItem.new.set_draw(false).set_expand(true), 1
    insert @bt_disconnect, 2
    insert @bt_quit, 3
  end
end

class ListsTreeView < Gtk::TreeView
  COLUMN_ID = 0
  COLUMN_NAME = 1

  def initialize
    @model = Gtk::ListStore.new Integer, String
    super @model
    set_margin 10

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
