#!/usr/bin/env ruby

service_name = ARGV[0]
unless service_name
  $stderr.puts "USAGE: ./run-task.rb <service-name>"
  exit 1
end

require "docker"

class Docker::Service
  include Docker::Base

  def self.all(opts = {}, conn = Docker.connection)
    hashes = Docker::Util.parse_json(conn.get('/services', opts)) || []
    hashes.map { |hash| new(conn, hash) }
  end

  def version
    self.info["Version"]["Index"]
  end

  def update(opts)
    connection.post("/services/#{self.id}/update", {version: version}, body: opts.to_json)
  end

  def scale(replicas)
    spec = self.info["Spec"]
    spec["Mode"]["Replicated"]["Replicas"] = replicas
    # by setting ForceUpdate to version, we are sure
    # it is changed every time, effectively forcing an update
    spec["TaskTemplate"]["ForceUpdate"] = version
    update(spec)
  end
  
  private_class_method :new
end

# do what the following command is doing:
# docker service update --force --replicas 1 service1
# because we don't have docker client installed
Docker.validate_version!

Docker::Service.all(filters: {name: [service_name]}.to_json)[0].scale 1
puts "OK"
