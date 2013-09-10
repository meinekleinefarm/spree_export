# encoding: utf-8

Spree::LineItem.class_eval do
  include ActionView::Helpers::NumberHelper

  # "ProduktID: 3 Rotwurst (Schwein 1) 1 Glas / 200g 1 x 3,50 EUR = 3,50 EUR"
  def to_csv
    "ProduktID: #{variant.product.id} #{variant.product.name} (#{variant.options_presentation || 'Schwein x'}) #{product.container} / #{product.net_weight}g #{quantity} x #{number_to_currency(Spree::Money.new(price).money, unit: 'EUR')} = #{number_to_currency(Spree::Money.new(price * quantity).money, unit: 'EUR')}"
  end

  def tax_amount
    rate = variant.product.tax_category.tax_rates.first
    if rate.included_in_price
      # 100€ = 107%
      #   x€ =   7%
      #============
      # 100€ * 0.07 / 1.07 = 6,54€
      Spree::Money.new(price).money * rate.amount / (1.0+rate.amount) * quantity
    else
      # 100€ = 100%
      #   x€ =   7%
      #============
      # 100€ * 0.07 = 7
      Spree::Money.new(price).money * rate.amount * quantity
    end
  end
end

