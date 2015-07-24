require "code/config"
require_relative '../support/uses_file_system'

module Code
  describe Config do
    include UsesFileSystem

    describe "#get" do

      context "when .codeconfig doesn't exist" do
        with_empty_tmp_folder

        it "creates a .codeconfig file" do
          expect(File.exists? ".codeconfig").to be false
          allow(System).to receive (:prompt)
          Config.get "random-property"
          expect(File.exists? ".codeconfig").to be true
        end
      end

      context "with an existing .codeconfig file" do

        context "when config property doesn't exist in the file" do
          with_file_and_content(".codeconfig", "")

          it "should prompt the user for the property value" do
            expect(System).to receive(:prompt).with("Unknown")
            Config.get "property"
          end

          it "should return the value the user has provided" do
            allow(System).to receive(:prompt).with("Unknown").and_return("test-value")
            expect(Config.get "property").to eq ("test-value")
          end

          it "should store the provided value into the file" do
            allow(System).to receive(:prompt).with("Unknown").and_return("test-value")
            Config.get "property"
            file_content = File.read ".codeconfig"
            expect(file_content.strip).to eq "property = \"test-value\""
          end
        end

        context "when config property does exist" do
          with_file_and_content(".codeconfig", "property = value")

          it "should not prompt the user for the property value" do
            expect(System).not_to receive(:prompt)
            Config.get "property"
          end

          it "should return the stored property value" do
            expect(Config.get "property").to eq "value"
          end
        end
      end

    end
  end
end