require 'gtk3'

class NewItemDialog < Gtk::Dialog
  def initialize parent, title, default_text = ''
    super :parent => parent,
          :title => title,
          :flags => [:modal, :destroy_with_parent],
          :buttons => [
            [Gtk::Stock::OK, Gtk::ResponseType::OK],
            [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]]

    # Set UI and UX properties
    set_default_response Gtk::ResponseType::OK
    child.margin = 10

    # Populate widget with internal UI elements
    @default_text = default_text
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
    @name_input.text = @default_text
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
