--Currency Tracker by erupt@asura.
--After you load the lua for the first time just edit the settings.xml from /data and reload the lua 
--to have your new fields displayed.  Curlines dictates how many fields you would like per line on your box.
--
-- ** Commands **
--  //curt on|off
--  //curt add <search term>
--  //curt del <search term>
--
-- ex.   //curt add Snowdim 
--		  Returns that this matched multiple results
--		 //curt add Snowdim 2
-- ex.   //curt add Snowdim *
--		  Adds multiple entries matching Snowdim
--
-- ** Version History **
--	v1.0 - Rewrote the saving and loading of currency types to just use whatever is found
--         in the packets library so no updates are needed.
--  v0.4 - Add commands to disable refresh, search and change fields from addon command
--	v0.3 - Add all fields to a table which can just be enabled/disabled through settings.xml
--	v0.2 - Fix Windower fields.lua to correct Unity Accolades memory location
--  v0.1 - Initial Test Release



_addon.author = 'Erupt'
_addon.commands = {'curtracker','curt'}
_addon.name = 'CurTracker'
_addon.version = '1.0'

require('logger')
require('tables')
require('sets')
texts = require('texts')
config = require('config')
res = require('resources')
packets = require('packets')



curfields = {}
for i,v in ipairs(T(packets.raw_fields.incoming[0x118])) do
	v = v['label']
	curfields[v:lower()] = v
end
for i,v in ipairs(T(packets.raw_fields.incoming[0x113])) do
	v = v['label']
	curfields[v:lower()] = v
end


	


default = {
  text = {
    pos = {}
  },
  curtracking = true,
  curlines = 2,
  curfields = S{},
}
default.text.pos.x = 100
default.text.pos.y = 300

settings = {}

cur1packet = {}
cur2packet = {}
cursearches = {}
curpackettype = 0

cur_box = function()
  local str = ''
  if not cur2packet['Coalition Imprimaturs'] then return end
  curlinecnt = 0
  for v in settings.curfields:it() do
	print('V: ',v)
    if v ~= '' then
      if curlinecnt >= settings.curlines then
        str = str..'\n'
        curlinecnt = 0
      end
	  v = curfields[v:lower()]
      if not cur1packet[v] then
        str = str..v..': '..cur2packet[v]..' '
        curlinecnt = curlinecnt+1
      else
        str = str..v..': '..cur1packet[v]..' '
        curlinecnt = curlinecnt+1
      end
    end
  end
  curpackettype = 0
  return str
end

search_data = {}

function search_curs(curs)
  local search = string.gsub(curs," ",".*")
  search_data = {}
  local search_cnt = 0
  search = string.lower(".*"..search..".*")
  for l,u in pairs(curfields) do
    if string.match(l,search) then
      table.insert(search_data,u)
      search_cnt = search_cnt+1
    end
  end
  return search_cnt
end

cur_trackbox = texts.new(settings.text,settings)

function addon_message(str)
  windower.add_to_chat(207, _addon.name..': '..str)
end

function cur_command(...)
  local commands = {...}
  if commands[1] then
    commands[1] = commands[1]:lower()
    if #commands>2 then
      cnt = 3
      while cnt <= #commands do
        if commands[cnt] ~= "*" then commands[2] = commands[2]..' '..commands[cnt] end
        cnt = cnt+1
      end
    end
  end
  if commands[1] == "on" then
    addon_message('Set to on')
    settings.curtracking = true
    send_request()
    return
  elseif commands[1] == "off" then
    addon_message('Set to off')
    settings.curtracking = false
    cur_trackbox:hide()
    return
  elseif commands[1] == "add" then
    if not commands[2] then
      addon_message(' Usage: //curt add Currency Name')
      return
    end
    local search_result = search_curs(commands[2])
    if search_result>0 then
      if search_result == 1 then
		if settings.curfields:contains(search_data[1]) then
			log(search_data[1]..' Already added to tracker')
			return
		end	
        addon_message('Adding: '..search_data[1])	
        settings.curfields:add(search_data[1]:lower())
        config.save(settings)
        return
      elseif search_result > 1 then
        if search_result > 5 then
          addon_message(' Too many results matched your pattern, narrow it down')
          return
        end
        local results = ''
        for k,v in pairs(search_data) do
          if k > 1 then results = results..', ' end
          results = results..v
        end
        if commands[#commands] == '*' then
          for k,v in pairs(search_data) do
            settings.curfields:add(v:lower())
          end
          addon_message(' Added: '..results)
          config.save(settings)
          return
        else 
          addon_message('Multiple Results: '..results)
          addon_message('** To add all these results append search with "*"')
          return
        end
      end
    else
      addon_message('Did not match any known currencies')
      return
    end
  elseif commands[1] == 'del' then
      if not commands[2] then
      addon_message(' Usage: //curt del Currency Name')
      return
    end
    local search_result = search_curs(commands[2])
    if search_result>0 then
      if search_result == 1 then
        addon_message('Deleting: '..search_data[1])		
        settings.curfields:remove(search_data[1]:lower())
        config.save(settings)
        return
      elseif search_result > 1 then
        if search_result > 5 then
          addon_message(' Too many results matched your pattern, narrow it down')
          return
        end
        local results = ''
        for k,v in pairs(search_data) do
          if k > 1 then results = results..', ' end
          results = results..v
        end
        if commands[#commands] == '*' then
          for k,v in pairs(search_data) do
            settings.curfields:remove(v:lower())
          end
          addon_message(' Deleted: '..results)
          config.save(settings)
          return
        else 
          addon_message('Multiple Results: '..results)
          addon_message('** To delete all these results append search with "*"')
          return
        end
      end
    else
      addon_message('Did not match any known currencies')
      return
	end
  end
end

function check_incoming_chunk(id,original,modified,injected,blocked)
  if settings.curtracker == false then return end
  if id == 0x118 then
    cur2packet = packets.parse('incoming', original)
  end
  if id == 0x113 then
    cur1packet = packets.parse('incoming',original)
--		print(original)
    return
  end
  if curpackettype == 2 then
    cur_trackbox:text(cur_box())
    cur_trackbox:show()
    coroutine.schedule(send_request,60)
  end
end


function check_outgoing_chunk(id,data)
  if id == 0x115 then
    local packet = packets.parse('outgoing',data)
--print(packet)
  end
end

function send_request()
  if curpackettype == 0 then
    local packet = packets.new('outgoing',0x10F)
    curpackettype = 1
    packets.inject(packet)
    coroutine.schedule(send_request,5)
    return
  end
  if curpackettype == 1 then
    local packet = packets.new('outgoing',0x115)
    curpackettype = 2
    packets.inject(packet)
    return
  end
end

incoming_chunk = windower.register_event('incoming chunk', check_incoming_chunk)
outgoing_chunk = windower.register_event('outgoing chunk', check_outgoing_chunk)




windower.register_event('login', function()
	if windower.ffxi.get_info().logged_in then
		settings = config.load(default)
		send_request()
	end
end)

windower.register_event('load', function()
	if windower.ffxi.get_info().logged_in then
		settings = config.load(default)
		send_request()
	end
end)


windower.register_event('addon command', cur_command)