list = nil
list = {next = list, value = 10}
list = {next = list, value = 11}
list = {next = list, value = 12}
list = {next = list, value = 13}

local l = list
while l do
	print(l.value)
	l = l.next
end
