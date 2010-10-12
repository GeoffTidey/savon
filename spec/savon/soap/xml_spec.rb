require "spec_helper"

describe Savon::SOAP::XML do
  let(:xml) { Savon::SOAP::XML.new Endpoint.soap, :authenticate, :id => 1 }

  describe ".new" do
    it "should accept an endpoint, an input tag and a SOAP body" do
      xml = Savon::SOAP::XML.new Endpoint.soap, :authentication, :id => 1
      
      xml.endpoint.should == Endpoint.soap
      xml.input.should == :authentication
      xml.body.should == { :id => 1 }
    end
  end

  describe "#input" do
    it "should set the input tag" do
      xml.input = :test
      xml.input.should == :test
    end
  end

  describe "#endpoint" do
    it "should set the endpoint to use" do
      xml.endpoint = "http://test.com"
      xml.endpoint.should == "http://test.com"
    end
  end

  describe "#version" do
    it "should default to SOAP 1.1" do
      xml.version.should == 1
    end

    it "should default to the global default" do
      Savon.soap_version = 2
      xml.version.should == 2
      
      reset_soap_version
    end

    it "should set the SOAP version to use" do
      xml.version = 2
      xml.version.should == 2
    end

    it "should raise an ArgumentError in case of an invalid version" do
      lambda { xml.version = 3 }.should raise_error(ArgumentError)
    end
  end

  describe "#header" do
    it "should default to an empty Hash" do
      xml.header.should == {}
    end

    it "should set the SOAP header" do
      xml.header = { "MySecret" => "abc" }
      xml.header.should == { "MySecret" => "abc" }
    end
  end

  describe "#namespaces" do
    it "should default to a Hash containing the namespace for SOAP 1.1" do
      xml.namespaces.should == { "xmlns:env" => "http://schemas.xmlsoap.org/soap/envelope/" }
    end

    it "should default to a Hash containing the namespace for SOAP 1.2 if that's the current version" do
      xml.version = 2
      xml.namespaces.should == { "xmlns:env" => "http://www.w3.org/2003/05/soap-envelope" }
    end

    it "should set the SOAP header" do
      xml.namespaces = { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema" }
      xml.namespaces.should == { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema" }
    end
  end

  describe "#namespace" do
    it "should set the 'xmlns:wsdl' namespace" do
      xml.namespace = "http://example.com"
      xml.namespaces["xmlns:wsdl"].should == "http://example.com"
    end
  end

  describe "#wsse" do
    it "should set the Savon::WSSE object" do
      xml.wsse = Savon::WSSE.new
      xml.wsse.should be_a(Savon::WSSE)
    end
  end

  describe "#body" do
    it "should set the SOAP body Hash" do
      xml.body = { :id => 1 }
      xml.to_xml.should include("<id>1</id>")
    end

    it "should also accepts an XML String" do
      xml.body = "<id>1</id>"
      xml.to_xml.should include("<id>1</id>")
    end
  end

  describe "#xml" do
    it "lets you specify a completely custom XML String" do
      xml.xml = "<custom>xml</custom>"
      xml.to_xml.should == "<custom>xml</custom>"
    end

    it "yields a Builder::XmlMarkup object to a given block" do
      xml.xml { |xml| xml.using("Builder") }
      xml.to_xml.should == '<?xml version="1.0" encoding="UTF-8"?><using>Builder</using>'
    end
  end

  describe "#to_xml" do
    after { reset_soap_version }

    context "by default" do
      it "should start with an XML declaration" do
        xml.to_xml.should match(/^<\?xml version="1.0" encoding="UTF-8"\?>/)
      end

      it "should have a SOAP envelope tag with a SOAP 1.1 namespace" do
        xml.to_xml.should include('<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">')
      end

      it "should have a SOAP body containing the SOAP input tag and body Hash" do
        xml.to_xml.should include('<env:Body><authenticate><id>1</id></authenticate></env:Body>')
      end

      it "should accept a SOAP body as an XML String" do
        xml.body = "<someId>1</someId>"
        xml.to_xml.should include('<env:Body><authenticate><someId>1</someId></authenticate></env:Body>')
      end

      it "should not contain a SOAP header" do
        xml.to_xml.should_not include('<env:Header')
      end
    end

    context "with the global SOAP version set to 1.2" do
      it "should contain the namespace for SOAP 1.2" do
        Savon.soap_version = 2
        
        xml.to_xml.should include('<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope">')
        reset_soap_version
      end
    end

    context "with a global and request SOAP version" do
      it "should contain the namespace for the request SOAP version" do
        Savon.soap_version = 2
        xml.version = 1
        
        xml.to_xml.should include('<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">')
        reset_soap_version
      end
    end

    context "using the #namespace shortcut" do
      it "should contain the 'xmlns:wsdl' namespace" do
        xml.namespace = "http://example.com"
        xml.to_xml.should include('xmlns:wsdl="http://example.com"')
      end
    end

    context "with WSSE authentication" do
      it "should containg a SOAP header with WSSE authentication details" do
        xml.wsse = Savon::WSSE.new
        xml.wsse.credentials "username", "password"

        xml.to_xml.should include("<env:Header><wsse:Security")
        xml.to_xml.should include("<wsse:Username>username</wsse:Username>")
        xml.to_xml.should include("password</wsse:Password>")
      end
    end

    context "with a simple input tag (Symbol)" do
      it "should just add the input tag" do
        xml.input = :simple
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with a simple input tag (Array)" do
      it "should just add the input tag" do
        xml.input = :simple
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with an input tag and a namespace Hash (Array)" do
      it "should contain the input tag with namespaces" do
        xml.input = [:getUser, { "active" => true }]
        xml.to_xml.should include('<getUser active="true"><id>1</id></getUser>')
      end
    end

    context "with a prefixed input tag (Array)" do
      it "should contain a prefixed input tag" do
        xml.input = [:wsdl, :getUser]
        xml.to_xml.should include('<wsdl:getUser><id>1</id></wsdl:getUser>')
      end
    end

    context "with a prefixed input tag and a namespace Hash (Array)" do
      it "should contain a prefixed input tag with namespaces" do
        xml.input = [:wsdl, :getUser, { :only_active => false }]
        xml.to_xml.should include('<wsdl:getUser only_active="false"><id>1</id></wsdl:getUser>')
      end
    end
  end

  def reset_soap_version
    Savon.soap_version = Savon::SOAP::DefaultVersion
  end

end