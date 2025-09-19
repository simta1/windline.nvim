---@diagnostic disable: need-check-nil
local windline = require('windline')
local cava_text = "OK"
local uv = vim.uv or vim.loop

local function system_stop()
    if _G._cava_stop then _G._cava_stop() end
end

vim.api.nvim_create_autocmd("VimLeave", {
    pattern = "*",
    callback = system_stop
})
local create_cava_colors = function(colors)
    local HSL = require('wlanimation.utils')
    local d_colors = {
        "green", "blue", "yellow", "magenta", "red", "cyan"
    }
    local cava_colors = HSL.rgb_to_hsl(colors[d_colors[math.random(#d_colors)]]):tints(10, 8)
    for i = 1, 8, 1 do
        colors["cava" .. i] = cava_colors[i]:to_rgb()
    end
    return colors
end

local bars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local result = {}
local cava_comp = {
    name = "cava",
    hl_colors = {
        cava1 = { "cava1", "wavedefault" },
        cava2 = { "cava2", "wavedefault" },
        cava3 = { "cava3", "wavedefault" },
        cava4 = { "cava4", "wavedefault" },
        cava5 = { "cava5", "wavedefault" },
        cava6 = { "cava6", "wavedefault" },
        cava7 = { "cava7", "wavedefault" },
        cava8 = { "cava8", "wavedefault" },
    },
    text = function()
        local temp = {}
        for i = 1, 30, 1 do
            local index = i * 2 - 1
            local c = tonumber(cava_text:sub(index, index))
            if c then
                c = c + 1
                temp[i] = { bars[c], "cava" .. c }
            end
        end

        local win_width = vim.fn.winwidth(0)
        local cnt = math.floor(win_width - 95)
        cnt = math.max(cnt, 6)
        result = {}

        local tlen = #temp
        for i = 1, cnt do
            result[i] = temp[((i - 1) % tlen) + 1]
        end
        return result
    end,
    click = function()
        vim.notify("change cava colors")
        windline.change_colors(create_cava_colors(windline.get_colors()))
    end
}

local function run_cava()
    local sourced_file = require('plenary.debug_utils').sourced_filepath()
    local plugin_directory = vim.fn.fnamemodify(sourced_file, ':h:h:h:h')

    local cava_path = vim.fn.expand(plugin_directory .. "/scripts/cava.sh")
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local handle = uv.spawn(cava_path,
        { stdio = { stdin, stdout, stderr }, },
        function() _G._cava_stop() end
    )

    uv.read_start(stdout, vim.schedule_wrap(function(_, data)
        if data then
            cava_text = data
            vim.cmd.redrawstatus()
        end
    end))
    _G._cava_stop = function()
        stdin:read_stop()
        stdin:close()
        stdout:read_stop()
        stdout:close()
        stderr:read_stop()
        stderr:close()
        handle:close()
        _G._cava_stop = nil
    end
end


local M = {}

M.toggle = function()
    if not _G._cava_stop then
        run_cava()
        windline.add_component(cava_comp, {
            name = "cava",
            position = "right",
            auto_remove = true,
            colors_name = create_cava_colors
        })
    else
        system_stop()
        windline.remove_component(cava_comp)
        vim.cmd.redrawstatus()
    end
end
-- M.toggle()
return M
