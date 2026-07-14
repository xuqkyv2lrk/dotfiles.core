local M = {}

local function fail(job, s)
	ya.preview_widget(job, ui.Text.parse(s):area(job.area):wrap(ui.Wrap.YES))
end

function M:peek(job)
	local child, err = Command("glow")
		:arg({ "--style", "dark", "--width", tostring(job.area.w), tostring(job.file.path) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return fail(job, "glow: " .. err)
	end

	local limit = job.area.h
	local i, lines = 0, {}
	repeat
		local line, event = child:read_line()
		if event ~= 0 then break end
		i = i + 1
		if i > job.skip then
			lines[#lines + 1] = line
		end
	until i >= job.skip + limit

	child:start_kill()

	if job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		local s = table.concat(lines, "")
		ya.preview_widget(job, ui.Text.parse(s):area(job.area))
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + job.units),
			only_if = job.file.url,
		})
	end
end

return M
