all: install start

install:
	@bundle install

start: install
	@bundle exec sidekiq \
		-C ./config/sidekiq.yml \
		-r ./config/app.rb || true
