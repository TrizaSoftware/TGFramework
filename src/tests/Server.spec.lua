return function ()
    local Server = require(script.Parent.Parent.Server)

    describe("Service", function()
        describe("CreateService", function()
            it("should be a table", function()
                local Service = Server:CreateService({
                    Name = "TestService"
                })
    
                expect(typeof(Service) == "table").to.be.ok()
            end)
    
            it("should throw an error with no name", function()
                expect(Server:CreateService({})).to.throw("A name must be specified for a Service.")
            end)
        end)
    end)
end