require 'code/github_api'

module Code
  describe GitHubAPI do
    let(:api) { GitHubAPI.new }

    describe "#ensure_authorized" do

      context 'when system is authorized' do
        before do
          allow(api).to receive(:authorized?).and_return(true)
        end

        it 'should not call #authorize' do
          expect(api).not_to receive(:authorize)
          expect(System).not_to receive(:prompt)
          expect(System).not_to receive(:prompt_text)

          api.ensure_authorized
        end
      end

      context 'when system is not authorized' do
        before do
          allow(api).to receive(:authorized?).and_return(false)
        end

        it 'should call #authorize' do
          expect(api).to receive(:authorize)
          expect(System).to receive(:prompt).once
          expect(System).to receive(:prompt_hidden).once

          api.ensure_authorized
        end
      end
    end

    describe "#authorize" do
      it "creates a client instance, uses it to create a token and stores it" do
        expect(api).to receive(:octokit_client_instance_from_basic_auth).with(username: "test_user", password: "test_pass").and_return("something")
        expect(api).to receive(:create_token).with("something").and_return("token")
        expect(System).to receive(:result).with("git config --global oauth.token token")
        api.send(:authorize, username: "test_user", password: "test_pass")
      end
    end
  end
end
