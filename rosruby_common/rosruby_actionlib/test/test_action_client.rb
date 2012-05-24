#!/usr/bin/env ruby

require 'ros'
ROS::load_manifest("rosruby_actionlib")
require 'test/unit'
require 'actionlib/action_client'
require 'actionlib_tutorials/FibonacciAction'

class TestActionClient < Test::Unit::TestCase
  def test_hoge
    node = ROS::Node.new('/test_action_client')
    client = Actionlib::ActionClient.new(node, '/fibonacci', Actionlib_tutorials::FibonacciAction)
    goal = Actionlib_tutorials::FibonacciGoal.new
    goal.order = 5
    sleep 1
    if client.wait_for_server
      handle = client.send_goal(goal)
      p result = handle.wait_for_result(20.0)
      if result
        p result.sequence
      end
    end
  end
end
