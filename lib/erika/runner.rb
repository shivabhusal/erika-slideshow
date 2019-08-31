class Erika
  class Runner
    class << self
      def call(cmd)
        puts '-' * 100
        puts cmd
        puts '-' * 100
        stdo, stde, process = Open3.capture3(cmd)
        _display_error(stde) if stde.length > 0
        stdo
      end
      
      private
        def _display_error(stde)
          puts ('-' * 47) + ' Error ' + ('-' * 46)
          puts stde
          puts '-' * 100
        end
    end
  end
end