#!/usr/bin/env ruby

require 'rubygems'
require 'net/https'
require 'xmlsimple'
require 'term/ansicolor'

def fetch(urlstr)
  url = URI.parse(urlstr)
  Net::HTTP.start(url.host, url.port) do |h|
    h.get("#{url.path}?#{url.query}").body
  end
end

CODESEARCH_URL = 'http://www.google.com/codesearch/feeds/search?q='

def codesearch_url(exprs)
  "#{CODESEARCH_URL}#{URI.encode(exprs.join(' '))}"
end

def search_results(exprs)
  x = XmlSimple.xml_in(fetch(codesearch_url(exprs)))
  x['entry'].map do |doc|
    pkg = doc['package'].first['name']
    link = doc['link'].first['href']
    file = doc['file'].first['name']
    match = doc['match'].map{|x| x['content']}.join("\n")
    {:pkg => pkg, :link => link,
     :file => file, :match => match}
  end
end

def html_to_term(html)
  html.gsub(/<b>/, Term::ANSIColor.bold). \
    gsub(/<\/b>/, Term::ANSIColor.clear). \
    gsub(/<pre>/, ''). \
    gsub(/<\/pre>/, '')
end

def format_results(res)
  fres = res.map do |res|
    "== #{Term::ANSIColor.red(res[:pkg])} #{Term::ANSIColor.green(res[:file])}\n" + \
    "   #{Term::ANSIColor.blue(res[:link])}\n#{html_to_term(res[:match])}"
  end
  fres.join("\n")
end

if $0 == __FILE__
  exprs = ARGV
  if exprs.empty?
    usage
  else
    $stdout.puts format_results(search_results(exprs))
  end
end
