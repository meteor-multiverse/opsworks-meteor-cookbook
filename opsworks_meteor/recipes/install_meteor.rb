bash "Install Meteor" do
  user "root"
  code <<-EOF
  curl https://install.meteor.com | /bin/sh
  EOF
end
