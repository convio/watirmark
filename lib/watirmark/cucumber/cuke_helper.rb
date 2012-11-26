module CukeHelper
  include 'watirmark/models/cucumber_helper'

  def log
    Watirmark::Configuration.instance.logger
  end

  def eval_keywords(hash)
    hash.each do |key, value|
      hash[key] = format_value(value)
    end
    hash
  end

  # when the input is an array, eval each element
  def eval_raw_record(row)
    row.each_index do |col|
      row[col] = format_value(row[col])
    end
    row
  end

  # calls the models method if of the pattern <name>.method
  def call_model_methods(hash)
    hash.each { |key, value| hash[key] = eval(value[1..value.length]) if value[0, 1].eql?("=") }
    hash
  end

  # return {:foo=1, :bar=2} from {'foo' =>1, 'bar' =>2}
  def colonize(hash)
    newhash = {}
    hash.each { |k, v| newhash[k.to_sym] = v }
    newhash
  end

  # returns [{:foo=1, :bar=2}, {:foo=3, :bar=4}] list of hash records
  # from table table where first row headers are keys and each row values
  # | foo | bar |
  # | 1   | 2   |
  # | 3   | 4   |
  def hash_record_list table
    table.map_headers! { |h| h.to_sym }
    records = table.hashes
    records.map { |record| eval_keywords(record) }
  end

  # returns {:foo=1, :bar=2}  hash record
  # from a key, value 2 column table
  # | foo | 1 |
  # | bar | 2 |
  def hash_record table
    colonize eval_keywords(table.rows_hash)
  end

  # returns .raw but still handles eval-ing the keywords
  def raw_record table
    table.raw.map { |record| eval_raw_record(record) }
  end

  #Given a list of keys or strings (call it key), return a string composed of
  #record_hash[key] or the string is key isn't really a key.  Yea, screwy I know
  def compose_string_from(record_hash, key_list)
    result = ''
    key_list.each do |key|
      if record_hash[key]
        result += record_hash[key]
      elsif key.is_a? String
        result += key
      end
    end
    result
  end

# Allows expected values for a cucumber table field to be different
# based on whether you are using Service Bus or DataSync. Use case is
# for a bug in DataSync that was not replicated in Service Bus
# In this example: DataSync incorrectly assigns 'Donation' and Service
# Bus correctly assigns 'TeamRaiser Gift' to transaction type field
#  # VERIFY ---------------+-------------------------------------------+
#  | accountname           | Tr01_Hellraiser Eventdonor Household      |
#  | type                  | Individual Gift                           |
#  | transactiontype       | =syncmode('TeamRaiser Gift','Donation')   |
  def syncmode(expected_bus, expected_datasync)
    if ENV['SYNCMODE'] == 'DataSync'
      expected_datasync
    else
      expected_bus
    end
  end

# if a block provided raises VerificationException we verify again
# this method acts as a gateway to prevent false negatives in testing CRM objects that we expect to change their values after being
# updated by the service bus
# motivation:
# After serivce bus sends a message to a CRM it takes a while sometimes for the updates to the object to occur.
# When we verify the state of the object we may still look at old values.
# We want to introduce a pooling mechanism that would re-verify one or more times after a duration of time
# and only fail after the specified count of tries.
# usage:
#   verify_failure { controller.verify } #=>  provide block that can fail with VerificationException
  def verify_failure(tries_count=6, seconds_between_tries=30)
    counter = 0
    loop do
      counter += 1
      begin
        yield
      rescue Watirmark::VerificationException => e
        Watirmark.logger.warn "*** reverifying failure: #{e}"
        raise e if counter >= tries_count
        sleep seconds_between_tries
      else
        break
      end
    end
  end

# given a hash and list of keys, make the values into a float if they exist
# FIXME: this is a work around until the Cucumber tests use a new matcher
# in convio_watir by making strings into floats
#
# record={:amountreceived => "10.00", :probability => "100"}
# floatify(record, [:amountreceived, :probability])
# changes record into
# record={:amountreceived => 10.0, :probability => 100.0}
  def floatify(record_hash, key_list)
    key_list.each do |key|
      record_hash[key] = record_hash[key].to_f if record_hash[key]
    end
    record_hash
  end

# merges sequentially a list of hashes
  def multimerge *hashes
    hashes.inject({}) { |memo, hash| hash.nil? ? memo : memo.merge(hash) }
  end

  def create_ts(with_separators=true)
    if with_separators
      Time.now.strftime "%Y:%m:%d:%H:%M:%S"
    else
      Time.now.strftime "%Y%m%d%H%M%S"
    end
  end

end



