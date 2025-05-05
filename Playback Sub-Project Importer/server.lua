local app_state = require("app_state")
local json = require("dkjson")
local socket = require("socket")
local action_cb = require("app_actions")

local server = {}

-- Start server on port 8080 (non-blocking)
local http_server = assert(socket.bind("*", 8080))
http_server:settimeout(0)  -- ✅ Non-blocking mode

function server.handle_requests()
    local client = http_server:accept()
    if client then
        client:settimeout(0.1)
        local request = client:receive("*l")

        if request then
            local method, path = request:match("^(%S+) (%S+)")
            local response_body = ""

            if method == "GET" and path == "/state" then
                -- ✅ Return current app state as JSON
                response_body = json.encode(app_state)

            elseif method == "POST" and path == "/action" then
                -- ✅ Handle actions (parsed from JSON request)
                local body = client:receive("*a")
                local request_data = json.decode(body)

                if request_data and request_data.action then
                    if request_data.action == "scan" then
                        action_cb.ScanDirectory()
                    elseif request_data.action == "import" then
                        action_cb.ImportProjects()
                    elseif request_data.action == "move_up" then
                        action_cb.MoveSelectedProject(request_data.project, "up")
                    elseif request_data.action == "move_down" then
                        action_cb.MoveSelectedProject(request_data.project, "down")
                    elseif request_data.action == "remove" then
                        action_cb.RemoveSelectedProject(request_data.project)
                    end
                end
                response_body = '{"status": "success"}'

            elseif method == "POST" and path == "/update_state" then
                -- ✅ Update state manually
                local body = client:receive("*a")
                local request_data = json.decode(body)
                if request_data then
                    for key, value in pairs(request_data) do
                        app_state[key] = value
                    end
                end
                response_body = '{"status": "updated"}'
            else
                response_body = '{"error": "Invalid request"}'
            end

            -- Send HTTP response
            local response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " .. #response_body .. "\r\n\r\n" .. response_body
            client:send(response)
        end
        client:close()
    end
end

return server
