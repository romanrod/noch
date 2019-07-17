class MockSlack

    def chat_postMessage(opts)
      true
    end

    def method_missing meth

    end


end