
class String
  def titleize
    self.split.each { |x| x.capitalize! }.join(' ')
  end
  
  def sentence_case
    self.split('.').first.gsub(/\W/, ' ').split(/(\A[\d]*[^a-zA-Z])/).last
  end
end