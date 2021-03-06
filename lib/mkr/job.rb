# Capybara configuration
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, { js_errors: false, timeout: 5000 })
end

module Mkr
  class Job
    def initialize(user, action)
      @user = user
      @action = action
      @session = create_session
    end

    def execute
      Mkr.logger.info("Mkr::Job begin for #{@user.name}")
      with_signed_in_kot do
        record_clock
      end
      true
    ensure
      Mkr.logger.info("Mkr::Job end for #{@user.name}")
    end

    private

    def create_session
      Capybara::Session.new(:poltergeist).tap do |s|
        s.driver.headers = {
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36'
        }
      end
    end

    def with_signed_in_kot
      visit_kot

      begin
        sign_in

        yield
      ensure
        clear_session
      end
    end

    def visit_kot
      @session.visit('https://s3.kingtime.jp/independent/recorder/personal/')
      Mkr.logger.success('Visit `s3.kingtime.jp`')
    end

    def sign_in
      @session.within('#modal_window') do
        @session.find('#id').set(@user.id)
        @session.find('#password').set(@user.pw)
        @session.within('.btn-control-outer') { @session.find('.btn-control-inner').click }
        Mkr.logger.success('Sign in')
      end
    rescue Capybara::ElementNotFound => e
      Mkr.logger.error(e)
    end

    def clear_session
      @session.reset!
      Mkr.logger.success('Clear session')
    end

    def record_clock
      @session.within('ul#buttons') do
        @session.find(record_selector).click
        Mkr.logger.success("Record clock for `:#{@action}`")
      end
    end

    def record_selector
      case @action
      when :punch_in
        '.record-btn-inner.record-clock-in'
      when :punch_out
        '.record-btn-inner.record-clock-out'
      end
    end
  end
end
