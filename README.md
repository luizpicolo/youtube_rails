# Youtube Rails    
[![Gem Version](https://badge.fury.io/rb/youtube_rails.svg)](https://badge.fury.io/rb/youtube_rails)    
Helper to read in YouTube urls and parse the video id and generate the youtube embed HTML code

This is based on gem https://github.com/datwright/youtube_addy by **David Wright** **(Discontinued)**. Thanks so much

**Author:** Luiz Picolo

## INSTALL
`gem install youtube_rails`

or add in your gemfile

`gem 'youtube_rails'`

## How to use
```ruby
YouTubeRails.extract_video_id("http://www.youtube.com/watch?v=XwmtNk_Yb2Q")
=> "XwmtNk_Yb2Q"
```

```ruby
YouTubeRails.extract_video_id("https://youtu.be/cD4TAgdS_Xw")
=> "cD4TAgdS_Xw"
```

```ruby
YouTubeRails.extract_video_id("http://www.youtube.com/watch?feature=player_embedded&v=SahhfqNkHFU")
=> "SahhfqNkHFU"
```

```ruby
YouTubeRails.extract_video_id("http://youtube.com/watch?v=Cd4g33ijd<script>this_should_not_be_here</scipt>")
=> nil
```

```ruby
YouTubeRails.youtube_embed_url("http://youtu.be/cD4TAgdS_Xw",420,315)
=> '<iframe width="420" height="315" src="http://www.youtube.com/embed/cD4TAgdS_Xw" frameborder="0" allowfullscreen></iframe>'
```

```ruby
YouTubeRails.youtube_embed_url_only("http://youtu.be/cD4TAgdS_Xw")
=> 'http://www.youtube.com/embed/cD4TAgdS_Xw'
```

```ruby
YouTubeRails.extract_video_image("https://youtu.be/cD4TAgdS_Xw")
=> "https://i.ytimg.com/vi/cD4TAgdS_Xw/hqdefault.jpg"
```

```ruby
# Params: default, medium, high, maximum
YouTubeRails.extract_video_image("https://youtu.be/cD4TAgdS_Xw", 'high')
=> "https://i.ytimg.com/vi/cD4TAgdS_Xw/mqdefault.jpg"
```
