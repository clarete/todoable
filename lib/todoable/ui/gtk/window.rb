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
require 'todoable/ui/gtk/mainpanel'

module Todoable::UI
  class Window < Gtk::Window
    def initialize base_uri
      super :toplevel

      # Define window properties
      set_title "Todoable"
      set_default_size 500, 200
      set_window_position :center
      signal_connect("destroy") { Gtk.main_quit }

      # Populate window with internal UI elements
      add(MainPanel.new base_uri)
    end
  end
end
