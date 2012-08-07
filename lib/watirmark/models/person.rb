module Watirmark
  module Model
    class Person < Base

      def self.inherited(subclass)
        subclass.default.firstname        {"first_#{uuid}"}
        subclass.default.lastname         {"last_#{uuid}"}
        subclass.default.username         {"user_#{uuid}"}
        subclass.default.password         {"password"}
        subclass.default.reminder_hint    {"hint"}
        subclass.meta_def :email_prefix do
          Watirmark::Configuration.instance.email || "devnull"
        end
        subclass.meta_def :email_suffix do
          "qasendmail.corp.convio.com"
        end
        subclass.default.email            {"#{subclass.email_prefix}+#{uuid}@#{subclass.email_suffix}"}

        # TODO: should move to add_model address, add_model credit_card
        # but will need some refactor of controllers to handle properly
        subclass.default.street1          {'3405 Mulberry Creek Dr'}
        subclass.default.city             {'Austin'}
        subclass.default.state            {'TX'}
        subclass.default.zip              {'78732'}
        subclass.default.country          {'United States'}

        subclass.default.creditcard       {"Visa"}
        subclass.default.cardnumber       {"4111 1111 1111 1111"}
        subclass.default.verificationcode {111}
        subclass.default.expmonth         {12}
        subclass.default.expyear          {Date::today.strftime("%Y")}
      end
    end
  end
end
