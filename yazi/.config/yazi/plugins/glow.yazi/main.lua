local M = {}

function M:peek(job)
	local child, err = Command("glow")
		:args({ "--style", "dark", "--width", tostring(job.area.w), tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if err then
		return
	end

	local output, err = child:wait_with_output()
	if err or not output.status.success then
		return
	end

	local lines = {}
	local i = 0
	for line in output.stdout:gmatch("[^\n]*") do
		i = i + 1
		if i > job.skip then
			lines[#lines + 1] = ui.Line(line)
		end
	end

	ya.preview_widgets(job, { ui.Text(lines):area(job.area) })
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.manager_emit("peek", {
			math.max(0, cx.active.preview.skip + job.units),
			only_if = tostring(job.file.url),
		})
	end
end

return M
