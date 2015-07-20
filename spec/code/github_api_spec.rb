require 'code/github_api'

module Code
  describe GitHubAPI do
    let(:api) { GitHubAPI.new }

    describe '#ensure_authorized' do

      context 'when system is authorized' do
        before do
          allow(api).to receive(:authorized?).and_return(true)
        end

        it 'should not call #authorize' do
          expect(api).not_to receive(:authorize)
          expect(api).not_to receive(:prompt)

          api.ensure_authorized
        end
      end

      context 'when system is not authorized' do
        before do
          allow(api).to receive(:authorized?).and_return(false)
        end

        it 'should call #authorize' do
          expect(api).to receive(:authorize)
          expect(api).to receive(:prompt).twice

          api.ensure_authorized
        end
      end
    end
  end
end