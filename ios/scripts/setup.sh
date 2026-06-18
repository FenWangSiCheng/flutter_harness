# Install ruby using rbenv
ruby_version=`cat .ruby-version`
if [[ ! -d "$HOME/.rbenv/versions/$ruby_version" ]]; then
  rbenv install $ruby_version;
fi
# Install bunlder
gem install bundler:2.5.17
# Install all gems
bundle install --path vendor/bundle
bundle exec fvm flutter precache --ios
# Install all pods
bundle exec pod install --repo-update
