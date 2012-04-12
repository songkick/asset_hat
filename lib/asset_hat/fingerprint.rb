require 'digest/sha1'

module AssetHat
  # Methods for determining the alphanumeric fingerprint of a code snippet.
  # This fingerprint changes along with the code, but doesn't necessarily
  # identify that code uniquely.
  #
  # Useful for busting browser caches whenever code changes.
  module Fingerprint
    class << self
      attr_accessor :fingerprints #:nodoc:
    end

    # Accepts an arbitrary string (e.g., of raw CSS/JS), and returns the
    # alphanumeric fingerprint for that string.
    def self.for_string(string)
      Digest::SHA1.hexdigest(string)[0..6]
    end

    # Accepts the path to a file in the local filesystem, and returns the
    # alphanumeric fingerprint for the contents of that file.
    def self.for_filepath(filepath)
      code = File.read(filepath)
      Fingerprint.for_string(code)
    end

    # Accepts the name and type (<code>:css</code> or <code>:js</code>) of a
    # bundle, and returns the alphanumeric fingerprint for that bundle.
    def self.for_bundle(bundle, type)
      type = type.to_sym

      # Return memoized fingerprint, if any
      @fingerprints ||= {}
      @fingerprints[type] ||= {}
      fingerprint = @fingerprints[type][bundle]
      return fingerprint if fingerprint.present?

      bundle_filepaths = AssetHat.bundle_filepaths(bundle, type)
      return nil unless bundle_filepaths.present?

      code = ''
      bundle_filepaths.each do |filepath|
        file_contents = File.read(filepath)
        code << file_contents
      end

      # Compute fingerprint based only on concatenated code
      all_code = bundle_filepaths.inject('') do |code, filepath|
        code << File.read(filepath)
      end
      fingerprint = Fingerprint.for_string(all_code)

      # Memoize result
      @fingerprints[type][bundle] = fingerprint

      fingerprint
    end

    # Precomputes and caches the alphanumeric fingerprints for all bundles.
    # Your web server process(es) should run this at boot to avoid overhead
    # during user runtime.
    def self.cache_fingerprints
      AssetHat::TYPES.each do |type|
        next if AssetHat.config[type.to_s].blank? ||
                AssetHat.config[type.to_s]['bundles'].blank?

        AssetHat.config[type.to_s]['bundles'].keys.each do |bundle|
          # Memoize fingerprint for this bundle
          AssetHat::Fingerprint.for_bundle(bundle, type) if AssetHat.cache?

          # Memoize fingerprints for each file in this bundle
          AssetHat.bundle_filepaths(bundle, type).each do |filepath|
            AssetHat::Fingerprint.for_filepath(filepath)
          end
        end
      end
    end

  end

end
