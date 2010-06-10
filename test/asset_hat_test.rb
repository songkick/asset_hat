require 'test_helper'

class AssetHatTest < ActiveSupport::TestCase
  context 'AssetHat' do
    context 'with caching enabled' do
      setup do
        flexmock(AssetHat).should_receive(:cache? => true)
      end

      should 'memoize config' do
        AssetHat.config
        flexmock(YAML).should_receive(:load).never
        3.times { AssetHat.config }
      end
    end # context 'with caching enabled'

    context 'with caching disabled' do
      setup do
        flexmock(AssetHat).should_receive(:cache? => false)
      end

      should 'not memoize config' do
        AssetHat.config
        flexmock(YAML).should_receive(:load).times(3)
        3.times { AssetHat.config }
      end
    end # context 'with caching disabled'
  end # context 'AssetHat'

  context 'AssetHat::CSS' do
    should 'return path to minified file' do
      assert_equal  'foo/bar/baz.min.css',
                    AssetHat::CSS.min_filepath('foo/bar/baz.css')
    end

    should 'add image asset commit IDs' do
      commit_id = 111
      flexmock(AssetHat).should_receive(:last_commit_id => commit_id)
      flexmock(Rails).should_receive(:public_path => '')

      assert_equal  "p{background:url(/images/foo.png?#{commit_id})}",
                    AssetHat::CSS.add_asset_commit_ids(
                      'p{background:url(/images/foo.png)}')
    end

    should 'add .htc asset commit IDs' do
      commit_id = 111
      flexmock(AssetHat).should_receive(:last_commit_id => commit_id)
      flexmock(Rails).should_receive(:public_path => '')

      assert_equal  "p{background:url(/htc/iepngfix.htc?#{commit_id})}",
                    AssetHat::CSS.add_asset_commit_ids(
                      'p{background:url(/htc/iepngfix.htc)}')
    end

    should 'add image asset hosts' do
      asset_host = 'http://media%d.example.com'
      assert_match(
        /^p\{background:url\(http:\/\/media[\d]\.example\.com\/images\/foo.png\)\}$/,
        AssetHat::CSS.add_asset_hosts(
          'p{background:url(/images/foo.png)}', asset_host)
      )
    end

    should 'add .htc asset hosts' do
      asset_host = 'http://media%d.example.com'
      assert_match(
        /^p\{background:url\(http:\/\/media[\d]\.example\.com\/htc\/iepngfix.htc\)\}$/,
        AssetHat::CSS.add_asset_hosts(
          'p{background:url(/htc/iepngfix.htc)}', asset_host)
      )
    end
  end # context 'AssetHat::CSS'

  context 'AssetHat::JS' do
    should 'return path to minified file' do
      assert_equal  'foo/bar/baz.min.js',
                    AssetHat::JS.min_filepath('foo/bar/baz.js')
    end
  end # context 'AssetHat::JS'

  should "return a bundle's filenames" do
    assert_equal  %w[css-file-1-1 css-file-1-2 css-file-1-3],
                  AssetHat.bundle_filenames('css-bundle-1', :css)
  end

  should "return a bundle's filepaths" do
    expected = [1,2,3].map { |i| "public/stylesheets/css-file-1-#{i}.css" }
    assert_equal expected, AssetHat.bundle_filepaths('css-bundle-1', :css)
  end
end