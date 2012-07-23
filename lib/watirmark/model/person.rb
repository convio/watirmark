module Watirmark
  module Model
    module Person
      include Watirmark::Model::Simple

      def self.included(klass)
        klass.extend ClassMethods
        klass.default.first_name {"first_#{uuid}"}
        klass.default.last_name  {"last_#{uuid}"}
        klass.default.user_name  {"user_#{uuid}"}
        klass.default.password   {"password"}

        klass.default.email_address {"#{email_prefix}+#{uuid}@#{email_suffix}"}
        klass.default.email_prefix Watirmark::Configuration.instance.email || "devnull"
        klass.default.email_suffix "qasendmail.corp.convio.com"

        klass.default.address = {
            :street1 => '3405 Mulberry Creek Dr',
            :city => 'Austin',
            :state => 'TX',
            :zip => '78732',
            :country => 'United States',
        }

        klass.default.credit_card = {
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
