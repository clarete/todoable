# Copyright (c) 2002-2017 Ruby-GNOME2 Project Team
#
# This program is free software. You can distribute/modify this
# program under the terms of the GNU LESSER GENERAL PUBLIC LICENSE
# Version 2.1.
#
# This very useful piece of code was copied from the ruby-gnome2
# project, more specifically from this URI:
# https://github.com/ruby-gnome2/ruby-gnome2/blob/master/gtk3/sample/misc/threads.rb

require 'gtk3'
require 'thread'

class JobQueue
  def initialize
    @queue = Queue.new
    @worker_id = nil
  end

  def push(&job)
    @queue << job
    if @worker_id.nil?
      start_worker
    end
  end

  def stop
    return if @worker_id.nil?
    GLib::Source.remove(@worker_id)
    @worker_id = nil
  end

  private
  def start_worker
    @worker_id = GLib::Idle.add do
      job = @queue.pop
      job.call
      if @queue.empty?
        @worker_id = nil
        GLib::Source::REMOVE
      else
        GLib::Source::CONTINUE
      end
    end
  end
end
