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
    print(result)
    os.exit(1)
else
    os.exit(result)
    os.exit(0)
end