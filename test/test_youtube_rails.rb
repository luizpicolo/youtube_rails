require 'test/unit'
require 'youtube_rails'

class TestYouTubeRails < Test::Unit::TestCase
  def test_invalid_youtube_url
    assert_equal nil, YouTubeRails.extract_video_id("not a valid url")
    assert YouTubeRails.has_invalid_chars?("http://www.youtube.com/watch?v=something<script>badthings</script>")
    assert_equal nil, YouTubeRails.extract_video_id("http://www.youtube.com/watch?v=something<script>badthings</script>")
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

    assert_equal iframe_default, YouTubeRails.youtube_embed_url(regular_url)
    assert_equal iframe_custom, YouTubeRails.youtube_embed_url(regular_url, 500, 350)
    assert_equal iframe_default_with_ssl, YouTubeRails.youtube_embed_url(regular_url, 420, 315, ssl: true)
    assert_equal iframe_custom_with_ssl, YouTubeRails.youtube_embed_url(regular_url, 500, 350, ssl: true)
  end

  def test_youtube_image
    vid_id                  = "cD4TAgdS_Xw"
    regular_url             = "http://www.youtube.com/watch?v=#{ vid_id }"
    image_default           = "https://i.ytimg.com/vi/cD4TAgdS_Xw/default.jpg"
    image_medium_quality    = "https://i.ytimg.com/vi/cD4TAgdS_Xw/mqdefault.jpg"
    image_high_quality     = "https://i.ytimg.com/vi/cD4TAgdS_Xw/hqdefault.jpg"
    image_sd_quality        = "https://i.ytimg.com/vi/cD4TAgdS_Xw/sddefault.jpg"

    assert_equal image_default, YouTubeRails.youtube_video_image(regular_url)
    assert_equal image_default, YouTubeRails.youtube_video_image(regular_url, 'default')
    assert_equal image_medium_quality, YouTubeRails.youtube_video_image(regular_url, 'medium')
    assert_equal image_high_quality, YouTubeRails.youtube_video_image(regular_url, 'high')
    assert_equal image_sd_quality, YouTubeRails.youtube_video_image(regular_url, 'maximum')
  end
end
