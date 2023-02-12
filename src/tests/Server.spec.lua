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
                local success = pcall(function()
                    Server:CreateService({})
                end)
                expect(not success).to.be.ok()
            end)
        end)
    end)
end