local csvutil = {}

--takes 2 tables, one for the columns (key / name pair), and the other for the data, and converts it into a CSV string
csvutil.MakeCSV = function( columns, data )
	local str_tbl = {}
	
	local temp_tbl = {}
	for _, v in ipairs(columns) do
		table.insert(temp_tbl, v.name)
	end

	table.insert( str_tbl, table.concat(temp_tbl, ", ") )

	for _, item in ipairs(data) do
		temp_tbl = {}
		for _, v in ipairs(columns) do
			local val = item[v.key]
			val = type(val) == "string" and val or ""
			if val:find(",") then
				val = string.format("\"%s\"", val)
			end
			table.insert(temp_tbl, val)
		end

		table.insert( str_tbl, table.concat(temp_tbl, ", ") )
	end

	return table.concat( str_tbl, "\n" )
end

csvutil.TestMakeCSV = function()
	local columns =
	{
		{ key = "firstname", name = "First Name" },
		{ key = "lastname", name = "Last Name" },
	}

	local data = 
	{
		{
			firstname = "Jamie",
			lastname = "Cheng",
		},
		{
			firstname = "John",
			lastname = "Doe",
		},
	}
	return csvutil.MakeCSV(columns, data)
end

return csvutil
