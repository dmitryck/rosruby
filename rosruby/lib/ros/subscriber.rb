# ros/subscriber.rb
#
# License: BSD
#
# Copyright (C) 2012  Takashi Ogura <t.ogura@gmail.com>
#
require 'ros/topic'
require 'ros/tcpros/client'
require 'ros/slave_proxy'

module ROS

  # subscriber of ROS topic. This is created by ROS::Node#subscribe.
  # Please use proc block for callback method.
  # It uses ROS::TCPROS::Client for message transfer.
  # Subscription can be shutdown by this ROS::Subscriber#shutdown
  #   node = ROS::Node.new('/rosruby/sample_subscriber')
  #   sub = node.subscribe('/chatter', Std_msgs::String) do |msg|
  #     puts "message come! = \'#{msg.data}\'"
  #   end
  #   while node.ok?
  #     node.spin_once
  #     sleep(1)
  #   end
  class Subscriber < Topic

    # @param [String] caller_id caller id of this node
    # @param [String] topic_name name of this topic (String)
    # @param [Class] topic_type class of msg
    # @param [Proc] callback callback for this topic
    # @param [Boolean] tcp_no_delay use tcp no delay option or not
    def initialize(caller_id, topic_name, topic_type, callback=nil, tcp_no_delay=nil)
      super(caller_id, topic_name, topic_type)
      @callback = callback
      @tcp_no_delay = tcp_no_delay
    end

    # @return [Boolean] use tcp no delay option or not
    attr_reader :tcp_no_delay

    # @return [Proc] callback of this subscription
    attr_reader :callback

    ##
    # execute callback for all queued messages.
    # This is called by {Node#spin_once}.
    # It checks all queues of connections and callback for all messages.
    def process_queue #:nodoc:
      @connections.each do |connection|
        while not connection.msg_queue.empty?
          msg = connection.msg_queue.pop
          if @callback
            @callback.call(msg)
          end
        end
      end
    end

    ##
    # request topic to master and start connection with publisher.
    # @param [String] uri uri to connect
    # @return [TCPROS::Client] new connection
    def add_connection(uri) #:nodoc:
      publisher = SlaveProxy.new(@caller_id, uri)
      begin
        protocol, host, port = publisher.request_topic(@topic_name, [["TCPROS"]])
        if protocol == "TCPROS"
          connection = TCPROS::Client.new(host, port, @caller_id, @topic_name, @topic_type, uri, @tcp_no_delay)
          connection.start
        else
          puts "not support protocol: #{protocol}"
          raise "not support protocol: #{protocol}"
        end
        connection.id = "#{@topic_name}_in_#{@connection_id_number}"
        @connection_id_number += 1
        @connections.push(connection)
        return connection
      rescue
        puts "request fail"
        return false
      end
    end

    ##
    # data of connection. for slave API
    # @return [Array] connection data
    def get_connection_data
      @connections.map do |connection|
        [connection.id, connection.byte_received, 1]
      end
    end

    ##
    # connection information fro slave API
    # @return [Array] connection info
    def get_connection_info
      info = []
      @connections.each do |connection|
        info.push([connection.id, connection.target_uri, 'i', connection.protocol, @topic_name])
      end
      info
    end

    ##
    # user interface of shutdown this subscriber
    #
    def shutdown
      @manager.shutdown_subscriber(self)
    end
  end
end
