require 'gtk3'
require 'todoable/ui/gtk/listbox'

class MainPanel < Gtk::Stack
  def initialize
    super

    # Define stack properties
    set_transition_type :slide_up_down

    # Populate window with internal UI elements
    @login_form = nil
    add_ui_elements
  end

  private

  def add_ui_elements
    @login_form = LoginForm.new
    @login_form.signal_connect("connect_bt_clicked") { |w, username, password|
      # puts username
      # puts password
      #w.report_error "Login failed: Didn't weeeerkkkk"
      set_visible_child "lists"
    }
    add_named @login_form, "login_form"

    @lists = ListsBox.new
    add_named @lists, "lists"
  end
end
