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
        email[model.model_name]
      end

      # Read the contents of an email, cache it and delete the email
      def read_email(model, options_hash, timeout=30)
        search_array = options_hash_to_array(options_hash)
        email_content = qa_inbox(model).get_email_text(search_array, timeout)
        email[model.model_name] = EmailBody.new(email_content)
      end

      def options_hash_to_array(hash_of_search_params)
        Kernel.warn(self + ':>' + Kernel.__callee__ + ': Attempting hash-to-array conversion with object that is not a hash') unless hash_of_search_params.is_a?(Hash)
        converted_array = Array.new
        hash_of_search_params.each do | search_key, search_value |
          converted_array << search_key.to_s.upcase
          converted_array << search_value.to_s
        end
        converted_array
      end

      def read_email_from(model, from, timeout=30)
        Kernel.warn(self + ':>' + Kernel.__callee__ + ': This method is deprecated, please use read_email')
        read_email(model, {:from => from, :to => model.email}, timeout)
      end

      def read_email_replyto(model, from, timeout=30)
        qa_inbox(model).get_email_replyto(["FROM", from, "TO", model.email], timeout)
      end

      def read_email_subject_and_from(model, from, subject, timeout=30)
        Kernel.warn(self + ':>' + Kernel.__callee__ + ': This method is deprecated, please use read_email')
        read_email(model, {:from => from, :to => model.email, :subject => subject}, timeout)
      end

      def log_email(model)
        Watirmark.logger.info "Email Received"
        Watirmark.logger.info email[model.model_name].body.inspect
      end

      # Access a cached copy of an email
      def [](model)
        email[model.model_name]
      end

      # Remove our cached copy of the email
      def delete(model)
        email[model.model_name] = nil
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

  class EmailEnvelope
    attr_accessor :envelope

    def initialize(envelope)
      @envelope = envelope
      @from = envelope.from
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
      nil
    end

    def inspect
      @doc.to_s
    end

  end
end


