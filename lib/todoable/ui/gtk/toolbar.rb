require 'gtk3'

class Toolbar < Gtk::Box
  def initialize title, mainpanel
    super :horizontal, 10
    @label = nil
    add_ui_elements title, mainpanel
  end

  def set_title title
    @label.set_markup "<span font-weight='heavy' font='32'>#{title}</span>"
  end

  private

  def add_ui_elements title, mainpanel
    @label = Gtk::Label.new
    @label.set_markup "<span font-weight='heavy' font='32'>#{title}</span>"
    @label.set_alignment 0, 0.5
    pack_start @label, :expand => true, :fill => true

    # Buttons that always show up
    bt_disconnect = Gtk::ToolButton.new(
     :label => "Disconnect",
     :stock_id => Gtk::Stock::DISCONNECT)
    bt_disconnect.set_tooltip_text bt_disconnect.label
    bt_disconnect.signal_connect("clicked") {
      mainpanel.set_visible_child "login_form"
    }

    bt_quit = Gtk::ToolButton.new(
     :label => "Quit",
     :stock_id => Gtk::Stock::QUIT)
    bt_quit.set_tooltip_text bt_quit.label
    bt_quit.signal_connect("clicked") { Gtk.main_quit }

    # Create the toolbar and add it to the box
    toolbar = Gtk::Toolbar.new
    toolbar.style_context.add_class("primary-toolbar")
    toolbar.insert Gtk::SeparatorToolItem.new.set_draw(false).set_expand(true), 0
    toolbar.insert bt_disconnect, 1
    toolbar.insert bt_quit, 2
    pack_start toolbar
  end
end
