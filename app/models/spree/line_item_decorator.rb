# encoding: utf-8

Spree::LineItem.class_eval do
  include ActionView::Helpers::NumberHelper

  # "ProduktID: 3 Rotwurst (Schwein 1) 1 Glas / 200g 1 x 3,50 EUR = 3,50 EUR"
  def to_csv

    # If this product has a variant called weight, we have to deal with this separately
    if weight_option?
      "ProduktID: #{variant.product.id} #{variant.product.name} (#{variant.options_presentation}) #{product.container} / #{net_weight}g #{quantity} x #{number_to_currency(Spree::Money.new(price).money, unit: 'EUR')} = #{number_to_currency(Spree::Money.new(price * quantity).money, unit: 'EUR')}"
    else
      "ProduktID: #{variant.product.id} #{variant.product.name} (#{variant.options_presentation}) #{product.container} / #{product.net_weight}g #{quantity} x #{number_to_currency(Spree::Money.new(price).money, unit: 'EUR')} = #{number_to_currency(Spree::Money.new(price * quantity).money, unit: 'EUR')}"
    end
  end

  def weight_option?
    variant.product.option_types.any?{ |ot| ot.name == 'weight' }
  end

  def net_weight
    ot = Spree::OptionType.find_by_name('weight')
    ov = variant.option_values.where(option_type_id: ot.id).try(:first)
    ov.name
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

