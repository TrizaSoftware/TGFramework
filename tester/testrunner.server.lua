local success, result = xpcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local TestEZ = require(ReplicatedStorage.TestEZ)

    local Results = TestEZ.TestBootstrap:run(
        {ReplicatedStorage.TGFramework.tests},
        TestEZ.Reporters.TextReporter
    )

    return Results.failureCount == 0
end, debug.traceback)

if not success then
    os.exit(1)
end

os.exit(result and 0 or 1)