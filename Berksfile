chef_api :config
site :opscode

ENABLE_GRAPHITE = false

OPSCODE_COOKBOOK_DIR = "#{ENV['HOME']}/src/opscode-cookbooks"

cookbook "opscode-heimdall", git: "git@github.com:opscode-cookbooks/opscode-heimdall.git"
# cookbook "opscode-heimdall", path: "#{OPSCODE_COOKBOOK_DIR}/opscode-heimdall"
cookbook "opscode-pedant", git: "git@github.com:opscode-cookbooks/opscode-pedant.git"
# cookbook "opscode-pedant", path: "#{OPSCODE_COOKBOOK_DIR}/opscode-pedant"
cookbook "opscode-ruby", git: "git@github.com:opscode-cookbooks/opscode-ruby.git"
# cookbook "opscode-ruby", path: "#{OPSCODE_COOKBOOK_DIR}/opscode-ruby"

# This is only needed for local dev work
cookbook "opscode-dev-shim", git: "git@github.com:opscode-cookbooks/opscode-dev-shim.git"
#cookbook "opscode-dev-shim", path: "#{OPSCODE_COOKBOOK_DIR}/opscode-dev-shim"

if ENABLE_GRAPHITE
  # These are currently needed if you want to get graphite running locally
  DEV_VM_COOKBOOK_DIR = "#{ENV['HOME']}/src/opscode/opscode-dev-vm/cookbooks"
  cookbook "piab",     path: "#{DEV_VM_COOKBOOK_DIR}/piab"
  cookbook "estatsd",  path: "#{DEV_VM_COOKBOOK_DIR}/estatsd"
  cookbook "graphite", path: "#{DEV_VM_COOKBOOK_DIR}/graphite"
  cookbook "gunicorn", path: "#{DEV_VM_COOKBOOK_DIR}/gunicorn"
end
