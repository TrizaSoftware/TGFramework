return function ()
    local Client = require(script.Parent.Parent.Client)

    describe("Controller", function()
        it("should be a table", function()
            local Controller = Client:CreateController({
                Name = "TestController"
            })

            expect(typeof(Controller) == "table").to.be.ok()
        end)
    end)
end