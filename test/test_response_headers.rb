require File.join(File.dirname(__FILE__), "test_helper")

class TestResponseHeaders < Test::Unit::TestCase

  def setup
    FakeWeb.clean_registry
  end

  def test_content_type_when_registering_with_string_and_content_type_header
    FakeWeb.register_uri(:get, "http://example.com/users.json", :string => '[{"username": "chrisk"}]', :content_type => "application/json")
    response = Net::HTTP.start("example.com") { |query| query.get("/users.json") }
    assert_equal '[{"username": "chrisk"}]', response.body
    assert_equal "application/json", response['Content-Type']
  end

  def test_content_type_when_registering_with_string_only
    FakeWeb.register_uri(:get, "http://example.com/users.json", :string => '[{"username": "chrisk"}]')
    response = Net::HTTP.start("example.com") { |query| query.get("/users.json") }
    assert_equal '[{"username": "chrisk"}]', response.body
    assert_nil response['Content-Type']
  end

  def test_cookies_when_registering_with_file_and_set_cookie_header
    FakeWeb.register_uri(:get, "http://example.com/", :file => File.dirname(__FILE__) + '/fixtures/test_example.txt',
                                                      :set_cookie => "user_id=1; example=yes")
    response = Net::HTTP.start("example.com") { |query| query.get("/") }
    assert_equal "test example content", response.body
    assert_equal "user_id=1; example=yes", response['Set-Cookie']
  end

  def test_registering_with_baked_response_ignores_header_options
    fake_response = Net::HTTPOK.new('1.1', '200', 'OK')
    fake_response["Server"] = "Apache/1.3.27 (Unix)"
    FakeWeb.register_uri(:get, "http://example.com/", :response => fake_response,
                                                      :server => "FakeWeb/1.2.3 (Ruby)")
    response = Net::HTTP.start("example.com") { |query| query.get("/") }
    assert_equal "200", response.code
    assert_equal "OK", response.message
    assert_equal "Apache/1.3.27 (Unix)", response["Server"]
  end

  def test_headers_are_rotated_when_registering_with_response_rotation
    FakeWeb.register_uri(:get, "http://example.com",
                               [{:string => 'test1', :expires => "Thu, 14 Jun 2009 16:00:00 GMT",
                                                     :content_type => "text/plain"},
                                {:string => 'test2', :expires => "Thu, 14 Jun 2009 16:00:01 GMT"}])

    Net::HTTP.start("example.com") do |query|
      response = query.get("/")
      assert_equal 'test1', response.body
      assert_equal "Thu, 14 Jun 2009 16:00:00 GMT", response['Expires']
      assert_equal "text/plain", response['Content-Type']

      response = query.get("/")
      assert_equal 'test2', response.body
      assert_equal "Thu, 14 Jun 2009 16:00:01 GMT", response['Expires']
      assert_nil response['Content-Type']
    end
  end

  def test_registering_with_status_option_and_response_headers
    FakeWeb.register_uri(:get, "http://example.com", :status => ["301", "Moved Permanently"],
                                                     :location => "http://www.example.com")

    response = Net::HTTP.start("example.com") { |query| query.get("/") }
    assert_equal "301", response.code
    assert_equal "Moved Permanently", response.message
    assert_equal "http://www.example.com", response["Location"]
  end

end