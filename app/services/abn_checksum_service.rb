class AbnChecksumService
  class << self
    def valid?(abn)
      digits = abn.gsub(/\D/, '').chars.map(&:to_i)
      return false unless digits.size == 11

      digits[0] -= 1
      sum = digits.zip(Constants::Formats::WEIGHTS).map { |d, w| d * w }.sum
      (sum % 89).zero?
    end
  end
end
