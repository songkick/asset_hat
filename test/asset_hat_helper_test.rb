require 'test_helper'
ENV['RAILS_ASSET_ID'] = ''

class AssetHatHelperTest < ActionView::TestCase
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

  context 'include_css' do
    setup { flexmock_rails_app }

    context 'with caching enabled' do
      context 'with minified versions' do
        setup do
          @fingerprint = '111'
          flexmock(AssetHat::Fingerprint).should_receive(
            :for_bundle => @fingerprint,
            :for_filepath => @fingerprint).
            by_default
        end

        should 'include one file by name, and ' +
               'automatically use minified version' do
          flexmock(AssetHat, :asset_exists? => true)
          expected_html = css_tag("foo.min.#{@fingerprint}.css")
          expected_path =
            AssetHat.assets_path(:css) + "/foo.min.#{@fingerprint}.css"

          assert_equal expected_html, include_css('foo', :cache => true)
          assert_equal expected_path, include_css('foo', :cache => true,
                                        :only_url => true)
        end

        should 'include one unminified file by name and extension' do
          expected_html = css_tag("foo.#{@fingerprint}.css")
          expected_path =
            AssetHat.assets_path(:css) + "/foo.#{@fingerprint}.css"

          assert_equal expected_html, include_css('foo.css', :cache => true)
          assert_equal expected_path, include_css('foo.css', :cache => true,
                                        :only_url => true)
        end

        should 'include one minified file by name and extension' do
          expected_html = css_tag("foo.min.#{@fingerprint}.css")
          expected_path =
            AssetHat.assets_path(:css) + "/foo.min.#{@fingerprint}.css"

          assert_equal expected_html,
            include_css('foo.min.css', :cache => true)
          assert_equal expected_path,
            include_css('foo.min.css', :cache => true, :only_url => true)
        end

        should 'include multiple files by name' do
          flexmock(AssetHat, :asset_exists? => true)

          sources = %w[foo bar]
          expected_html = sources.map do |source|
            css_tag("#{source}.min.#{@fingerprint}.css")
          end.join("\n")
          expected_paths = sources.map do |source|
            AssetHat.assets_path(:css) + "/#{source}.min.#{@fingerprint}.css"
          end

          assert_equal expected_html,
            include_css('foo', 'bar', :cache => true)
          assert_equal expected_paths,
            include_css('foo', 'bar', :cache => true, :only_url => true)
        end

        should 'include multiple files as a bundle' do
          bundle = 'css-bundle-1'
          expected_html = css_tag("bundles/#{bundle}.min.#{@fingerprint}.css")
          expected_path =
            AssetHat.bundles_path(:css) + "/#{bundle}.min.#{@fingerprint}.css"

          assert_equal expected_html,
            include_css(:bundle => bundle, :cache => true)
          assert_equal expected_path,
            include_css(:bundle => bundle, :cache => true, :only_url => true)
        end

        context 'via SSL' do
          setup do
            @request = test_request
            flexmock(@controller).should_receive(:request => @request).
              by_default
            flexmock(@controller.request).should_receive(:ssl? => true).
              by_default
            assert @controller.request.ssl?,
              'Precondition: Request should use SSL'
          end

          should 'include multiple files as a SSL bundle' do
            flexmock(AssetHat, :ssl_asset_host_differs? => true)
            bundle = 'css-bundle-1'
            expected_html =
              css_tag("bundles/ssl/#{bundle}.min.#{@fingerprint}.css")
            expected_path = AssetHat.bundles_path(:css, :ssl => true) +
              "/#{bundle}.min.#{@fingerprint}.css"

            assert_equal expected_html,
              include_css(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_css(:bundle => bundle, :cache => true,
                :only_url => true)
          end

          should 'use non-SSL CSS if SSL/non-SSL asset hosts are the same' do
            flexmock(AssetHat, :ssl_asset_host_differs? => false)
            bundle = 'css-bundle-1'
            expected_html = css_tag("bundles/#{bundle}.min.#{@fingerprint}.css")
            expected_path = AssetHat.bundles_path(:css) +
              "/#{bundle}.min.#{@fingerprint}.css"

            assert_equal expected_html,
              include_css(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_css(:bundle => bundle, :cache => true,
                :only_url => true)
          end
        end # context 'via SSL'

      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and ' +
               'automatically use original version' do
          expected_html = css_tag('foo.css')
          expected_path = AssetHat.assets_path(:css) + '/foo.css'

          assert_equal expected_html, include_css('foo')
          assert_equal expected_path, include_css('foo', :only_url => true)
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and ' +
             'automatically use original version' do
        expected_html = css_tag('foo.css')
        expected_path = AssetHat.assets_path(:css) + '/foo.css'

        assert_equal expected_html, include_css('foo', :cache => false)
        assert_equal expected_path, include_css('foo', :cache => false,
                                      :only_url => true)
      end

      should 'include one unminified file by name and extension' do
        expected_html = css_tag('foo.css')
        expected_path = AssetHat.assets_path(:css) + '/foo.css'

        assert_equal expected_html, include_css('foo.css', :cache => false)
        assert_equal expected_path, include_css('foo.css', :cache => false,
                                      :only_url => true)
      end

      should 'include multiple files by name' do
        sources = %w[foo bar.min]
        expected_html =
          sources.map { |source| css_tag("#{source}.css") }.join("\n")
        expected_paths = sources.map do |source|
          AssetHat.assets_path(:css) + "/#{source}.css"
        end

        assert_equal expected_html,
          include_css('foo', 'bar.min', :cache => false)
        assert_equal expected_paths,
          include_css('foo', 'bar.min', :cache => false, :only_url => true)
      end

      context 'with real bundle files' do
        setup do
          @config = AssetHat.config
        end

        should 'include a bundle as separate files' do
          bundle = 'css-bundle-1'
          bundle_filenames = @config['css']['bundles'][bundle]
          expected_html = bundle_filenames.map do |source|
            css_tag("#{source}.css")
          end.join("\n")
          expected_paths = bundle_filenames.map do |source|
            AssetHat.assets_path(:css) + "/#{source}.css"
          end

          assert_equal expected_html,
            include_css(:bundle => bundle, :cache => false)
          assert_equal expected_paths,
            include_css(:bundle => bundle, :cache => false, :only_url => true)
        end

        should 'include a bundle as separate files ' +
               'with a symbol bundle name' do
          bundle = 'css-bundle-1'
          expected = @config['css']['bundles'][bundle].map { |source|
            css_tag("#{source}.css")
          }.join("\n")
          output = include_css(:bundle => bundle.to_sym, :cache => false)
          assert_equal expected, output
        end

        should 'include multiple bundles as separate files' do
          bundles = [1,2].map { |i| "css-bundle-#{i}" }
          expected_html = bundles.map { |bundle|
            sources = @config['css']['bundles'][bundle]
            sources.map { |src| css_tag("#{src}.css") }
          }.flatten.uniq.join("\n")
          expected_paths = bundles.map do |bundle|
            sources = @config['css']['bundles'][bundle]
            sources.map do |src|
              AssetHat.assets_path(:css) + "/#{src}.css"
            end
          end.flatten.uniq

          assert_equal expected_html,
            include_css(:bundles => bundles, :cache => false)
          assert_equal expected_paths,
            include_css(:bundles => bundles, :cache => false,
              :only_url => true)
        end

        should 'include named files and bundles together' do
          bundles = ['css-bundle-2']
          expected_html = css_tag("css-file-1-1.css") + "\n" +
            bundles.map do |bundle|
              sources = @config['css']['bundles'][bundle]
              sources.map { |src| css_tag("#{src}.css") }
            end.flatten.uniq.join("\n")
          expected_paths = ["/stylesheets/css-file-1-1.css"] +
            bundles.map do |bundle|
              sources = @config['css']['bundles'][bundle]
              sources.map do |src|
                AssetHat.assets_path(:css) + "/#{src}.css"
              end
            end.flatten.uniq

          assert_equal expected_html,
            include_css('css-file-1-1', :bundles => bundles, :cache => false)
          assert_equal expected_paths,
            include_css('css-file-1-1', :bundles => bundles, :cache => false,
              :only_url => true)
        end
      end # context 'with real bundle files'
    end # context 'with caching disabled'
  end # context 'include_css'

  context 'include_js' do
    setup do
      flexmock_rails_app
      @request = test_request
      flexmock(@controller).should_receive(:request => @request).by_default
    end

    context 'with caching enabled' do
      setup do
      end

      context 'with minified versions' do
        setup do
          @fingerprint = '111'
          flexmock(AssetHat::Fingerprint).should_receive(
            :for_filepath => @fingerprint,
            :for_bundle   => @fingerprint
          ).by_default
        end

        should 'include one file by name, and ' +
               'automatically use minified version' do
          filename = 'jquery.some-plugin'
          flexmock(AssetHat, :asset_exists? => true)
          expected_html = js_tag("#{filename}.min.#{@fingerprint}.js")
          expected_path = AssetHat.assets_path(:js) +
            "/#{filename}.min.#{@fingerprint}.js"

          assert_equal expected_html,
            include_js(filename, :cache => true)
          assert_equal expected_path,
            include_js(filename, :cache => true,
              :only_url => true)
        end

        should 'include one unminified file by name and extension' do
          filename = 'jquery.some-plugin'
          ext      = '.js'
          expected_html = js_tag("#{filename}.#{@fingerprint}#{ext}")
          expected_path =
            AssetHat.assets_path(:js) + "/#{filename}.#{@fingerprint}#{ext}"

          assert_equal expected_html, include_js(filename, :cache => true)
          assert_equal expected_path, include_js(filename, :cache => true,
                                        :only_url => true)
        end

        should 'include one minified file by name and extension' do
          filename = 'jquery.some-plugin.min'
          ext      = '.js'
          expected_html = js_tag("#{filename}.#{@fingerprint}#{ext}")
          expected_path =
            AssetHat.assets_path(:js) + "/#{filename}.#{@fingerprint}#{ext}"

          assert_equal expected_html, include_js(filename, :cache => true)
          assert_equal expected_path, include_js(filename, :cache => true,
                                        :only_url => true)
        end

        should 'include multiple files by name' do
          flexmock(AssetHat, :asset_exists? => true)
          sources = %w[foo jquery.plugin]
          expected_html = sources.map do |source|
            js_tag("#{source}.min.#{@fingerprint}.js")
          end.join("\n")
          expected_paths = sources.map do |source|
            AssetHat.assets_path(:js) + "/#{source}.min.#{@fingerprint}.js"
          end

          assert_equal expected_html,
            include_js('foo', 'jquery.plugin', :cache => true)
          assert_equal expected_paths,
            include_js('foo', 'jquery.plugin', :cache => true,
              :only_url => true)
        end

        should 'include multiple files as a bundle' do
          bundle   = 'js-bundle-1'
          filename = "#{bundle}.min"
          ext      = ".js"
          expected_html = js_tag("bundles/#{filename}.#{@fingerprint}#{ext}")
          expected_path =
            AssetHat.bundles_path(:js) + "/#{filename}.#{@fingerprint}#{ext}"

          assert_equal expected_html,
            include_js(:bundle => bundle, :cache => true)
          assert_equal expected_path,
            include_js(:bundle => bundle, :cache => true, :only_url => true)
        end

        should 'include multiple bundles' do
          flexmock(AssetHat, :asset_exists? => true)
          bundles = %w[foo bar]
          expected_html = bundles.map do |bundle|
            js_tag("bundles/#{bundle}.min.#{@fingerprint}.js")
          end.join("\n")
          expected_paths = bundles.map do |bundle|
            AssetHat.bundles_path(:js) + "/#{bundle}.min.#{@fingerprint}.js"
          end

          assert_equal expected_html,
            include_js(:bundles => bundles, :cache => true)
          assert_equal expected_paths,
            include_js(:bundles => bundles, :cache => true, :only_url => true)
        end

        context 'via SSL' do
          setup do
            @request = test_request
            flexmock(@controller).should_receive(:request => @request).
              by_default
            flexmock(@controller.request).should_receive(:ssl? => true).
              by_default
            assert @controller.request.ssl?,
              'Precondition: Request should use SSL'
          end

          should 'use non-SSL JS if SSL/non-SSL asset hosts differ' do
            flexmock(AssetHat, :ssl_asset_host_differs? => true)
            bundle = 'js-bundle-1'
            expected_html = js_tag("bundles/#{bundle}.min.#{@fingerprint}.js")
            expected_path =
              AssetHat.bundles_path(:js) + "/#{bundle}.min.#{@fingerprint}.js"

            assert_equal expected_html,
              include_js(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_js(:bundle => bundle, :cache => true, :only_url => true)
          end

          should 'use non-SSL JS if SSL/non-SSL asset hosts are the same' do
            flexmock(AssetHat, :ssl_asset_host_differs? => false)
            bundle = 'js-bundle-1'
            expected_html = js_tag("bundles/#{bundle}.min.#{@fingerprint}.js")
            expected_path =
              AssetHat.bundles_path(:js) + "/#{bundle}.min.#{@fingerprint}.js"

            assert_equal expected_html,
              include_js(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_js(:bundle => bundle, :cache => true, :only_url => true)
          end
        end # context 'via SSL'
      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and ' +
               'automatically use original version' do
          source = 'jquery.some-plugin'

          expected_html = js_tag("#{source}.js")
          expected_path = AssetHat.assets_path(:js) + "/#{source}.js"

          assert_equal expected_html, include_js(source, :cache => true)
          assert_equal expected_path, include_js(source, :cache => true,
                                        :only_url => true)
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and ' +
             'automatically use original version' do
        source = 'foo'
        expected_html = js_tag("#{source}.js")
        expected_path = AssetHat.assets_path(:js) + "/#{source}.js"

        assert_equal expected_html, include_js(source, :cache => true)
        assert_equal expected_path, include_js(source, :cache => true,
                                      :only_url => true)
      end

      should 'include one unminified file by name and extension' do
        filename = 'foo.js'
        expected_html = js_tag(filename)
        expected_path = AssetHat.assets_path(:js) + "/#{filename}"

        assert_equal expected_html, include_js(filename, :cache => true)
        assert_equal expected_path, include_js(filename, :cache => true,
                                      :only_url => true)
      end

      should 'include one minified file by name and extension' do
        filename = 'foo.min.js'
        expected_html = js_tag(filename)
        expected_path = AssetHat.assets_path(:js) + "/#{filename}"

        assert_equal expected_html, include_js(filename, :cache => true)
        assert_equal expected_path, include_js(filename, :cache => true,
                                      :only_url => true)
      end

      should 'include multiple files by name' do
        sources = %w[foo bar.min]
        expected_html = sources.map do |source|
          js_tag("#{source}.js")
        end.join("\n")
        expected_paths = sources.map do |source|
          AssetHat.assets_path(:js) + "/#{source}.js"
        end

        assert_equal expected_html,
          include_js('foo', 'bar.min', :cache => false)
        assert_equal expected_paths,
          include_js('foo', 'bar.min', :cache => false, :only_url => true)
      end

      context 'with real bundle files' do
        setup do
          @config = AssetHat.config
        end

        should 'include a bundle as separate files' do
          bundle = 'js-bundle-1'
          sources = @config['js']['bundles'][bundle]
          expected_html = sources.map do |source|
            js_tag("#{source}.js")
          end.join("\n")
          expected_paths = sources.map do |source|
            AssetHat.assets_path(:js) + "/#{source}.js"
          end

          assert_equal expected_html,
            include_js(:bundle => bundle, :cache => false)
          assert_equal expected_paths,
            include_js(:bundle => bundle, :cache => false, :only_url => true)
        end

        should 'include a bundle as separate files ' +
               'with a symbol bundle name' do
          bundle   = 'js-bundle-1'
          sources  = @config['js']['bundles'][bundle]
          expected = sources.
            map { |src| js_tag("#{src}.js") }.join("\n")
          output = include_js(:bundle => bundle.to_sym, :cache => false)
          assert_equal expected, output
        end

        should 'include multiple bundles as separate files' do
          bundles = [1,2].map { |i| "js-bundle-#{i}" }
          expected_html = bundles.map { |bundle|
            sources = @config['js']['bundles'][bundle]
            sources.map { |src| js_tag("#{src}.js") }
          }.flatten.uniq.join("\n")
          expected_paths = bundles.map do |bundle|
            sources = @config['js']['bundles'][bundle]
            sources.map do |src|
              AssetHat.assets_path(:js) + "/#{src}.js"
            end
          end.flatten.uniq

          assert_equal expected_html,
            include_js(:bundles => bundles, :cache => false)
          assert_equal expected_paths,
            include_js(:bundles => bundles, :cache => false,
              :only_url => true)
        end

      end # context 'with real bundle files'
    end # context 'with caching disabled'

  end # context 'include_js'

  should 'compute public asset paths' do
    flexmock_rails_app

    assert_equal '/stylesheets/foo.css', asset_path(:css, 'foo')
    assert_equal '/stylesheets/bundles/foo.min.css',
      asset_path(:css, 'bundles/foo.min.css')

    assert_equal '/javascripts/foo.js', asset_path(:js, 'foo')
    assert_equal '/javascripts/bundles/foo.min.js',
      asset_path(:js, 'bundles/foo.min.js')
  end

  private

  def css_tag(filename)
    %{
      <link href="/stylesheets/#{filename}"
            media="screen,projection" rel="stylesheet" type="text/css" />
    }.strip.gsub(/\s+/, ' ')
  end

  def js_tag(filename)
    %{<script src="/javascripts/#{filename}" type="text/javascript"></script>}
  end

  def flexmock_rails_app
    # Creates just enough hooks for a dummy Rails app.
    flexmock(Rails,
      :application => flexmock('dummy_app', :env_defaults => {}),
      :logger      => flexmock('dummy_logger', :warn => nil)
    )

    if defined?(config) # Rails 3.x
      config.assets_dir = AssetHat::ASSETS_DIR
    end

    flexmock(AssetHat).should_receive(:consider_all_requests_local? => true).
      by_default
  end

  def test_request
    if defined?(ActionDispatch) # Rails 3.x
      ActionDispatch::TestRequest.new
    else # Rails 2.x
      ActionController::TestRequest.new
    end
  end

end

