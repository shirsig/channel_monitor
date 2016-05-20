local channel_monitor = CreateFrame('Frame')
channel_monitor:SetScript('OnEvent', function()
	this[event](this)
end)
channel_monitor:RegisterEvent('ADDON_LOADED')

channel_monitor_x, channel_monitor_y = 0, 0
channel_monitor_on = true
channel_monitor_filter = ''

function channel_monitor:match(message)
	for keyword in string.gfind(channel_monitor_filter, '[^,]+') do
		keyword = gsub(keyword, '^%s*', '')
		keyword = gsub(keyword, '%s*$', '')
		local position = 1
		while true do
			local start_position, end_position = strfind(strupper(message), strupper(keyword), position, true)
			if start_position then
				if (start_position == 1 or not strfind(strsub(message, start_position - 1, start_position - 1), '%w')) and (end_position == strlen(message) or not strfind(strsub(message, end_position + 1, end_position + 1), '%w')) then
					return true
				end
				position = end_position + 1
			else
				break
			end
		end
	end
	return false
end

function channel_monitor:CHAT_MSG_CHANNEL()
	if channel_monitor_on and self:match(arg1) and arg2 ~= UnitName('player') then
		arg1 = gsub(arg1, "%%", "%%%%")

		local flag
		if arg6 ~= '' then
			flag = TEXT(getglobal('CHAT_FLAG_'..arg6))
		else
			flag = ''
		end

		local language
		if arg3 ~= '' and arg3 ~= 'Universal' and arg3 ~= GetDefaultLanguage('player') then
			language = '['..arg3..'] '
		else
			language = ''
		end

		local timestamp = '|cffffa900'..date('%H:%M')..'|r '

		local body = timestamp..format(TEXT(getglobal('CHAT_CHANNEL_GET'))..language..arg1, flag..'|Hplayer:'..arg2..'|h['..arg2..']|h')

		local info = ChatTypeInfo['CHANNEL']
		self.message_frame:AddMessage(body, info.r, info.g, info.b, info.id)
	end
end

function channel_monitor:ADDON_LOADED()
	if arg1 ~= 'channel_monitor' then
		return
	end

	self:RegisterEvent('CHAT_MSG_CHANNEL')

	local main_frame = CreateFrame('Frame', nil, UIParent)
	main_frame:SetPoint('CENTER', channel_monitor_x, channel_monitor_y)
	main_frame:SetWidth(350)
	main_frame:SetHeight(120)
	main_frame:SetBackdrop({
		bgFile=[[Interface\ChatFrame\ChatFrameBackground]],
		tile = true,
		tileSize = 16,
	})
    main_frame:SetBackdropColor(0, 0, 0, .45)
	main_frame:SetMovable(true)
	main_frame:SetClampedToScreen(true)
	main_frame:SetToplevel(true)
	main_frame:EnableMouse(true)
	main_frame:RegisterForDrag('LeftButton')
	main_frame:SetScript('OnDragStart', function()
		this:StartMoving()
	end)
	main_frame:SetScript('OnDragStop', function()
		this:StopMovingOrSizing()
		local x, y = this:GetCenter()
		local ux, uy = UIParent:GetCenter()
		channel_monitor_x, channel_monitor_y = floor(x - ux + 0.5), floor(y - uy + .7)
	end)
	main_frame:SetScript('OnUpdate', function()
		if MouseIsOver(this) then
			this.time_entered = this.time_entered or GetTime()
			if GetTime() - this.time_entered > .5 then
				this.editbox:SetAlpha(1)
	    		this:SetBackdropColor(0, 0, 0, .45)
	    		main_frame:EnableMouse(true)
    		end
		else
			this.time_entered = nil
			this.editbox:ClearFocus()
			this.editbox:SetAlpha(0)
    		this:SetBackdropColor(0, 0, 0, 0)
    		this:EnableMouse(false)
		end
	end)

    local editbox = CreateFrame('EditBox', nil, main_frame)
    main_frame.editbox = editbox
	editbox:SetPoint('TOP', 0, -2)
	editbox:SetPoint('LEFT', 2, 0)
	editbox:SetPoint('RIGHT', -2, 0)
    editbox:SetAutoFocus(false)
    editbox:SetTextInsets(0, 0, 3, 3)
    editbox:SetMaxLetters(256)
    editbox:SetHeight(19)
    editbox:SetFontObject(GameFontNormal)
    editbox:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'})
    editbox:SetBackdropColor(1, 1, 1, .2)
    editbox:SetText(channel_monitor_filter)
    editbox:SetScript('OnTextChanged', function() channel_monitor_filter = this:GetText() end)
    editbox:SetScript('OnEditFocusLost', function()
        this:HighlightText(0, 0)
    end)
    editbox:SetScript('OnEscapePressed', function()
        this:ClearFocus()
    end)
    editbox:SetScript('OnEnterPressed', function()
        this:ClearFocus()
    end)
    do
        local last_time, last_x, last_y

        editbox:SetScript('OnEditFocusGained', function()
            this:HighlightText()
        end)

        editbox:SetScript('OnMouseUp', function()
            local x, y = GetCursorPosition()
            if last_time and last_time > GetTime() - .5 and abs(x - last_x) < 10 and abs(y - last_y) < 10 then
                this:HighlightText()
                last_time = nil
            else
                last_time = GetTime()
                last_x, last_y = GetCursorPosition()
            end
        end)
    end

	local message_frame = CreateFrame('ScrollingMessageFrame', nil, main_frame)
	main_frame.message_frame = message_frame
	message_frame:SetFontObject(GameFontNormalLarge)
	message_frame:SetJustifyH('LEFT')
	message_frame:SetPoint('TOP', editbox, 'BOTTOM')
	message_frame:SetPoint('BOTTOM', 0, 2)
	message_frame:SetPoint('LEFT', 0, 0)
	message_frame:SetPoint('RIGHT', 0, 0)
	message_frame:SetScript('OnHyperlinkClick', function() ChatFrame_OnHyperlinkShow(arg1, arg2, arg3) end)
	message_frame:SetScript('OnHyperlinkLeave', ChatFrame_OnHyperlinkHide)
	message_frame:EnableMouseWheel(true)
	message_frame:SetScript('OnMouseWheel', function() if arg1 == 1 then this:ScrollUp() elseif arg1 == -1 then this:ScrollDown() end end)
	message_frame:SetTimeVisible(60)

    if not channel_monitor_on then
    	main_frame:Hide()
	end

	self.message_frame = message_frame
    self.main_frame = main_frame
end

SLASH_CHANNEL_MONITOR1, SLASH_CHANNEL_MONITOR2 = '/channel_monitor', '/cm'
function SlashCmdList.CHANNEL_MONITOR()
	channel_monitor_on = not channel_monitor_on
	if channel_monitor_on then
		channel_monitor.main_frame:Show()
	else
		channel_monitor.main_frame:Hide()
	end
end