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
                expect(Client:CreateController({})).to.throw("A name must be specified for a Controller.")
            end)
        end)
    end)
end