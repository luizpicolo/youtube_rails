class YouTubeRails
  # Converts a list of domains into a regex matching them at the start of a string
  def self._domains_to_regex(domains)
    pattern = [
      '^(',
      domains.map {|d| Regexp.quote(d) }.join('|'),
      ')/'
    ].join('')
    
    Regexp.new(pattern, Regexp::IGNORECASE | Regexp::MULTILINE)
  end

  SCHEME_FORMAT = %r{(https?:|)//}i
  SHORTURL_DOMAIN = 'youtu.be'
  # Some URLs are interchangeable with others. The keys here are just an ID.
  DOMAIN_ALIASES = {
    'youtube.com' => %w{www.youtube.com
                            youtube.com
                          m.youtube.com
                        www.youtube-nocookie.com},
    SHORTURL_DOMAIN => [SHORTURL_DOMAIN],
  }
  DOMAIN_REGEX = DOMAIN_ALIASES.map do |placeholder, domains|
    [placeholder, _domains_to_regex(domains)]
  end.to_h

  ID = %r{(?<id>[0-9a-zA-Z_-]+)} # URL-safe Base64 ID
  ANYPARAMS = %r{([^;&]*[&;])*} # Zero or more URL parameters
  URL_FORMATS = [
    %r{^(watch|ytscreeningroom)\?#{ANYPARAMS}v=#{ID}}mi,
    %r{^(v|e|embed|shorts)/#{ID}}mi,
    %r{^oembed\?#{ANYPARAMS}url=[^&;]+watch(%3f|\?)v(=|%3d)#{ID}}mi, # accepts encoded delims
    %r{^attribution_link\?#{ANYPARAMS}u=(/|%2f)watch(%3f|\?)v(=|%3d)#{ID}}mi, # ditto
    %r{^apiplayer\?#{ANYPARAMS}video_id=#{ID}}mi,
  ]
  SHORTURL_FORMATS = [
    %r{^#{ID}}i,
  ]
  
  # See reserved and unreserved characters here:
  # https://www.rfc-editor.org/rfc/rfc3986#appendix-A
  # Note, % character must also be included, as this is used in pct-encoded escapes.
  INVALID_CHARS = %r{[^a-zA-Z0-9:/?=&$\-_.+!*'(),~#\[\]@;%]}

  def self.has_invalid_chars?(youtube_url)
    !INVALID_CHARS.match(youtube_url).nil?
  end

  def self.extract_video_id(youtube_url)
    return nil if has_invalid_chars?(youtube_url)
    youtube_url = youtube_url
                    .strip # remove whitespace before and after
                    .sub(%r{^#{SCHEME_FORMAT}}, '') # remove valid schemes

    # Deal with shortened URLs as a special case
    if youtube_url.sub!(DOMAIN_REGEX['youtu.be'], '')
      SHORTURL_FORMATS.each do |regex|
        match = youtube_url.match(regex)
        return match[:id] if match
      end
      return nil # No matches
    end

    # Ensure one of the regular allows domains matches
    return nil unless youtube_url.sub!(DOMAIN_REGEX['youtube.com'], '')
    
    URL_FORMATS.inject(nil) do |result, format_regex|
      match = format_regex.match(youtube_url)
      match ? match[:id] : result
    end
  end

  def self.youtube_embed_url(youtube_url, width = 420, height = 315, **options)
    %(<iframe width="#{width}" height="#{height}" src="#{ youtube_embed_url_only(youtube_url, **options) }" frameborder="0" allowfullscreen></iframe>)
  end

  def self.youtube_regular_url(youtube_url, **options)
    vid_id = extract_video_id(youtube_url)
    "http#{'s' if options[:ssl]}://www.youtube.com/watch?v=#{ vid_id }"
  end

  def self.youtube_shortened_url(youtube_url, **options)
    vid_id = extract_video_id(youtube_url)
    "http#{'s' if options[:ssl]}://youtu.be/#{ vid_id }"
  end

  def self.youtube_embed_url_only(youtube_url, **options)
    vid_id = extract_video_id(youtube_url)
    "http#{'s' if options[:ssl]}://www.youtube.com/embed/#{ vid_id }#{'?rel=0' if options[:disable_suggestion]}"
  end

  def self.extract_video_image(youtube_url, version = 'default')
    vid_id = extract_video_id(youtube_url)
    case version
      when 'default'
        "https://i.ytimg.com/vi/#{ vid_id }/default.jpg"
      when 'medium'
        "https://i.ytimg.com/vi/#{ vid_id }/mqdefault.jpg"
      when 'high'
        "https://i.ytimg.com/vi/#{ vid_id }/hqdefault.jpg"
      when 'maximum'
        "https://i.ytimg.com/vi/#{ vid_id }/sddefault.jpg"
    end
  end
end
