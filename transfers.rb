#!/usr/bin/env ruby

require 'csv'
require 'date'
require 'stripe'

# Fetches all transactions in a set of transfers.
# Useful for looking at transfers that include refunds out of the current month.

def cents_to_dollars(value)
  if value != 0
    val = value.to_s[0..-3] + "." + value.to_s[-2..-1]
    val.to_f
  else
    value
  end
end

Stripe.api_key = ENV['STRIPE_SECRET']
count = ENV['STX_COUNT'] || 50

puts "Starting to get all transfers (limit: #{count} STX_COUNT)"
transfers = Stripe::Transfer.all(limit: count)
puts "Fetched #{transfers.data.length}/#{transfers.count} transfers"

output_file = "transactions-all.csv"
puts "Writing to #{output_file}"

# TODO: Look at https://github.com/stripe/stripe-ruby/issues/130 for pagination issue.
# TODO: Switch to customers.auto_paging_each do |customer| for paging

total_transactions = 0

CSV.open(output_file, 'wb', row_sep: "\r\n") do |csv|
  csv << ['TransferID', 'TransactionID','Amount', 'Created', 'Currency', 'Customer', 'Description', 'Fee', 'Net', 'Type']
  transfers.each do |xfer|

    xfer_count = xfer.transactions.count

    puts "Fetching all transactions for #{xfer.id} (#{xfer_count} total)"
    transactions = xfer.transactions.all(
        :limit => xfer_count,
    )
    transactions.each do |t|
      csv << [xfer.id, t.id, cents_to_dollars(t.amount), Time.at(t.created), t.currency, t.customer_details, t.description, t.fee, t.net, t.type]
      total_transactions += 1
    end
  end
end

puts "Wrote #{total_transactions} total transactions"
puts "All done!"