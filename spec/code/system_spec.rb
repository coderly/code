require "code/system"

module Code
  module System

    describe "#open_in_browser" do
      it "calls #open for a fully defined URL" do
        expect(System).to receive(:open)

        System.open_in_browser("https://www.example.com")
      end

      it "doesn't call #open for an incomplete URL" do
        expect(System).not_to receive(:open)

        System.open_in_browser("www.example.com")
      end

      it "doesn't call #open for an invalid URL" do
        expect(System).not_to receive(:open)

        System.open_in_browser("000")
      end
    end
  end
end