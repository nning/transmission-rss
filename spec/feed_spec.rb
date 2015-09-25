require 'spec_helper'

describe Feed do
  before do
    @url = "http://site.com/rss"
    @download_path = "~/files"
    @matcher = ".*\\.pdf"
    @regexp = /.*\.pdf/i
  end

  it "should be parse simple array format" do
    feed = Feed.new(@url)
    expect(feed.url).to eq(@url)
    expect(feed.download_path).to be_nil
    expect(feed.regexp).to be_nil
  end

  it "should be able to parse old style hash with no options" do
    feed = Feed.new({@url => nil})
    expect(feed.url).to eq(@url)
    expect(feed.download_path).to be_nil
    expect(feed.regexp).to be_nil
  end

  it "should be able to parse old style with both options" do
    feed = Feed.new({@url => nil, "download_path" => @download_path, "regexp" => @matcher})
    expect(feed.url).to eq(@url)
    expect(feed.download_path).to eq(@download_path)
    expect(feed.regexp).to eq(@regexp)
  end

  it "should be able to use new style config with no options" do
    feed = Feed.new({"url" => @url})
    expect(feed.url).to eq(@url)
    expect(feed.download_path).to be_nil
    expect(feed.regexp).to be_nil
  end

  it "should be able to use new style config with all options" do
    feed = Feed.new({"url" => @url, "download_path" => @download_path, "regexp" => @matcher})
    expect(feed.url).to eq(@url)
    expect(feed.download_path).to eq(@download_path)
    expect(feed.regexp).to eq(@regexp)
  end

  it "should have a functioning matcher" do
    feed = Feed.new({"url" => @url, "download_path" => @download_path, "regexp" => @matcher})
    expect(feed.matches_regexp?("myfile.pdf")).to eq(true)
    expect(feed.matches_regexp?("myfile.doc")).to eq(false)
    expect(feed.matches_regexp?("MYFILE.PDF")).to eq(true)
  end
end
