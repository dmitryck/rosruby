#!/usr/bin/env ruby

require 'ros'
ROS::load_manifest("rosruby_actionlib")
require 'test/unit'
require 'actionlib/action_server'
require 'actionlib_tutorials/FibonacciAction'

class TestActionServer < Test::Unit::TestCase
  def test_hoge
    node = ROS::Node.new('/test_action_server')
    server = Actionlib::ActionServer.new(node, '/fibonacci',
                                         Actionlib_tutorials::FibonacciAction)
    server.start do |goal, handle|
      p 'goal has come'
      p goal.order
      result = Actionlib_tutorials::FibonacciResult.new
      result.sequence = [0, 1, 2]
      handle.set_succeeded(result)
    end
    node.spin
  end
end
