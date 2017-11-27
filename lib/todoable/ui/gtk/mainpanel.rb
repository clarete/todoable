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

require 'thread'
require 'gtk3'

require 'todoable'
require 'todoable/ui/gtk/jobqueue'
require 'todoable/ui/gtk/loginform'
require 'todoable/ui/gtk/lists'
require 'todoable/ui/gtk/items'

module Todoable::UI
  # Main widget within the Todoable window.
  #
  # The `MainPanel` is responsible for holding the screens within the
  # main window and to provide a mechanism to switch between them. The
  # routing between the child components is done using the method
  # `Gtk::Stack#set_visible_child`

  class MainPanel < Gtk::Stack
    attr_accessor :jobqueue
    attr_accessor :todoable
    attr_accessor :selected

    def initialize base_uri
      super()

      # Define stack properties
      set_transition_type :slide_up_down

      # Instance that updates the UI when threads have results to
      # present
      @jobqueue = JobQueue.new
      @todoable = Todoable::Todoable.new base_uri

      # This is the list that is currently selected. Defaults to no
      # lists and only gets set when the user clicks in one of the lists
      # on the ListsBox TreeView.
      @selected = nil

      # Populate window with internal UI elements
      @items_box = nil
      add_ui_elements
    end

    def list_items list
      set_visible_child "items_box"
      @selected = list
      @items_box.load_items
    end

    private

    def add_ui_elements
      # Create the elements
      login_form = LoginForm.new
      add_named login_form, "login_form"
      lists_box = ListsBox.new self
      add_named lists_box, "lists_box"
      @items_box = ItemsBox.new self
      add_named @items_box, "items_box"

      # Define the login action
      login_form.signal_connect("connect_bt_clicked") { |w, username, password|
        Thread.new do
          begin
            @todoable.authenticate username, password
            @jobqueue.push {
              set_visible_child "lists_box"
              w.success
              lists_box.load_lists
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
end
