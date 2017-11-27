require 'gtk3'

class Toolbar < Gtk::Box
  def initialize title, mainpanel, show_back_button = false
    super :horizontal, 10
    @show_back_button = show_back_button
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

    # Button that only shows up if there's a place to go back to
    bt_back = Gtk::ToolButton.new(
      :label => "Go back",
      :icon_widget => Gtk::Image.new(:icon_name => 'go-previous-symbolic'))
    bt_back.set_tooltip_text bt_back.label
    bt_back.signal_connect("clicked") {
      mainpanel.set_visible_child "lists_box"
    }

    # Buttons that always show up
    bt_disconnect = Gtk::ToolButton.new(
      :label => "Disconnect",
      :icon_widget => Gtk::Image.new(:icon_name => 'avatar-default-symbolic'))
    bt_disconnect.set_tooltip_text bt_disconnect.label
    bt_disconnect.signal_connect("clicked") {
      mainpanel.set_visible_child "login_form"
    }

    bt_quit = Gtk::ToolButton.new(
      :label => "Quit",
      :icon_widget => Gtk::Image.new(:icon_name => 'application-exit-symbolic'))
    bt_quit.set_tooltip_text bt_quit.label
    bt_quit.signal_connect("clicked") { Gtk.main_quit }

    # Create the toolbar and add it to the box
    toolbar = Gtk::Toolbar.new
    toolbar.style_context.add_class("primary-toolbar")
    toolbar.insert Gtk::SeparatorToolItem.new.set_draw(false).set_expand(true), 0
    toolbar.insert bt_back, 1 if @show_back_button
    toolbar.insert bt_disconnect, 2
    toolbar.insert bt_quit, 3
    pack_start toolbar
  end
end
