module Watirmark
  module Model
    class Person < Simple

      def self.inherited(subclass)
        subclass.default.firstname     {"first_#{subclass.uuid}"}
        subclass.default.lastname      {"last_#{subclass.uuid}"}
        subclass.default.username      {"user_#{subclass.uuid}"}

        subclass.default.password       {"password"}
        subclass.default.reminder_hint  {"hint"}

        subclass.default.email_prefix   Watirmark::Configuration.instance.email || "devnull"
        subclass.default.email_suffix   "qasendmail.corp.convio.com"
        subclass.default.email          {"#{subclass.default.email_prefix}+#{subclass.uuid}@#{subclass.default.email_suffix}"}

        subclass.default.address = {
            :street1 => '3405 Mulberry Creek Dr',
            :city => 'Austin',
            :state => 'TX',
            :zip => '78732',
            :country => 'United States',
        }
        subclass.default.credit_card = {
            :creditcard => "Visa",
            :cardnumber => "4111 1111 1111 1111",
            :verificationcode => 111,
            :expmonth => 12,
            :expyear => Date::today.strftime("%Y")
        }
      end
    end
  end
end
