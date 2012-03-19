module EmailHelper

  # Access the list of emails we've read and cached
  def emails
    EmailCollection
  end

  # Parse the email body into an object
  def email_body(body)
    EmailBody.new(body)
  end

  class EmailCollection
    class << self
      def email
        @email ||= {}
      end

      # Connect to the INBOX
      def qa_inbox(model)
        WatirmarkEmail::QAMail.new(email_address(model) )
      end

      # Return an email if we've seen it
      def found_email(model)
        email[model.__name__]
      end

      # Read the contents of an email, cache it and delete the email
      def read_email(model, subject, timeout=30)
        email_content = qa_inbox(model).get_email_text(["SUBJECT", subject, "TO", model.email], timeout)
        email[model.__name__] = EmailBody.new(email_content)
      end

      def log_email(model)
        puts "Email Received"
        puts email[model.__name__].body.inspect
      end

      # Access a cached copy of an email
      def [](model)
        email[model.__name__]
      end

      # Remove our cached copy of the email
      def delete(model)
        email[model.__name__] = nil
      end

      # Format the email address so we're always referring to the qasendmail domain
      def email_address(model)
        model.email.gsub(/\+.+/,'').gsub(/@.+/, '@qasendmail.corp.convio.com')
      end
    end
  end

  class EmailLink
    attr_accessor :href, :text

    def initialize(doc)
      @href = doc['href']
      @text = doc.content
    end
  end

  class EmailBody
    attr_accessor :doc, :body

    def initialize(body)
      @body = body
      @doc = ::Nokogiri::HTML.parse body
    end

    def links
      unless @links
        @links = []
        @doc.xpath('//a').each do |link|
          @links << EmailLink.new(link)
        end
      end
      @links
    end

    def link(how, matcher)
      links.each do |link|
        case how
          when :text
            return link if /#{matcher}/.matches link.text
          when :href
            return link if /#{matcher}/.matches link.href
        end
      end
      return nil
    end

    def inspect
      @doc.to_s
    end

  end
end


