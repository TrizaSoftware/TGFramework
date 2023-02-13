return function ()
    local Client = require(script.Parent.Parent.Client)

    describe("Controller", function()
        describe("CreateController", function()
            it("should be a table", function()
                local Controller = Client:CreateController({
                    Name = "TestController"
                })
    
                expect(typeof(Controller) == "table").to.be.ok()
            end)
    
            it("should throw an error with no name", function()
                local success = pcall(function()
                    Client:CreateController({})
                end)
                expect(not success).to.be.ok()
            end)
        end)
    end)

    describe("Service", function()
        describe("GetService", function()
            it("should throw an error with an invalid service", function()
                local success = pcall(function()
                    Client:GetService("ThisServiceDoesntExist")
                end)

                expect(not success).to.be.ok()
            end)
        end)
    end)
end