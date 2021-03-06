describe "Quickbooks::Service::Payment" do
  before(:all) { construct_service :payment }

  let(:customer_ref) { Quickbooks::Model::BaseReference.new(:value => 42) }
  let(:model) { Quickbooks::Model::Payment }
  let(:payment) { model.new :id => 8748, :customer_ref => customer_ref }
  let(:resource) { model::REST_RESOURCE }

  it "can query for payments" do
    stub_request(:get,
                 @service.url_for_query,
                 ["200", "OK"],
                 fixture("payments.xml"))

    payments = @service.query

    payments.entries.count.should eq(1)
    payment = payments.entries.first
    payment.private_note.should eq("H60jzmw0Uq")
  end

  it "can fetch a payment by ID" do
    stub_request(:get,
                 "#{@service.url_for_resource(resource)}/1",
                 ["200", "OK"],
                 fixture("payment_by_id.xml"))

    payment = @service.fetch_by_id(1)

    payment.private_note.should eq("H60jzmw0Uq")
  end

  it "can create a payment" do
    stub_request(:post,
                 @service.url_for_resource(resource),
                 ["200", "OK"],
                 fixture("fetch_payment_by_id.xml"))

    created_payment = @service.create(payment)

    created_payment.id.should eq(8748)
  end

  it "can sparse update a payment" do
    payment.total = 20.0
    stub_request(:post,
                 @service.url_for_resource(resource),
                 ["200", "OK"],
                 fixture("fetch_payment_by_id.xml"),
                 true)

    update_response = @service.update(payment, :sparse => true)

    update_response.total.should eq(40.0)
  end

  it "can delete a payment" do
    stub_request(:post,
                 "#{@service.url_for_resource(resource)}?operation=delete",
                 ["200", "OK"],
                 fixture("payment_delete_success_response.xml"))

    response = @service.delete(payment)

    response.should be_true
  end

  it "properly outputs BigDecimal fields" do
    payment.total = payment.unapplied_amount = payment.exchange_rate = "42"

    xml = payment.to_xml

    xml.at("TotalAmt").text.should eq("42.0")
    xml.at("UnappliedAmt").text.should eq("42.0")
    xml.at("ExchangeRate").text.should eq("42.0")
  end
end
