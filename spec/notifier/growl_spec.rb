# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)

describe Backup::Notifier::Growl do
  let(:model) { Backup::Model.new(:test_trigger, 'test label') }
  let(:notifier) do
    Backup::Notifier::Growl.new(model) do |prowl|
      prowl.application = 'application'
      prowl.sticky = true
    end
  end

  it 'should be a subclass of Notifier::Base' do
    Backup::Notifier::Growl.
      superclass.should == Backup::Notifier::Base
  end

  describe '#initialize' do
    after { Backup::Notifier::Growl.clear_defaults! }

    it 'should load pre-configured defaults through Base' do
      Backup::Notifier::Growl.any_instance.expects(:load_defaults!)
      notifier
    end

    it 'should pass the model reference to Base' do
      notifier.instance_variable_get(:@model).should == model
    end

    context 'when no pre-configured defaults have been set' do
      it 'should use the values given' do
        notifier.application.should == 'application'
        notifier.sticky.should be_true

        notifier.on_success.should == true
        notifier.on_warning.should == true
        notifier.on_failure.should == true
      end

      it 'should use default values if none are given' do
        notifier = Backup::Notifier::Growl.new(model)
        notifier.application.should == 'backup'
        notifier.sticky.should be_nil

        notifier.on_success.should == true
        notifier.on_warning.should == true
        notifier.on_failure.should == true
      end
    end # context 'when no pre-configured defaults have been set'

    context 'when pre-configured defaults have been set' do
      before do
        Backup::Notifier::Growl.defaults do |n|
          n.application = 'default_app'
          n.sticky = true

          n.on_success = false
          n.on_warning = false
          n.on_failure = false
        end
      end

      it 'should use pre-configured defaults' do
        notifier = Backup::Notifier::Growl.new(model)
        notifier.application.should == 'default_app'
        notifier.sticky.should be_true

        notifier.on_success.should == false
        notifier.on_warning.should == false
        notifier.on_failure.should == false
      end

      it 'should override pre-configured defaults' do
        notifier = Backup::Notifier::Growl.new(model) do |n|
          n.application = 'new_app'
          n.sticky = false

          n.on_success = false
          n.on_warning = true
          n.on_failure = true
        end

        notifier.application.should == 'new_app'
        notifier.sticky.should be_false

        notifier.on_success.should == false
        notifier.on_warning.should == true
        notifier.on_failure.should == true
      end
    end # context 'when pre-configured defaults have been set'
  end # describe '#initialize'

  describe '#notify!' do
    context 'when status is :success' do
      it 'should send Success message' do
        notifier.expects(:send_message).with(
          '[Backup::Success] test label (test_trigger)'
        )
        notifier.send(:notify!, :success)
      end
    end

    context 'when status is :warning' do
      it 'should send Warning message' do
        notifier.expects(:send_message).with(
          '[Backup::Warning] test label (test_trigger)'
        )
        notifier.send(:notify!, :warning)
      end
    end

    context 'when status is :failure' do
      it 'should send Failure message' do
        notifier.expects(:send_message).with(
          '[Backup::Failure] test label (test_trigger)'
        )
        notifier.send(:notify!, :failure)
      end
    end
  end # describe '#notify!'

  describe '#send_message' do
    it 'should send the given message' do
      client = mock
      Growl.expects(:new).returns(client)
      Growl.expects(:installed?).returns(true)
      client.expects(:message=).with('a message')
      client.expects(:name=).with('application')
      client.expects(:sticky!)
      client.expects(:run)

      notifier.send(:send_message, 'a message')
    end
  end

end
