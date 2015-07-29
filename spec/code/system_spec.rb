require "code/system"

module Code
  module System
    describe "#prompt" do
      it "should print the prompt, then ask for and return the input" do
        expect(System).to receive(:print).with("Test: ").and_return("")
        expect(System).to receive(:gets).and_return("test_user")
        input = System.prompt "Test"
        expect(input).to eq "test_user"
      end

      it "should strip special characters from the input" do
        allow(System).to receive(:print).and_return("")
        allow(System).to receive(:gets).and_return("test\n")

        input = System.prompt ""
        expect(input).to eq "test"
      end
    end

    describe "#prompt_hidden" do
      it "should print the prompt, ask for input without echo, print a new line and return the input" do
        expect(System).to receive(:print).with("Test: ").and_return("")
        expect(System).to receive(:noecho_gets).and_return("test_pass")
        expect(System).to receive(:puts).and_return("")
        input = System.prompt_hidden "Test"
        expect(input).to eq "test_pass"
      end

      it "should strip special characters from the input" do
        allow(System).to receive(:print).and_return("")
        allow(System).to receive(:noecho_gets).and_return("test\n")

        input = System.prompt_hidden ""
        expect(input).to eq "test"
      end
    end

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

    describe "#error" do
      it "calls abort with a red message" do
        expect(System).to receive(:abort)
        expect(System).to receive(:red).with("message")

        System.error "message"
      end
    end

    describe "#exec" do
      it "calls #puts with a green message, then executes the command using Kernel backtick" do
        expect(System).to receive(:puts)
        expect(System).to receive(:green).with("message")
        expect(System).to receive(:command_failed?).and_return(false)
        expect(System).to receive(:`)
        System.exec "message"
      end

      it "raises a CommandFailedError if command has failed, with red text" do
        allow(System).to receive(:puts)
        allow(System).to receive(:green)
        expect(System).to receive(:red)
        expect(System).to receive(:command_failed?).and_return(true)
        expect(System).to receive(:`)
        expect { System.exec "message" }.to raise_error System::CommandFailedError
      end
    end

    describe "#call" do
      it "calls #exec with git prepended to the command script" do
        expect(System).to receive(:exec).with("git some command")
        System.call "some command"
      end
    end
  end
end