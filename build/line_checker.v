module build

enum Typ {
	function_call
	definition
	math
}

pub fn parse_line(line string) Typ {
	if line.contains('(') && line.contains(')') {
		//function call
		return .function_call
	}
}

pub fn (mut parser Parser) parse_function(line string) ?(Function, []string) {
	data := line.split('(')
	name := data[0]
	mut parameter := []string{}

	mut last := []byte{}
	mut str := false

	for b in data[1] {
		if b == '\''.bytes()[0] {
			if str {
				str = false
			} else {
				str = true
			}
		}
		if b == ','.bytes()[0] {
			if !str {
				if last.len > 0 {
					parameter << string(last)
					last = []byte{}
				}
			}
		} else if b == ')'.bytes()[0] {
			if !str {
				if last.len > 0 {
					parameter << string(last)
					last = []byte{}
				}
			}
		} else {
			last << b
		}
	}

	if parser.check_func_exists(name) {
		func := parser.get_func(name)
		if func.parameter.len == parameter.len {
			for i := 0; i < func.parameter.len; i++ {
				match func.parameter[i].typ.name {
					'string' {
						if !(parameter[i].trim_space().starts_with('\'') && parameter[i].trim_space().ends_with('\'')) {
							return error('String isnt given')
						}
						parameter[i] = parameter[i].trim_space().replace('\'', '"')
					}
					else {}
				}
			}
			return func, parameter
		} else {
			//error
			return error('Not enought parameter ($parameter.len given but needs $func.parameter.len)')
		}
	} else if name.starts_with('C.') || name.starts_with('c.') {
		for i, _ in parameter {
			parameter[i] = parameter[i].trim_space().replace('\'', '"')
		}
		return Function{name}, parameter
	} else {
		//error
		return error('Function doesnt exists')
	}
}