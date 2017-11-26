require 'thread'
require 'gtk3'

require 'todoable'
require 'todoable/ui/gtk/lists'
require 'todoable/ui/gtk/jobqueue'

class MainPanel < Gtk::Stack
  attr_accessor :jobqueue
  attr_accessor :todoable

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
    # Create the elements
    login_form = LoginForm.new
    add_named login_form, "login_form"
    list_box = ListsBox.new self
    add_named list_box, "lists_box"

    # Define the login action
    login_form.signal_connect("connect_bt_clicked") { |w, username, password|
      Thread.new do
        begin
          @todoable.authenticate username, password
          @jobqueue.push {
            set_visible_child "lists_box"
            w.success
            list_box.load_lists
          }
        rescue Todoable::AuthError
          @jobqueue.push { w.report_error "User or password doesn't match" }
        rescue Exception => exc
          @jobqueue.push { w.report_error exc.to_s }
        end
      end
    }
  end
end
