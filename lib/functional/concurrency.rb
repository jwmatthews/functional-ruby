require 'thread'
require 'timeout'

require 'functional/promise'

module Functional

  class Future

    attr_reader :state

    # Has the promise been fulfilled?
    # @return [Boolean]
    def fulfilled?() return(@state == :fulfilled); end

    # Is promise completion still pending?
    # @return [Boolean]
    def pending?() return(! fulfilled?); end

    def value(timeout = nil)
      if @mutex.nil?
        return @value
      elsif timeout.nil?
        return @mutex.synchronize { @value }
      else
        begin
          Timeout::timeout(timeout.to_f) {
            @mutex.synchronize { @value }
          }
        rescue Timeout::Error => ex
          return nil
        end
      end
    end

    alias_method :realized?, :fulfilled?
    alias_method :deref, :value

    def initialize(*args, &block)

      unless block_given?
        @state = :fulfilled
      else
        @state = :pending
        @mutex = Mutex.new
        @t = Thread.new do
          @mutex.synchronize do
            Thread.pass
            begin
              @value = block.call(*args)
            rescue Exception => ex
              # supress
            end
            @state = :fulfilled
          end
          @mutex = nil
        end
        @t.abort_on_exception = true
      end
    end
  end
end

module Kernel

  def future(*args, &block)
    return Functional::Future.new(*args, &block)
  end
  module_function :future

  def deref(future)
    if future.respond_to?(:deref)
      return future.deref
    else
      return nil
    end
  end

  def pending?(future)
    if future.respond_to?(:pending?)
      return future.pending?
    else
      return false
    end
  end

  def fulfilled?(future)
    if future.respond_to?(:fulfilled?)
      return future.fulfilled?
    else
      return false
    end
  end

  def realized?(future)
    if future.respond_to?(:realized?)
      return future.realized?
    else
      return false
    end
  end

  #def rejected?(future)
    #if future.respond_to?(:rejected?)
      #return future.rejected?
    #else
      #return false
    #end
  #end
end

#module Functional
  # p = Process.new{|receive| 'Bam!' }
  # # -or-
  # p = make {|receive| 'Bam!' }

  # p << 'Boom!' # send the message 'Boom!' to the process
  # x = nil
  # p >> x # retrieve the next message from the process

  # p.kill # stop the process and freeze it

  # http://www.ruby-doc.org/core-1.9.3/ObjectSpace.html
  #class Process

    #def initialize(&block)
      #raise ArgumentError.new('no block given') unless block_given?
      #ObjectSpace.define_finalizer(self, proc {|id| puts "Finalizer one on #{id}" })
    #end

    #def <<(send)
    #end

    #def >>(receive)
    #end
  #end
#end

module Kernel

  # Spawn a single-use thread to run the given block.
  # Supresses exceptions.
  #
  # @param args [Array] zero or more arguments for the block
  # @param block [Proc] operation to be performed concurrently
  #
  # @return [true,false] success/failre of thread creation
  #
  # @note Althought based on Go's goroutines and Erlang's spawn/1,
  # Ruby has a vastly different runtime. Threads aren't nearly as
  # efficient in Ruby. Use this function sparingly.
  #
  # @see http://golang.org/doc/effective_go.html#goroutines
  # @see https://gobyexample.com/goroutines
  def go(*args, &block)
    return false unless block_given?
    t = Thread.new(*args){ |*args|
      Thread.pass
      self.instance_exec(*args, &block)
    }
    t.abort_on_exception = false
    return t.alive?
  end
  module_function :go

  ## called `spawn` in Erlang, but Ruby already has a spawn function
  ## called `make` in Go
  #def make(&block)
    #return Functional::Process.new(&block)
  #end
  #module_function :make
end
