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
          with_file_and_content(".codeconfig", "property = value\n")

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

    describe "#master_branch_name" do
      context "when there is no previously stored property value" do
        with_file_and_content(".codeconfig", "")
        let(:prompt_text) { "You didn't set the name of the master branch. What is it? (master)" }

        it "asks the user for the property value" do
          expect(System).to receive(:prompt).with prompt_text
          Config.master_branch_name
        end

        it "should return the value the user has provided" do
          allow(System).to receive(:prompt).with(prompt_text).and_return("test-value")

          expect(Config.master_branch_name).to eq ("test-value")
        end

        it "should store the provided value into the file" do
          allow(System).to receive(:prompt).with(prompt_text).and_return("test-value")
          Config.master_branch_name
          file_content = File.read ".codeconfig"
          expect(file_content.strip).to eq "master_branch = \"test-value\""
        end
      end

      context "when there is a previously stored property value" do
        with_file_and_content(".codeconfig", "master_branch = \"value\"\n")
          it "should not prompt the user for the property value" do
            expect(System).not_to receive(:prompt)
            Config.master_branch_name
          end

          it "should return the stored property value" do
            expect(Config.master_branch_name).to eq "value"
          end
      end
    end

    describe "#development_branch_name" do
      context "when there is no previously stored property value" do
        with_file_and_content(".codeconfig", "")
        let(:prompt_text) { "You didn't set the name of the development branch. What is it? (development)" }

        it "asks the user for the property value" do
          expect(System).to receive(:prompt).with prompt_text
          Config.development_branch_name
        end

        it "should return the value the user has provided" do
          allow(System).to receive(:prompt).with(prompt_text).and_return("test-value")

          expect(Config.development_branch_name).to eq ("test-value")
        end

        it "should store the provided value into the file" do
          allow(System).to receive(:prompt).with(prompt_text).and_return("test-value")
          Config.development_branch_name
          file_content = File.read ".codeconfig"
          expect(file_content.strip).to eq "development_branch = \"test-value\""
        end
      end

      context "when there is a previously stored property value" do
        with_file_and_content(".codeconfig", "development_branch = \"value\"\n")
          it "should not prompt the user for the property value" do
            expect(System).not_to receive(:prompt)
            Config.development_branch_name
          end

          it "should return the stored property value" do
            expect(Config.development_branch_name).to eq "value"
          end
      end
    end

    describe "#ready_label" do
      context "when there is no previously stored property value" do
        with_file_and_content(".codeconfig", "")
        let(:prompt_text) { "You didn't set the label used for marking the PR as ready. What is it? (awaiting review)" }

        it "asks the user for the property value" do
          expect(System).to receive(:prompt).with prompt_text
          Config.ready_label
        end

        it "should return the value the user has provided" do
          allow(System).to receive(:prompt).with(prompt_text).and_return("test-value")

          expect(Config.ready_label).to eq ("test-value")
        end

        it "should store the provided value into the file" do
          allow(System).to receive(:prompt).with(prompt_text).and_return("test-value")
          Config.ready_label
          file_content = File.read ".codeconfig"
          expect(file_content.strip).to eq "ready_label = \"test-value\""
        end
      end

      context "when there is a previously stored property value" do
        with_file_and_content(".codeconfig", "ready_label = \"value\"\n")
          it "should not prompt the user for the property value" do
            expect(System).not_to receive(:prompt)
            Config.ready_label
          end

          it "should return the stored property value" do
            expect(Config.ready_label).to eq "value"
          end
      end
    end

    describe "default" do
      with_file_and_content(".codeconfig", "")

      it "asks the user for the property value" do
        allow(System).to receive(:prompt).and_return("\n")

        expect(Config.master_branch_name).to eq "master"
        expect(Config.development_branch_name).to eq "development"
        expect(Config.ready_label).to eq "awaiting review"
      end
    end
  end
end
