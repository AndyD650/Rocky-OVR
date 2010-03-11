require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DownloadsController do
  integrate_views

  before(:each) do
    @registrant = Factory.create(:step_5_registrant)
    `touch #{@registrant.pdf_file_path}`
  end

  it "provides a link to download the PDF" do
    get :show, :registrant_id => @registrant.to_param
    assert_not_nil assigns[:registrant]
    assert_response :success
    assert_template "download"
    assert_select "span.button a[target=_blank]"
    assert_select "span.button a[onclick]"
  end

  after(:each) do
    `rm #{@registrant.pdf_file_path}`
  end
end
