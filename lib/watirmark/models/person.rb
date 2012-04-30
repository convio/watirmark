module Watirmark
  module Model
    module Person
      include Simple

      def __first_name__
        "first_#{uuid}"
      end

      def __last_name__
        "last_#{uuid}"
      end

      def __user_name__
        "user_#{uuid}"
      end

      def __email_address__
        "#{__email_prefix__}+#{uuid}@#{__email_suffix__}"
      end

      def __email_prefix__
        Watirmark::Configuration.instance.email || "devnull"
      end

      def __email_suffix__
        "qasendmail.corp.convio.com"
      end

      def __address__
        {
            :street1 => '3405 Mulberry Creek Dr',
            :city => 'Austin',
            :state => 'TX',
            :zip => '78732',
            :country => 'United States',
        }
      end

      def __credit_card__
        {
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
