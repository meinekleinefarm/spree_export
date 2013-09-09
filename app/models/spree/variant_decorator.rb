# encoding: utf-8

Spree::Variant.class_eval do

  def options_presentation
    values = self.option_values.joins(:option_type).order("#{Spree::OptionType.table_name}.position asc")

    values.map! do |ov|
      ov.presentation
    end

    values << "Schwein X" if values.empty?

    values.to_sentence({ :words_connector => ", ", :two_words_connector => ", " })
  end

end
