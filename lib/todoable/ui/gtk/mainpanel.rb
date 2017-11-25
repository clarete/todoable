require 'thread'
require 'gtk3'

require 'todoable'
require 'todoable/ui/gtk/lists'
require 'todoable/ui/gtk/jobqueue'

class MainPanel < Gtk::Stack
  def initialize
    super

    # Define stack properties
    set_transition_type :slide_up_down

    # Instance that updates the UI when threads have results to
    # present
    @jobqueue = JobQueue.new
    @todoable = Todoable::Todoable.new "http://localhost:4567"

    # Populate window with internal UI elements
    add_ui_elements
  end

  private

  def add_ui_elements
    # Add the login form and define the login action
    login_form = LoginForm.new
    login_form.signal_connect("connect_bt_clicked") { |w, username, password|
      Thread.new do
        begin
          @todoable.authenticate username, password
          @jobqueue.push {
            set_visible_child "lists_box"
            w.success
          }
        rescue Todoable::AuthError
          @jobqueue.push { w.report_error "User or password doesn't match" }
        rescue Exception => exc
          @jobqueue.push { w.report_error exc.to_s }
        end
      end
    }
    add_named login_form, "login_form"

    # Add the lists tree view
    lists_box = Gtk::Box.new :vertical
    lists_box.set_margin 10
    lists_box.pack_start Toolbar.new "Lists", self
    lists_box.pack_start ListsTreeView.new, :expand => true, :fill => true
    add_named lists_box, "lists_box"
  end
end

class Toolbar < Gtk::Box
  def initialize title, mainpanel
    super :horizontal, 10
    @mainpanel = mainpanel
    add_ui_elements title
  end

  private

  def add_ui_elements title
    @label = Gtk::Label.new
    @label.set_markup "<span font-weight='heavy' font='32'>#{title}</span>"
    @label.set_alignment 0, 0.5
    pack_start @label, :expand => true, :fill => true

    # Buttons that always show up
    bt_disconnect = Gtk::ToolButton.new(
     :label => "Disconnect",
     :stock_id => Gtk::Stock::DISCONNECT)
    bt_disconnect.set_tooltip_text bt_disconnect.label
    bt_disconnect.signal_connect("clicked") { @mainpanel.set_visible_child "login_form" }

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
