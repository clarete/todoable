# Copyright (C) 2017  Lincoln Clarete <lincoln@clarete.li>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License (LGPL) as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'gtk3'

module Todoable::UI
  class LoginForm < Gtk::Box
    # Register with GLib so we can emit signals \o/
    type_register

    # Signal dispatched when the "connect" button is clicked. This way
    # we don't have to manage any state in this class.
    #
    # The two parameters passed to the signal handler are the "username"
    # and "password" collected from the form.
    signal_new(
      "connect_bt_clicked",       # name
      GLib::Signal::RUN_FIRST,    # flags
      nil,                        # accumulator (XXX: not supported yet)
      nil,                        # return type (void == nil)
      String, String,             # parameter types
    )

    def initialize
      # When type_register() is used, super is equivalent to
      # GLib::Object#initialize. Thus it needs a hash instead of passing
      # the actual parameters
      super "orientation" => :vertical, "spacing" => 10

      # Create UI Elements
      @errorbar = @errorlabel = @username = @password = @spinner = nil
      add_ui_elements
    end

    def report_error message
      set_sensitive true
      @spinner.stop
      @errorlabel.text = message
      @errorbar.set_no_show_all false
      @errorbar.show_all
      @errorbar.visible = true
    end

    def success
      set_sensitive true
      @spinner.stop
      @username.text = ''
      @password.text = ''
      @errorbar.hide
    end

    private

    # Default handler for the `connect_bt_clicked` signal. Override with
    # `signal_connect` on your instance
    def signal_do_connect_bt_clicked username, password
    end

    def do_login
      set_sensitive false
      @spinner.start
      signal_emit("connect_bt_clicked", @username.text, @password.text)
    end

    def add_ui_elements
      # Form container
      form_box = Gtk::Box.new :vertical, 10
      form_box.set_margin 100
      pack_start form_box

      # Title of the form
      title = Gtk::Label.new
      title.set_markup '<span font-weight="heavy" size="large">Login</span>'
      form_box.pack_start title, :expand => false, :padding => 10

      # User name field
      form_box.pack_start Gtk::Label.new("User name").set_alignment(0, 0.5), :expand => false
      @username = Gtk::Entry.new
      form_box.pack_start @username, :expand => false

      # Password field
      form_box.pack_start Gtk::Label.new("Password").set_alignment(0, 0.5), :expand => false
      @password = Gtk::Entry.new.set_visibility false
      form_box.pack_start @password, :expand => false

      # Login button
      login_bt = Gtk::Button.new :label => "Connect"
      login_bt.signal_connect("clicked") { do_login }
      form_box.pack_start login_bt, :expand => false, :fill => false, :padding => 10

      # Spinner
      @spinner = Gtk::Spinner.new
      form_box.pack_start @spinner, :padding => 10

      # Error bar
      @errorlabel = Gtk::Label.new
      @errorbar = Gtk::InfoBar.new
      @errorbar.show_close_button = true
      @errorbar.message_type = :error
      @errorbar.signal_connect("response") { @errorbar.hide }
      @errorbar.set_no_show_all true
      @errorbar.content_area.pack_start(
        @errorlabel,
        :expand => false,
        :fill => false,
        :padding => 0,
      )
      pack_end @errorbar, :expand => false
    end
  end
end
