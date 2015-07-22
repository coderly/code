require "code/pull_request"
require "code/branch"

module Code
  describe PullRequest do
    # ToDO self.for_branch uses a GitHubAPI instance, which we can't inject
    # Not sure how to test that part

    it "properly maps the url and number properties" do
      pr = PullRequest.new(pull_request_info: { html_url: "example.com", number: 1 })
      expect(pr.url).to eq "example.com"
      expect(pr.number).to eq 1
    end

    describe "#add_label" do
      it "calls GitHubAPI#label_pr" do
        api = GitHubAPI.new
        pr = PullRequest.new(pull_request_info: { html_url: "example.com", number: 1 }, github_api: api)

        expect(api).to receive(:label_pr).with(pr, "label")
        pr.add_label("label")
      end
    end
  end
end
