local success = xpcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local TestEZ = require(ReplicatedStorage.TestEZ)

    local Results = TestEZ.TestBootstrap:run(
        {ReplicatedStorage.TGFramework.tests},
        TestEZ.Reporters.TextReporter
    )

    return Results.failureCount == 0
end, debug.traceback)

os.exit(success and 0 or 1)