# encoding: utf-8
require 'csv'
Spree::Order.class_eval do

  def self.completed_between(start_date, end_date)
    where(completed_at: start_date..end_date)
  end

  def self.paid_and_ready_to_ship
    where(payment_state: 'paid', shipment_state: 'ready')
  end

  def total_weight
    line_items.inject(0) do |weight, line_item|
      weight + (line_item.variant.weight ? (line_item.quantity * line_item.variant.weight.to_i) : 0)
    end
  end

  def net_weight
    line_items.inject(0) do |weight, line_item|
      weight + (line_item.product.net_weight ? (line_item.quantity * line_item.product.net_weight.to_i) : 0)
    end
  end

  def status
    shipment_status || payment_status || order_status
  end

  def order_status
    case state
    # The order process has been completed
    when "complete" then 'Neu'
    when "canceled", "awaiting_return", "returned" then 'Storniert'
    else
      # :cart, :address, :delivery, :payment, :confirm, :resumed
      # Order is in the process and can be ignored
      nil
    end
  end

  def payment_status
    case payments.first.try(:state)
    when "completed" then 'Wurde bezahlt'
    else
      nil
    end
  end

  def shipment_status
    case shipments.first.try(:state)
    when "shipped" then 'Wurde teilweise verschickt'
    else
      nil
    end
  end

  def billing_salutation
    'Herr/Frau'
  end

  def billing_first_name
    billing_address.try(:firstname)
  end

  def billing_last_name
    billing_address.try(:lastname)
  end

  def billing_zip
    billing_address.try(:zipcode)
  end

  def billing_city
    billing_address.try(:city)
  end

  def billing_street
    billing_address.try(:address1).gsub(/^([a-zäöüß\s\d.,-]+?)\s*([\d\s]+(?:\s?[-|+\/]\s?\d+)?\s*[a-z]?)?$/i,'\1') rescue nil
  end

  def billing_street_nr
    billing_address.try(:address1).gsub(/^([a-zäöüß\s\d.,-]+?)\s*([\d\s]+(?:\s?[-|+\/]\s?\d+)?\s*[a-z]?)?$/i,'\2') rescue nil
  end

  def billing_phone
    billing_address.try(:phone)
  end

  def shipping_salutation
    'Herr/Frau'
  end

  def shipping_first_name
    shipping_address.try(:firstname)
  end

  def shipping_last_name
    shipping_address.try(:lastname)
  end

  def shipping_city
    shipping_address.try(:city)
  end

  def shipping_zip
    shipping_address.try(:zipcode)
  end

  def shipping_street
    shipping_address.try(:address1).gsub(/^([a-zäöüß\s\d.,-]+?)\s*([\d\s]+(?:\s?[-|+\/]\s?\d+)?\s*[a-z]?)?$/i,'\1') rescue nil
  end

  def shipping_street_nr
    shipping_address.try(:address1).gsub(/^([a-zäöüß\s\d.,-]+?)\s*([\d\s]+(?:\s?[-|+\/]\s?\d+)?\s*[a-z]?)?$/i,'\2') rescue nil
  end

  def shipping_phone
    shipping_address.try(:phone)
  end

  def shipping_total
    shipment.try(:cost)
  end

  def price_products_total_with_tax
    Spree::Money.new(item_total).money
  end

  def price_products_total_tax
    line_items.map(&:tax_amount).sum
  end

  def price_products_total_without_tax
    price_products_total_with_tax - price_products_total_tax
  end

  def to_csv
    [
      id.to_s,
      status,
      billing_salutation,
      billing_first_name,
      billing_last_name,
      billing_zip,
      billing_city,
      billing_street,
      billing_street_nr,
      email,
      billing_phone,
      shipping_salutation,
      shipping_first_name,
      shipping_last_name,
      shipping_zip,
      shipping_city,
      shipping_street,
      shipping_street_nr,
      email,
      shipping_phone,
      'Nein',
      'Nein',
      'Nein',
      price_products_total_with_tax.to_f.to_s, #price_products_total_with_tax
      price_products_total_without_tax.to_f.to_s, #price_products_total_without_tax
      price_products_total_tax.to_f.to_s, #price_products_total_tax
      shipping_total.to_f.to_s, #price_shipping_total
      total.to_f.to_s, #price_total
      net_weight, #weight_total_in_gram
      total_weight, #weight_total_in_gram_brutto
      created_at.strftime("%Y-%m-%d"), #"2012-01-06"
      created_at.strftime("%H:%M:%S"), #"09:43:36"
      created_at.strftime("%Y-%m-%d"), #"2012-01-06"
      updated_at.strftime("%H:%M:%S"), #"09:43:36"
      line_items.map(&:to_csv).join(' ----------------------------- ')
    ]
  end

  # EXAMPLE:
  # id ;status         ;billing_salutation;billing_first_name;billing_last_name;billing_zip;billing_city;billing_street      ;billing_street_nr;billing_email  ;billing_phone  ;shipping_salutation;shipping_first_name;shipping_last_name;shipping_zip;shipping_city;shipping_street;shipping_street_nr;shipping_email;shipping_phone;shipping_address_is_billing_address;is_gift;newsletter_subscription;price_products_total_with_tax;price_products_total_without_tax;price_products_total_tax;price_shipping_total;price_total;weight_total_in_gram;weight_total_in_gram_brutto;created_at_date;created_at_time;updated_at_date;updated_at_time;cart_text;comment
  # "3";"Abgeschlossen";"Frau"            ;"Ursula"          ;"Enzian"         ;"99734"    ;"Nordhausen";"Stolberger Str. 83";""               ;"neru52@web.de";"03631/4735465";""                 ;""                 ;""                ;""          ;""           ;""             ;""                ;""            ;""            ;"Ja"                               ;"Nein" ;"Nein"                 ;"10.50"                      ;"8.51"                          ;"2.00"                  ;"5.90"              ;"16.40"    ;"600"               ;"0"                        ;"2012-01-06"   ;"09:43:36"     ;"2012-02-16"   ;"13:21:23"     ;"ProduktID: 3 Rotwurst (Schwein 1) 1 Glas / 200g 1 x 3,50 EUR = 3,50 EUR ----------------------------- ProduktID: 4 Sülze (Schwein 1) 1 Glas / 200g 2 x 3,50 EUR = 7,00 EUR ----------------------------- Zwischensumme: 10,50 EUR Verpackungs- und Lieferkosten: 5,90 EUR ----------------------------- Gesamt: 16,40 EUR ----------------------------- -----------------------------   Gemäß § 19 Umsatzsteuergesetz erheben wir als Kleinunternehmen keine Umsatzsteuer. "
  def self.export_csv
    CSV.generate(:col_sep => ';', :force_quotes => true) do |csv|
      csv << csv_headers
      all.each do |order|
        csv << order.to_csv
      end
    end
  end

  def self.csv_headers
    %w{id
      status
      billing_salutation
      billing_first_name
      billing_last_name
      billing_zip
      billing_city
      billing_street
      billing_street_nr
      billing_email
      billing_phone
      shipping_salutation
      shipping_first_name
      shipping_last_name
      shipping_zip
      shipping_city
      shipping_street
      shipping_street_nr
      shipping_email
      shipping_phone
      shipping_address_is_billing_address
      is_gift
      newsletter_subscription
      price_products_total_with_tax
      price_products_total_without_tax
      price_products_total_tax
      price_shipping_total
      price_total
      weight_total_in_gram
      weight_total_in_gram_brutto
      created_at_date
      created_at_time
      updated_at_date
      updated_at_time
      cart_text
      comment}
  end

end
