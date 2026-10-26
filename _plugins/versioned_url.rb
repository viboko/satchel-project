# frozen_string_literal: true

require "digest"

module Satchel
  # Adds a fingerprint of a file's contents to its URL:
  #
  #   {{ '/assets/videos/demo.mp4' | versioned_url }}
  #   => /assets/videos/demo.mp4?v=3f1c9a0b2e
  #
  # When a file is replaced, its URL changes with it, so a browser never
  # mixes what it cached of the old file with the new one. That matters most
  # for video, which browsers fetch and cache in pieces: a replaced video at
  # an unchanged URL can stall partway through.
  module VersionedUrlFilter
    def versioned_url(path)
      site = @context.registers[:site]
      file = File.join(site.source, path.to_s.delete_prefix("/"))
      raise ArgumentError, "versioned_url: no file at #{path}" unless File.file?(file)

      # relative_url is Jekyll's own filter, registered alongside this one.
      "#{relative_url(path)}?v=#{Digest::SHA256.file(file).hexdigest[0, 10]}"
    end
  end
end

Liquid::Template.register_filter(Satchel::VersionedUrlFilter)
