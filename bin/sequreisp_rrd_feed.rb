#!/usr/bin/env ruby

# Sequreisp - Copyright 2010, 2011 Luciano Ruete
#
# This file is part of Sequreisp.
#
# Sequreisp is free software: you can redistribute it and/or modify
# it under the terms of the GNU Afero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Sequreisp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Afero General Public License for more details.
#
# You should have received a copy of the GNU Afero General Public License
# along with Sequreisp.  If not, see <http://www.gnu.org/licenses/>.

require 'rrd'
#require 'ruby-debug'
IFB_UP="ifb0"
IFB_DOWN="ifb1"
RRD_DIR=RAILS_ROOT + "/db/rrd"
INTERVAL=300

def rrd_create(path, time)
  RRD::Wrapper.create '--start', (time - 60.seconds).strftime("%s"), path, 
    "-s", "#{INTERVAL.to_s}",
    # max = 1*1024*1024*1024*600 = 1Gbit/s * 600s
    "DS:down_prio:DERIVE:600:0:644245094400",
    "DS:down_dfl:DERIVE:600:0:644245094400",
    "DS:up_prio:DERIVE:600:0:644245094400",
    "DS:up_dfl:DERIVE:600:0:644245094400",
    #(24x60x60/300)*30dias
    "RRA:AVERAGE:0.5:1:8640",
    #(24x60x60x30/300)*12meses
    "RRA:AVERAGE:0.5:30:3456",
    #(24x60x60x30x12/300)*10años
    "RRA:AVERAGE:0.5:360:2880"
end

def rrd_update(o, time, down_prio, down_dfl, up_prio, up_dfl)
  rrd_path = RRD_DIR + "/#{o.class.name}.#{o.id.to_s}.rrd"
  rrd_create(rrd_path, time) unless File.exists?(rrd_path)
  RRD::Wrapper.update rrd_path, "-t", "down_prio:down_dfl:up_prio:up_dfl", "#{time.strftime("%s")}:#{down_prio}:#{down_dfl}:#{up_prio}:#{up_dfl}"
  #puts "#{o.klass.number.to_s(16)} #{rrd_path} #{time.strftime("%s")}:#{down_prio}:#{down_dfl}:#{up_prio}:#{up_dfl}"
end

def tc_class(iface, provider=false)
  karray={}
  klass=nil
  io = IO.popen("/sbin/tc -s class show dev #{iface}", "r")
  io.each do |line|
    #puts line
    if (line =~ /class htb \w+:(\w*)/) != nil
      #puts "class = #{$~[1]}"
      klass = $~[1] 
    elsif (line =~ /Sent (\d+) /) != nil
      #puts "sent = #{$~[1]}"
      karray[klass] = $~[1] if klass
    end
  end
  io.close
  karray
end

time = Time.now
client_up = tc_class(IFB_UP)
client_down = tc_class(IFB_DOWN)
Contract.all.each do |c|
  rrd_update c, time, client_down[c.class_prio2_hex], client_down[c.class_prio3_hex], client_up[c.class_prio2_hex], client_up[c.class_prio3_hex]
end

ProviderGroup.enabled.each do |pg|
  pg_up = pg_down = 0
  pg.providers.enabled.each do |p| 
    p_up = File.open("/sys/class/net/#{p.interface.name}/statistics/tx_bytes").read.chomp rescue 0
    p_down = File.open("/sys/class/net/#{p.interface.name}/statistics/rx_bytes").read.chomp rescue 0
    rrd_update p, time, p_down, 0, p_up, 0
    pg_up += p_up.to_i
    pg_down += p_down.to_i
  end
  rrd_update pg, time, pg_down, 0, pg_up, 0
end

Interface.all.each do |i|
  up = File.open("/sys/class/net/#{i.name}/statistics/tx_bytes").read.chomp rescue 0
  down = File.open("/sys/class/net/#{i.name}/statistics/rx_bytes").read.chomp rescue 0
  rrd_update i, time, down, 0, up, 0
end
