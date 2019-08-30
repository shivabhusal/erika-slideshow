class Erika
  class Audio
    attr_accessor :full_path
    
    def initialize full_path: Erika::Config.audio
      @full_path = full_path
    end
  end
end