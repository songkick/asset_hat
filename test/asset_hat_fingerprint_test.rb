require 'test_helper'

class AssetHatHelperTest < ActionView::TestCase
  context 'for_string' do
    should 'generate a 7 character fingerprint' do
      fingerprint = AssetHat::Fingerprint.for_string('test')
      assert_equal fingerprint.length, 7
    end
  end

  context 'for_filepath' do
    setup do
      @path = 'script.js'
    end

    context 'when the file does not exist' do
      setup do
        flexmock(File).should_receive(:file?).with(@path).and_return(false)
      end

      should 'return a blank fingerprint' do
        fingerprint = AssetHat::Fingerprint.for_filepath(@path)
        assert_equal fingerprint, ''
      end
    end

    context 'when the file exists' do
      setup do
        flexmock(File).should_receive(:file?).with(@path).and_return(true)
        flexmock(File).should_receive(:read).with(@path).and_return('example')
      end

      should 'read the file and generate a fingerprint' do
        fingerprint = AssetHat::Fingerprint.for_filepath(@path)
        assert_equal fingerprint.length, 7
      end
    end
  end

  context 'for_bundle' do
    setup do
      @bundle_name = 'exempli_gratia'
      @paths = ['foo', 'bar']
      flexmock(AssetHat).should_receive(:bundle_filepaths).
        with(@bundle_name, :js).and_return(@paths)
      flexmock(File).should_receive(:file?).and_return(true).by_default
      flexmock(File).should_receive(:read).with(@paths[0]).and_return('lorem')
      flexmock(File).should_receive(:read).with(@paths[1]).and_return('ipsum')
    end

    should 'concatenate the files and generate a fingerprint' do
      expected = AssetHat::Fingerprint.for_string('loremipsum')
      actual = AssetHat::Fingerprint.for_bundle(@bundle_name, :js)
      assert_equal expected, actual
    end

    should 'memoize the fingerprints' do
      AssetHat::Fingerprint.for_bundle(@bundle_name, :js)

      assert_not_nil AssetHat::Fingerprint.fingerprints[:js][@bundle_name]
    end
  end

  context 'cache_fingerprints' do
    context 'using the example config' do
      setup { AssetHat::Fingerprint.cache_fingerprints }

      should 'cache the fingerprints' do
        assert AssetHat::Fingerprint.fingerprints[:js].present?
        assert AssetHat::Fingerprint.fingerprints[:css].present?
        assert AssetHat::Fingerprint.fingerprints[:filepath].present?
      end
    end
  end
end
