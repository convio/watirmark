module Watirmark
  module Model
    class Person < Simple

      def self.inherited(subclass)
        subclass.default.first_name {"first_#{uuid}"}
        subclass.default.last_name  {"last_#{uuid}"}
        subclass.default.user_name  {"user_#{uuid}"}
        subclass.default.password   {"password"}

        subclass.default.email_address {"#{email_prefix}+#{uuid}@#{email_suffix}"}
        subclass.default.email_prefix Watirmark::Configuration.instance.email || "devnull"
        subclass.default.email_suffix "qasendmail.corp.convio.com"

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
