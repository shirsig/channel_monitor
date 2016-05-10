local channel_monitor = CreateFrame('Frame')
channel_monitor:SetScript('OnEvent', function()
	this[event](this)
end)
channel_monitor:RegisterEvent('ADDON_LOADED')

channel_monitor_x, channel_monitor_y = 0, 0
channel_monitor_on = true
channel_monitor_filter = ''

function channel_monitor:match(message)
	for clause in string.gfind(channel_monitor_filter, '[^,]+') do
		local match
		for keyword in string.gfind(clause, '[^/]+') do
			keyword = gsub(keyword, '^%s*', '')
			keyword = gsub(keyword, '%s*$', '')
			local position = 1
			while true do
				local start_position, end_position = strfind(strupper(message), strupper(keyword), position, true)
				if start_position then
					if (start_position == 1 or not strfind(strsub(message, start_position - 1, start_position - 1), '%w')) and (end_position == strlen(message) or not strfind(strsub(message, end_position + 1, end_position + 1), '%w')) then
						match = true
					end
					position = end_position
				else
					break
				end
			end
		end
		if not match then
			return false
		end
	end
	return true
end

function channel_monitor:CHAT_MSG_CHANNEL()
	if channel_monitor_on and self:match(arg1) then
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

		local body = format(TEXT(getglobal('CHAT_CHANNEL_GET'))..language..arg1, flag..'|Hplayer:'..arg2..'|h['..arg2..']|h')

		-- Add Channel
		arg4 = gsub(arg4, '%s%-%s.*', '')
		body = '['..arg4..'] '..body

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
	main_frame:SetWidth(300)
	main_frame:SetHeight(93)
	main_frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8', edgeFile='Interface\\Buttons\\WHITE8X8', edgeSize=2})
    main_frame:SetBackdropColor(1,1,1,.2)
    main_frame:SetBackdropBorderColor(1,1,1,.2)
	main_frame:SetMovable(true)
	main_frame:SetClampedToScreen(true)
	main_frame:EnableMouse(true)
	main_frame:RegisterForDrag('LeftButton')
	main_frame:SetScript('OnDragStart', function()
		this:StartMoving()
	end)
	main_frame:SetScript('OnDragStop', function()
		this:StopMovingOrSizing()
		local x, y = this:GetCenter()
		local ux, uy = UIParent:GetCenter()
		channel_monitor_x, channel_monitor_y = floor(x - ux + 0.5), floor(y - uy + 0.5)
	end)

    local editbox = CreateFrame('EditBox', nil, main_frame)
	editbox:SetPoint('TOP', 0, -5)
	editbox:SetPoint('LEFT', 5, 0)
	editbox:SetPoint('RIGHT', -5, 0)
    editbox:SetAutoFocus(false)
    editbox:SetTextInsets(0, 0, 3, 3)
    editbox:SetMaxLetters(256)
    editbox:SetHeight(19)
    editbox:SetFont([[Fonts\ARIALN.TTF]], 15)
    editbox:SetShadowColor(0, 0, 0, 0)
    editbox:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8X8', edgeSize=2})
    editbox:SetBackdropBorderColor(1,1,1,.2)
    editbox:SetText(channel_monitor_filter)
    editbox:SetScript('OnTextChanged', function() channel_monitor_filter = this:GetText() end)
    editbox:SetScript('OnEditFocusLost', function()
        this:HighlightText(0, 0)
    end)
    editbox:SetScript('OnEscapePressed', function()
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
	message_frame:SetFontObject(GameFontNormal)
	message_frame:SetJustifyH('LEFT')
	message_frame:SetPoint('TOP', editbox, 'BOTTOM')
	message_frame:SetPoint('BOTTOM', 0, 6)
	message_frame:SetPoint('LEFT', 5, 0)
	message_frame:SetPoint('RIGHT', -5, 0)
	message_frame:SetScript('OnHyperlinkClick', function() ChatFrame_OnHyperlinkShow(arg1, arg2, arg3) end)
	message_frame:SetScript('OnHyperlinkLeave', ChatFrame_OnHyperlinkHide)
	message_frame:EnableMouseWheel(true)
	message_frame:SetScript('OnMouseWheel', function() if arg1 == 1 then this:ScrollUp() elseif arg1 == -1 then this:ScrollDown() end end)
	message_frame:SetFading(false)

    if not channel_monitor_on then
    	main_frame:Hide()
	end

	self.message_frame = message_frame
    self.main_frame = main_frame
end

SLASH_channel_monitor1, SLASH_channel_monitor2 = '/channel_monitor', '/cm'
function SlashCmdList.channel_monitor()
	channel_monitor_on = not channel_monitor_on
	if channel_monitor_on then
		channel_monitor.main_frame:Show()
	else
		channel_monitor.main_frame:Hide()
	end
end