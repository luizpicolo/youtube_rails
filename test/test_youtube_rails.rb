require 'test/unit'
require 'base64'
require 'securerandom'
require 'youtube_rails'

class TestYouTubeRails < Test::Unit::TestCase
  # The URL schemes to test against.
  # Some URLs in webpage sources uses the // prefix to be https-agnostic.
  SCHEMES = ['http://', 'https://', 'HTTP://', 'HTTPS://', '//', '']

  # The schemes are not included here, because these are permuted programatically.
  # Domains are included, because the URL can depend on the domain. Note, however
  # that these domains must match a key in DOMAIN_ALIASES.
  CANDIDATE_URLS = [
    'youtube.com/watch?v=XXXXXXXXXXX',

    # Add some URLs with the full range of valid URI characters
    # (expanding those allowed previously to include `~#\[\]@;%]`)
    # See reserved and unreserved patterns here: https://www.rfc-editor.org/rfc/rfc3986#appendix-A
    # % Must also be included as it is used for character escapes.
    # Some URLs are not strictly correct YT URLs - but are valid URIs
    'youtube.com/watch?v=XXXXXXXXXXX&feature=channel#t=0m10s', # hash delimits anchors
    'youtube.com/watch?v=XXXXXXXXXXX&fs=1;hl=en_US;rel=0', # semicolon is a valid alt to &
    'youtube.com/watch?v=XXXXXXXXXXX&codes=[V@lid%20]', # the other characters!

    # These formats gathered from https://stackoverflow.com/a/70512384
    'www.youtube.com/watch?v=XXXXXXXXXXX', # Normal Url
    'youtu.be/XXXXXXXXXXX', # Share Url
    'youtu.be/XXXXXXXXXXX?t=6', # Share Url with start time
    'm.youtube.com/watch?v=XXXXXXXXXXX&list=RDXXXXXXXXXXX&start_radio=1', # Mobile browser url
    'www.youtube.com/watch?v=XXXXXXXXXXX&list=RDXXXXXXXXXXX&start_radio=1&rv=smKgVuS', # Long url
    'www.youtube.com/watch?v=XXXXXXXXXXX&list=RDXXXXXXXXXXX&start_radio=1&rv=XXXXXXXXXXX&t=38', # Long url with start time
    'youtube.com/shorts/XXXXXXXXXXX', # Youtube Shorts
  ]

  # Generates a random YouTube ID
  def random_id
    # 11 chars of RFC4648 base64url A-Z, a-z, 0-9, -, _ => just enough for 64 bits (actually 66)
    Base64.urlsafe_encode64(SecureRandom.random_bytes(8), padding: false)
  end

  def test_invalid_youtube_url
    assert_equal nil, YouTubeRails.extract_video_id("not a valid url")
    assert YouTubeRails.has_invalid_chars?("http://www.youtube.com/watch?v=something<script>badthings</script>")
    assert_equal nil, YouTubeRails.extract_video_id("http://www.youtube.com/watch?v=something<script>badthings</script>")
    assert_equal nil, YouTubeRails.extract_video_id("http://www.youtube,com/watch?v=something")
  end

  def test_old_style_youtube_url_returns_code
    assert_equal "something", YouTubeRails.extract_video_id("http://www.youtube.com/watch?v=something")
    assert_equal "XwmtNk_Yb2Q", YouTubeRails.extract_video_id("http://www.youtube.com/watch?v=XwmtNk_Yb2Q")
    assert_equal "XwmtNk_Yb2Q", YouTubeRails.extract_video_id("https://www.youtube.com/watch?v=XwmtNk_Yb2Q")
    assert_equal "XwmtNk_Yb2Q", YouTubeRails.extract_video_id("www.youtube.com/watch?v=XwmtNk_Yb2Q")
    assert_equal "XwmtNk_Yb2Q", YouTubeRails.extract_video_id("http://www.youtube.com/watch?v=XwmtNk_Yb2Q&feature=autoplay&list=AVGxdCwVVULXfH-k_IVzQbQcibTdWOSgKg&lf=artist&playnext=8")
    assert_equal "SahhfqNkHFU", YouTubeRails.extract_video_id("http://www.youtube.com/watch?feature=player_embedded&v=SahhfqNkHFU")
  end

  def test_new_style_youtube_url_returns_code
    assert_equal "cD4TAgdS_Xw", YouTubeRails.extract_video_id("http://youtu.be/cD4TAgdS_Xw")
    assert_equal "cD4TAgdS_Xw", YouTubeRails.extract_video_id("https://youtu.be/cD4TAgdS_Xw")
    assert_equal "cD4TAgdS_Xw", YouTubeRails.extract_video_id("youtu.be/cD4TAgdS_Xw")
  end

  # This test added to supplement the above, in a more generic way.
  def test_extract_video_id
    CANDIDATE_URLS.each do |url|
      scheme = SCHEMES.sample
      id = random_id
      url = scheme + url.sub('XXXXXXXXXXX', id)

      # Replace placeholder URLs with one of the variants (in either case)
      YouTubeRails::DOMAIN_ALIASES.each_pair do |placeholder, alternatives|
        next unless url.start_with?(placeholder)

        domain = alternatives.sample
        domain.upcase! if rand(2) == 1
        
        url[0, placeholder.length] = domain
        break
      end
      
      assert_equal id, YouTubeRails.extract_video_id(url), "when testing case: #{url}"
    end 
  end

  def test_youtube_urls_conversion
    vid_id              = "cD4TAgdS_Xw"
    regular_url         = "http://www.youtube.com/watch?v=#{ vid_id }"
    regular_url_https   = "https://www.youtube.com/watch?v=#{ vid_id }"
    embed_url           = "http://www.youtube.com/embed/#{ vid_id }"
    shortened_url       = "http://youtu.be/#{ vid_id }"
    shortened_url_https = "https://youtu.be/#{ vid_id }"

    assert_equal regular_url, YouTubeRails.youtube_regular_url(embed_url)
    assert_equal regular_url, YouTubeRails.youtube_regular_url(shortened_url)
    assert_equal regular_url_https, YouTubeRails.youtube_regular_url(embed_url, ssl: true)
    assert_equal regular_url_https, YouTubeRails.youtube_regular_url(shortened_url, ssl: true)

    assert_equal shortened_url, YouTubeRails.youtube_shortened_url(embed_url)
    assert_equal shortened_url, YouTubeRails.youtube_shortened_url(regular_url)
    assert_equal shortened_url_https, YouTubeRails.youtube_shortened_url(embed_url, ssl: true)
    assert_equal shortened_url_https, YouTubeRails.youtube_shortened_url(regular_url, ssl: true)
  end

  def test_youtube_embed_url
    vid_id                  = "cD4TAgdS_Xw"
    regular_url             = "http://www.youtube.com/watch?v=#{ vid_id }"
    iframe_default          = %(<iframe width="420" height="315" src="http://www.youtube.com/embed/#{vid_id}" frameborder="0" allowfullscreen></iframe>)
    iframe_custom           = %(<iframe width="500" height="350" src="http://www.youtube.com/embed/#{vid_id}" frameborder="0" allowfullscreen></iframe>)
    iframe_default_with_ssl = %(<iframe width="420" height="315" src="https://www.youtube.com/embed/#{vid_id}" frameborder="0" allowfullscreen></iframe>)
    iframe_custom_with_ssl  = %(<iframe width="500" height="350" src="https://www.youtube.com/embed/#{vid_id}" frameborder="0" allowfullscreen></iframe>)
    iframe_without_suggestions  = %(<iframe width="500" height="350" src="http://www.youtube.com/embed/#{vid_id}?rel=0" frameborder="0" allowfullscreen></iframe>)
    iframe_with_suggestions  = %(<iframe width="500" height="350" src="http://www.youtube.com/embed/#{vid_id}" frameborder="0" allowfullscreen></iframe>)

    assert_equal iframe_default, YouTubeRails.youtube_embed_url(regular_url)
    assert_equal iframe_custom, YouTubeRails.youtube_embed_url(regular_url, 500, 350)
    assert_equal iframe_default_with_ssl, YouTubeRails.youtube_embed_url(regular_url, 420, 315, ssl: true)
    assert_equal iframe_custom_with_ssl, YouTubeRails.youtube_embed_url(regular_url, 500, 350, ssl: true)
    assert_equal iframe_without_suggestions, YouTubeRails.youtube_embed_url(regular_url, 500, 350, disable_suggestion: true)
    assert_equal iframe_with_suggestions, YouTubeRails.youtube_embed_url(regular_url, 500, 350, disable_suggestion: false)
  end

  def test_youtube_image
    vid_id                  = "cD4TAgdS_Xw"
    regular_url             = "http://www.youtube.com/watch?v=#{ vid_id }"
    image_default           = "https://i.ytimg.com/vi/cD4TAgdS_Xw/default.jpg"
    image_medium_quality    = "https://i.ytimg.com/vi/cD4TAgdS_Xw/mqdefault.jpg"
    image_high_quality     = "https://i.ytimg.com/vi/cD4TAgdS_Xw/hqdefault.jpg"
    image_sd_quality        = "https://i.ytimg.com/vi/cD4TAgdS_Xw/sddefault.jpg"

    assert_equal image_default, YouTubeRails.extract_video_image(regular_url)
    assert_equal image_default, YouTubeRails.extract_video_image(regular_url, 'default')
    assert_equal image_medium_quality, YouTubeRails.extract_video_image(regular_url, 'medium')
    assert_equal image_high_quality, YouTubeRails.extract_video_image(regular_url, 'high')
    assert_equal image_sd_quality, YouTubeRails.extract_video_image(regular_url, 'maximum')
  end
end
