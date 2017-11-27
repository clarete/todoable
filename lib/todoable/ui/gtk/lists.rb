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

require 'todoable/ui/gtk/toolbar'
require 'todoable/ui/gtk/newitem'

module Todoable::UI
  class ListsBox < Gtk::Box
    def initialize mainpanel
      super :vertical
      set_margin 10
      @mainpanel = mainpanel

      # Populate widget with internal UI elements
      @listview = @spinner = nil
      add_ui_elements
    end

    def load_lists
      start_loading
      Thread.new do
        lists = @mainpanel.todoable.lists
        @mainpanel.jobqueue.push {
          @listview.clear
          lists.each { |list| @listview.append list }
          finish_loading
        }
      end
    end

    def start_loading
      @spinner.start
      set_sensitive false
    end

    def finish_loading
      @spinner.stop
      set_sensitive true
    end

    private

    def add_ui_elements
      # Add the toolbar
      pack_start Toolbar.new("Lists", @mainpanel), :padding => 10

      # Add the list view
      @listview = ListsTreeView.new self, @mainpanel
      pack_start @listview, :expand => true, :fill => true

      # Add the box that holds the button to create new lists and the
      # spinner
      box = Gtk::Box.new :horizontal, 10
      pack_end box, :padding => 10
      add_button = Gtk::Button.new :label => "_New List"
      add_button.set_use_underline true
      add_button.signal_connect("clicked") { run_new_list_dialog }
      box.pack_start add_button
      @spinner = Gtk::Spinner.new
      box.pack_end @spinner, :padding => 10
    end

    def run_new_list_dialog
      dialog = NewItemDialog.new @mainpanel.parent, "New List"
      response = dialog.run_and_get_input
      dialog.destroy

      # Let's request creating a new list if the response contains
      # anything usable as a name of a list
      if response != nil
        start_loading
        Thread.new do
          @mainpanel.todoable.new_list response
          load_lists
        end
      end
    end
  end

  class ListsTreeView < Gtk::TreeView
    COLUMN_LIST = 0
    COLUMN_ID = 1
    COLUMN_NAME = 2
    COLUMN_EDIT = 3
    COLUMN_DELETE = 4

    def initialize listsbox, mainpanel
      @model = Gtk::ListStore.new Object, String, String, String, String
      super @model
      @listsbox = listsbox
      @mainpanel = mainpanel
      setup_columns
    end

    def append list
      @model.append.set_values [
list,
list.id,
"<big>#{list.name}</big>",
"document-edit-symbolic",
"edit-delete-symbolic"
]
    end

    def clear
      @model.clear
    end

    private

    def setup_columns
      # The column that will store the Todoable::List instance
      column_list = Gtk::TreeViewColumn.new "Instance", nil, "text" => COLUMN_LIST
      column_list.set_visible false
      append_column column_list

      # The invisible column that holds the ID of the list
      column_id = Gtk::TreeViewColumn.new "ID", nil, "text" => COLUMN_ID
      column_id.set_visible false
      append_column column_id

      # The column to display the name of the list
      renderer_name = Gtk::CellRendererText.new
      renderer_name.set_padding 5, 5
      column_name = Gtk::TreeViewColumn.new "Name", renderer_name, "markup" => COLUMN_NAME
      column_name.set_expand true
      append_column column_name

      # The column to display the edit icon
      renderer_edit = Gtk::CellRendererPixbuf.new
      renderer_edit.set_padding 5, 5
      column_edit = Gtk::TreeViewColumn.new(
        "Edit", renderer_edit,
        "icon_name" => COLUMN_EDIT)
      column_edit.set_expand false
      append_column column_edit

      # The column to display the delete icon
      renderer_delete = Gtk::CellRendererPixbuf.new
      renderer_delete.set_padding 5, 5
      column_delete = Gtk::TreeViewColumn.new(
        "Delete", renderer_delete,
        "icon_name" => COLUMN_DELETE)
      column_delete.set_expand false
      append_column column_delete

      # Let's not show the headers
      set_headers_visible false

      # Handles the clicking on each row
      set_activate_on_single_click true
      signal_connect("row-activated") { |w, path, column|
        iter = @model.get_iter path
        list = @model.get_value iter, COLUMN_LIST

        if column == column_name
          # Ask the main panel to show the items from the selected list
          # if the user clicks the column that contains the list name
          @mainpanel.list_items list
        elsif column == column_edit
          run_edit_dialog iter, list
        elsif column == column_delete
          delete_list iter, list
        end
      }
    end

    def run_edit_dialog iter, list
      dialog = NewItemDialog.new @mainpanel.parent, "Rename List", list.name
      response = dialog.run_and_get_input
      dialog.destroy

      # Let's request creating a new list if the response contains
      # anything usable as a name of a list
      if response != nil && response != list.name
        patch_list iter, list, response
      end
    end

    def delete_list iter, list
      @listsbox.start_loading
      Thread.new do
        list.delete
        @mainpanel.jobqueue.push {
          @model.remove iter
          @listsbox.finish_loading
        }
      end
    end

    def patch_list iter, list, new_name
      @listsbox.start_loading
      Thread.new do
        list.update new_name
        @mainpanel.jobqueue.push {
          iter[COLUMN_NAME] = "<big>#{new_name}</big>"
          @listsbox.finish_loading
        }
      end
    end
  end
end
