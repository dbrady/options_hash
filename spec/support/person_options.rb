class PersonOptions < OptionsHash
  required :name, :level_of_schooling

  optional :height, :weight, default: ->{ 2 }
  optional :size,            &->{ (weight * height) * 100 }

  required :iq, :intelegence do |given_value|
    given_value.to_f * 0.50
  end
end
