require 'code/system/os'

module Code
  module System
    describe OS do
      it "detects linux" do
        platform_string ="x86_64-linux"
        os_detector = OS.new(platform_string: platform_string)

        expect(os_detector.linux?).to be true
      end

      it "detects windows" do
        platform_string="i386-mingw32"
        os_detector = OS.new(platform_string: platform_string)

        expect(os_detector.windows?).to be true
      end

      it "detects unix" do
        platform_string ="x86_64-linux"
        os_detector = OS.new(platform_string: platform_string)

        expect(os_detector.unix?).to be true
      end

      it "detects osx" do
        platform_string = "x86_64-darwin14"
        os_detector = Code::System::OS.new(platform_string: platform_string)

        expect(os_detector.osx?).to be true
      end

      describe "#open_command" do
        it "returns 'open' for osx" do
          platform_string ="x86_64-darwin14"
          os_detector = OS.new(platform_string: platform_string)

          expect(os_detector.open_command).to eq "open"
        end

        it "returns 'xdg-open' for linux" do
          platform_string ="x86_64-linux"
          os_detector = OS.new(platform_string: platform_string)

          expect(os_detector.open_command).to eq "xdg-open"
        end
      end
    end
  end
end