local M = {}

-- fiber.create()	Create and start a fiber
M.create = box.fiber.wrap

-- fiber.self()	Get a fiber object
M.self = box.fiber.self

-- fiber.find()	Get a fiber object by ID
M.find = box.fiber.find

-- fiber.sleep()	Make a fiber go to sleep
M.sleep = box.fiber.sleep

-- fiber.name()
M.name = box.fiber.name

-- fiber.yield()	Yield control
M.yield = function() box.fiber.sleep(0) end

-- fiber.status()	Get the current fiber’s status
M.status = box.fiber.status

-- fiber.info()	Get information about all fibers
M.info = function() error("Use `show fiber` from admin console",0) end

-- fiber.kill()	Cancel a fiber
M.kill = box.fiber.kill

-- fiber.testcancel()	Check if the current fiber has been cancelled
M.testcancel = box.fiber.testcancel

-- fiber.time()	Get the system time in seconds
M.time = box.time

-- fiber.time64()	Get the system time in microseconds
M.time64 = box.time64

-- fiber.channel()	Create a communication channel
M.channel = box.ipc.channel

-- fiber.cond()	Create a condition variable
M.cond = function() error("cond not implemented. use channel",0) end

return M
