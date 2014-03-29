node[:deploy].each do |app_slug_name, app_deploy|
  deploy app_deploy[:deploy_to] do
    before_migrate do
      # Check if domain name is set
      if app_deploy[:domains].length == 0
        Chef::Log.debug("Skipping Meteor installation of #{app_slug_name}. App does not have any domains configured.")
        next
      end

      # Using the first domain to create ROOT_URL for Meteor
      domain_name = app_deploy[:domains][0]

      if app_deploy[:ssl_support]
        protocol_prefix = "https://"
      else
        protocol_prefix = "http://"
      end

      tmp_dir = "/tmp/meteor_tmp"
      repo_dir = "#{app_deploy[:deploy_to]}/shared/cached-copy"
      mongo_url = node[:apps_config][app_slug_name][:mongo_url]

      bash "Deploy Meteor" do
        code <<-EOH
        # Reset the Meteor temp directory
        rm -rf #{tmp_dir}
        mkdir -p #{tmp_dir}

        # Move files to the temp directory
        cp -R #{repo_dir}/. #{tmp_dir}

        # Create a Meteor bundle
        cd #{tmp_dir}
        mrt install
        meteor bundle bundled_app.tgz
        tar -xzf bundled_app.tgz

        # Copy the bundle folder into the release directory
        cp -R #{tmp_dir}/bundle #{release_path}
        chown -R deploy:www-data #{release_path}/bundle

        # cd into release directory
        cd #{release_path}

        # OpsWorks expects a server.js file
        echo 'process.env.ROOT_URL  = "#{protocol_prefix}#{domain_name}";' > ./server.js
        echo 'process.env.MONGO_URL = "#{mongo_url}";' >> ./server.js
        echo 'process.env.PORT = 80; require("./bundle/main.js");' >> ./server.js
        chown deploy:www-data ./server.js

        # Remove the temp directory
        rm -rf #{tmp_dir}
        EOH
      end

      # Run user provided callback file
      run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
    end
  end
end
